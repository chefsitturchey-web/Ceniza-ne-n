class_name BossBattleHud
extends Control
## Screen-space combat instruments. Actual health snaps to damage; the pale
## damage trail holds briefly before draining, without obscuring the new value.
const PALETTES: Array[Color] = [Color("bc8655"), Color("d77a40"), Color("65aebc"), Color("c8b58a"), Color("cd83a0")]
const FILLS: Array[Color] = [Color("b83b32"), Color("c84a2d"), Color("357f9b"), Color("9e344e"), Color("b74473")]
const PLAYER_TRACK: Rect2 = Rect2(53, 28, 151, 9)
const STAMINA_TRACK: Rect2 = Rect2(53, 47, 151, 4)
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

func diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)]), color)

func frame_track(rect: Rect2, ratio: float, trail: float, fill: Color, metal: Color) -> void:
	draw_rect(rect.grow(4), Color("030810", 0.95))
	draw_rect(rect.grow(3), metal.darkened(0.50), false, 1)
	draw_line(rect.position + Vector2(-2, -2), Vector2(rect.end.x + 2, rect.position.y - 2), metal.lightened(0.20), 1)
	draw_line(Vector2(rect.position.x - 2, rect.end.y + 2), rect.end + Vector2(2, 2), metal.darkened(0.12), 1)
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

func player_crest(center: Vector2) -> void:
	var low: bool = health > 0 and player_ratio <= 0.30
	var brass: Color = Color("b96c5b") if low else Color("a69c79")
	var rim: PackedVector2Array = []
	for index: int in 8: rim.append(center + Vector2.from_angle(PI / 8 + index * TAU / 8) * 19)
	draw_colored_polygon(rim, Color("060d16"))
	rim.append(rim[0])
	draw_polyline(rim, brass.darkened(0.35), 2)
	draw_arc(center, 14, 0, TAU, 32, brass, 1)
	draw_arc(center, 11, 0, TAU, 32, Color("304953"), 1)
	# The Portador's cyan neural key, set into a dark enamel medallion.
	diamond(center - Vector2(0, 4), 5, Color("81dfd2"))
	diamond(center - Vector2(0, 4), 2, Color("152c37"))
	draw_line(center, center + Vector2(0, 9), Color("81dfd2"), 2)
	draw_line(center + Vector2(0, 6), center + Vector2(5, 6), Color("81dfd2"), 2)
	for side: int in [-1, 1]: draw_rect(Rect2(center + Vector2(side * 16 - 1, -1), Vector2(2, 2)), brass)

func boss_crest(center: Vector2, metal: Color) -> void:
	diamond(center, 17, Color("070d17"))
	var border: PackedVector2Array = PackedVector2Array([center + Vector2(0, -16), center + Vector2(16, 0), center + Vector2(0, 16), center + Vector2(-16, 0), center + Vector2(0, -16)])
	draw_polyline(border, metal.darkened(0.25), 2)
	match zone_index:
		0: # Hydraulic gear and central reactor.
			for index: int in 6:
				var direction: Vector2 = Vector2.from_angle(index * TAU / 6)
				draw_line(center + direction * 8, center + direction * 12, metal, 3)
			draw_arc(center, 8, 0, TAU, 24, metal, 2)
			diamond(center, 3, Color("67c6d0"))
		1: # Furnace grille and flame.
			draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 17)), metal.darkened(0.55), false, 1)
			var flame: PackedVector2Array = PackedVector2Array([center + Vector2(-6, 7), center + Vector2(-5, -2), center + Vector2(-1, 1), center + Vector2(2, -10), center + Vector2(7, 3), center + Vector2(5, 7)])
			draw_colored_polygon(flame, metal)
			draw_line(center + Vector2(0, 5), center + Vector2(2, -2), Color("ffe3a6"), 2)
		2: # Sonar resonator.
			for radius: int in [5, 9, 12]: draw_arc(center, radius, -PI * 0.8, PI * 0.8, 24, metal, 1)
			diamond(center, 2, Color("b8f0e5"))
		3: # Ivory shield and oath blade.
			var shield: PackedVector2Array = PackedVector2Array([center + Vector2(-9, -8), center + Vector2(9, -8), center + Vector2(7, 4), center + Vector2(0, 11), center + Vector2(-7, 4), center + Vector2(-9, -8)])
			draw_polyline(shield, metal, 1)
			draw_line(center + Vector2(0, -10), center + Vector2(0, 8), Color("ecded0"), 2)
			draw_line(center + Vector2(-5, -3), center + Vector2(5, -3), metal, 2)
		4: # Ceremonial crown linked to a neural core.
			draw_polyline(PackedVector2Array([center + Vector2(-10, -4), center + Vector2(-6, 3), center + Vector2(0, -10), center + Vector2(6, 3), center + Vector2(10, -4)]), metal, 2)
			draw_arc(center + Vector2(0, 4), 7, 0, PI, 20, metal, 1)
			diamond(center + Vector2(0, 4), 3, Color("f5bdcc"))

