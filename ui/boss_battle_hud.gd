class_name BossBattleHud
extends Control
## Screen-space combat instruments. Actual health snaps to damage; the pale
## damage trail holds briefly before draining, without obscuring the new value.
const PALETTES: Array[Color] = [Color("bc8655"), Color("d77a40"), Color("65aebc"), Color("c8b58a"), Color("cd83a0")]
const FILLS: Array[Color] = [Color("b83b32"), Color("c84a2d"), Color("357f9b"), Color("9e344e"), Color("b74473")]
const BOSS_FRAMES: Array[Texture2D] = [preload("res://assets/ui/frames/recaudador.png"), preload("res://assets/ui/frames/caldera.png"), preload("res://assets/ui/frames/coro.png"), preload("res://assets/ui/frames/prefecto.png"), preload("res://assets/ui/frames/madre.png")]
const PLAYER_FRAME: Texture2D = preload("res://assets/ui/frames/portador.png")
const PLAYER_TRACK: Rect2 = Rect2(34, 29, 168, 7)
const STAMINA_TRACK: Rect2 = Rect2(34, 46, 168, 3)
const BOSS_TRACK: Rect2 = Rect2(111, 334, 418, 9)
var zone_index: int = 0
var boss_title: String = ""
var health: int = 100
var health_max: int = 100
var stamina: float = 100
var stamina_max: float = 100
var boss_health: int = 100
var boss_health_max: int = 100
var phase: int = 1
var exposed: bool = false
var player_ratio: float = 1
var boss_ratio: float = 1
var player_trail: float = 1
var boss_trail: float = 1
var player_hold: float = 0
var boss_hold: float = 0
var font: Font = ThemeDB.fallback_font
var player_panel: StyleBoxFlat

func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_panel = panel_style()
	set_process(false) # The arena supplies its paused/story-aware clock.

func configure(index: int, title: String, player: TopdownPlayer, boss: Recaudador) -> void:
	zone_index = clampi(index, 0, 4)
	boss_title = title
	update_values(player, boss)
	player_trail = player_ratio
	boss_trail = boss_ratio
	player_hold = 0
	boss_hold = 0

func update_values(player: TopdownPlayer, boss: Recaudador) -> void:
	health = player.health
	health_max = Player.MAX_HEALTH
	stamina = player.stamina
	stamina_max = Player.MAX_STAMINA
	boss_health = boss.health
	boss_health_max = maxi(1, boss.max_health)
	phase = boss.phase
	exposed = boss.core_exposed
	var next_player: float = clampf(float(health) / health_max, 0, 1)
	var next_boss: float = clampf(float(boss_health) / boss_health_max, 0, 1)
	if next_player < player_ratio: player_hold = 0.55
	if next_boss < boss_ratio: boss_hold = 0.65
	player_ratio = next_player
	boss_ratio = next_boss
	player_trail = maxf(player_trail, player_ratio)
	boss_trail = maxf(boss_trail, boss_ratio)
	queue_redraw()

func advance(delta: float) -> void:
	player_hold = maxf(0, player_hold - delta)
	boss_hold = maxf(0, boss_hold - delta)
	if player_hold == 0: player_trail = move_toward(player_trail, player_ratio, delta * 0.65)
	if boss_hold == 0: boss_trail = move_toward(boss_trail, boss_ratio, delta * 0.45)
	queue_redraw()

func text_at(text: String, point: Vector2, font_size: int, color: Color, width: float = -1) -> void:
	draw_string(font, point + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, Color("040810"))
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func frame_track(rect: Rect2, ratio: float, trail: float, fill: Color, metal: Color) -> void:
	draw_rect(rect.grow(1), Color("19151e"))
	draw_rect(rect, Color("100e18"))
	if trail > ratio:
		draw_rect(Rect2(rect.position, Vector2(floorf(rect.size.x * trail), rect.size.y)), Color("e4bf7b").darkened(0.15))
	if ratio > 0:
		var filled: Rect2 = Rect2(rect.position, Vector2(maxf(1, floorf(rect.size.x * ratio)), rect.size.y))
		draw_rect(filled, fill)
		draw_line(filled.position, Vector2(filled.end.x, filled.position.y), fill.lightened(0.32), 1)
		draw_line(Vector2(filled.position.x, filled.end.y - 1), filled.end - Vector2(0, 1), fill.darkened(0.35), 1)
		if filled.size.x > 3: draw_line(Vector2(filled.end.x - 1, filled.position.y + 1), filled.end - Vector2(1, 1), Color("f3c3a2", 0.55), 1)

func _draw() -> void:
	# Compact instruments sit in the corners; the arena centre stays readable.
	draw_style_box(player_panel, Rect2(10, 8, 213, 53))
	text_at("PORTADOR", Vector2(34, 20), 10, Color("ddd7c7"))
	var hp_text: String = "%d / %d" % [health, health_max]
	text_at(hp_text, Vector2(204 - font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, 20), 10, Color("ecd6c7"))
	frame_track(PLAYER_TRACK, player_ratio, player_trail, Color("b63840"), Color("a49274"))
	frame_track(STAMINA_TRACK, clampf(stamina / stamina_max, 0, 1), 0, Color("61b7a3"), Color("557c78"))
	draw_texture_rect(PLAYER_FRAME, Rect2(18, 22, 200, 21), false)
	draw_rect(STAMINA_TRACK.grow(1), Color("76928c", 0.65), false, 1)
	for index: int in range(1, 4):
		var x: float = PLAYER_TRACK.position.x + PLAYER_TRACK.size.x * index / 4
		draw_line(Vector2(x, PLAYER_TRACK.position.y + 1), Vector2(x, PLAYER_TRACK.end.y - 1), Color("210e17", 0.35), 1)
	var metal: Color = PALETTES[zone_index]
	var backdrop: PackedVector2Array = PackedVector2Array([Vector2(69, 307), Vector2(571, 307), Vector2(584, 339), Vector2(566, 355), Vector2(74, 355), Vector2(56, 339)])
	draw_colored_polygon(backdrop, Color("060c16", 0.70))
	var title_size: int = 13
	while title_size > 10 and font.get_string_size(boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > 340: title_size -= 1
	var title_width: float = font.get_string_size(boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	text_at(boss_title, Vector2(320 - title_width / 2, 321), title_size, metal.lightened(0.55), 340)
	text_at("II" if phase == 2 else "I", Vector2(544, 305), 11, metal)
	frame_track(BOSS_TRACK, boss_ratio, boss_trail, FILLS[zone_index].lightened(0.08 if phase == 2 else 0.0), Color("7fdac7") if exposed else metal)
	draw_texture_rect(BOSS_FRAMES[zone_index], Rect2(71, 312, 498, 44), false, Color(0.8, 1.0, 0.92) if exposed else Color.WHITE)
	if exposed: draw_line(Vector2(112, 346), Vector2(528, 346), Color("79d7c6", 0.8), 1)

func panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("09111d", 0.48)
	style.border_color = Color("4d5558", 0.7)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_right = 6
	return style