func ornaments(metal: Color) -> void:
	for side: int in [-1, 1]:
		var x: float = 108 if side < 0 else 532
		var end: Vector2 = Vector2(x, 338)
		draw_polyline(PackedVector2Array([end + Vector2(side * 2, -9), end + Vector2(side * 8, -9), end + Vector2(side * 13, -4), end + Vector2(side * 13, 4), end + Vector2(side * 8, 9), end + Vector2(side * 2, 9)]), metal, 1)
		for index: int in 3:
			var point: Vector2 = Vector2(x - side * (7 + index * 5), 330)
			if zone_index == 1:
				draw_line(point, point - Vector2(0, 3 + index % 2), metal, 2)
			elif zone_index == 2:
				draw_line(point, point + Vector2(2, -2), metal, 1)
			elif zone_index == 4:
				draw_arc(point - Vector2(0, 1), 3, PI, TAU, 8, metal, 1)
			else: diamond(point, 1, metal)
		for y: float in [330, 347]:
			draw_rect(Rect2(x - 1, y, 2, 2), metal.lightened(0.2))

func _draw() -> void:
	# Compact instruments sit in the corners; the arena centre stays readable.
	draw_style_box(player_panel, Rect2(10, 8, 213, 53))
	player_crest(Vector2(30, 34))
	text_at("PORTADOR", Vector2(53, 21), 10, Color("ddd7c7"))
	var hp_text: String = "%d / %d" % [health, health_max]
	text_at(hp_text, Vector2(204 - font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, 21), 10, Color("ecd6c7"))
	frame_track(PLAYER_TRACK, player_ratio, player_trail, Color("b63840"), Color("a49274"))
	frame_track(STAMINA_TRACK, clampf(stamina / stamina_max, 0, 1), 0, Color("61b7a3"), Color("557c78"))
	for index: int in range(1, 4):
		var x: float = PLAYER_TRACK.position.x + PLAYER_TRACK.size.x * index / 4
		draw_line(Vector2(x, PLAYER_TRACK.position.y + 1), Vector2(x, PLAYER_TRACK.end.y - 1), Color("210e17", 0.35), 1)
	var metal: Color = PALETTES[zone_index]
	var backdrop: PackedVector2Array = PackedVector2Array([Vector2(69, 309), Vector2(571, 309), Vector2(584, 339), Vector2(566, 355), Vector2(74, 355), Vector2(56, 339)])
	draw_colored_polygon(backdrop, Color("060c16", 0.91))
	draw_line(Vector2(114, 308), Vector2(526, 308), Color(metal, 0.22), 1)
	var title_size: int = 13
	while title_size > 10 and font.get_string_size(boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > 340: title_size -= 1
	var title_width: float = font.get_string_size(boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	text_at(boss_title, Vector2(320 - title_width / 2, 324), title_size, metal.lightened(0.55), 340)
	text_at("II" if phase == 2 else "I", Vector2(538, 324), 11, metal)
	frame_track(BOSS_TRACK, boss_ratio, boss_trail, FILLS[zone_index].lightened(0.08 if phase == 2 else 0.0), Color("7fdac7") if exposed else metal)
	ornaments(metal)
	boss_crest(Vector2(83, 338), metal)
	diamond(Vector2(557, 338), 5, metal.darkened(0.3))
	diamond(Vector2(557, 338), 2, metal.lightened(0.4))

func panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("09111d", 0.92)
	style.border_color = Color("4d5558", 0.7)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_bottom_right = 6
	return style
