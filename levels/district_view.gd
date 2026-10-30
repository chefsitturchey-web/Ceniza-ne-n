class_name DistrictView
extends Node2D

const FLOOR_Y: float = GameRules.FLOOR_Y
var cycle: CycleSystem
var defenses: DefenseSystem
var player: Player
var zone: ZoneData:
	set(value):
		zone = value
		district_background = load(zone.background_path) as Texture2D if zone != null and not zone.background_path.is_empty() else DEFAULT_BACKGROUND
		queue_redraw()
const DEFAULT_BACKGROUND: Texture2D = preload("res://assets/world/backgrounds/layers/periphery_alive_v2.png")
var district_background: Texture2D = DEFAULT_BACKGROUND
const GROUND: Texture2D = preload("res://assets/world/structures/ground_strip.png")
## Cuánto siguen las capas a la cámara: 1 queda fija en pantalla, 0 se mueve con el mundo.
## Decoración fija del distrito: [textura, x]. Lejos de las obras (±180, ±240) y del núcleo.
const PROPS: Array = [
	[preload("res://assets/world/props/sign.png"), -810.0], [preload("res://assets/world/props/car.png"), -720.0],
	[preload("res://assets/world/props/crate.png"), -630.0], [preload("res://assets/world/props/lamp.png"), -560.0],
	[preload("res://assets/world/props/scrap.png"), -470.0], [preload("res://assets/world/props/barrel.png"), -395.0],
	[preload("res://assets/world/props/barrel.png"), -380.0], [preload("res://assets/world/props/lamp.png"), -330.0],
	[preload("res://assets/world/props/lamp.png"), 330.0], [preload("res://assets/world/props/scrap.png"), 420.0],
	[preload("res://assets/world/props/crate.png"), 455.0], [preload("res://assets/world/props/lamp.png"), 775.0],
	[preload("res://assets/world/props/spool.png"), 700.0], [preload("res://assets/world/props/sign.png"), 825.0],
]
const LAMP: Texture2D = preload("res://assets/world/props/lamp.png")

## Luz de cada fase: cielo arriba/abajo, bruma sobre las capas lejana/media, luz del mundo y farolas.
const LIGHTING: Dictionary = {
	"DÍA": {"sky_top": Color("7b93a6"), "sky_bottom": Color("d8b98e"), "far_haze": 0.62, "mid_haze": 0.3,
		"world": Color(1.0, 1.0, 1.0), "lamps": 0.0},
	"AVISO": {"sky_top": Color("3b3352"), "sky_bottom": Color("e07a4c"), "far_haze": 0.45, "mid_haze": 0.18,
		"world": Color(1.0, 0.86, 0.78), "lamps": 0.7},
	"NOCHE": {"sky_top": Color("05070d"), "sky_bottom": Color("16233a"), "far_haze": 0.12, "mid_haze": 0.0,
		"world": Color(0.66, 0.72, 0.92), "lamps": 1.0},
}
## Segundos aproximados de cada transición entre fases.
const TRANSITION_TIME: float = 2.5

var light: Dictionary = LIGHTING["DÍA"].duplicate()
var daylight: CanvasModulate = CanvasModulate.new()
var time: float = 0.0
var redraw_clock: float = 0
var last_camera_x: float = INF

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(daylight)

func _process(delta: float) -> void:
	time += delta
	if cycle == null:
		return
	var target: Dictionary = LIGHTING.get(cycle.phase, LIGHTING["DÍA"]).duplicate()
	if cycle.phase != "NOCHE":
		var colors: Array = DistrictDepth.SKY_COLORS.get(zone.id if zone != null else "periphery", DistrictDepth.SKY_COLORS.periphery)
		target.sky_top = colors[0] if cycle.phase == "DÍA" else colors[0].lerp(Color("3b3352"), 0.55)
		target.sky_bottom = colors[1] if cycle.phase == "DÍA" else colors[1].lerp(Color("b67d65"), 0.5)
	var weight: float = clampf(delta / TRANSITION_TIME * 3.0, 0.0, 1.0)
	for key: String in light:
		light[key] = lerp(light[key], target[key], weight)
	daylight.color = light["world"]
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		var camera_x: float = camera.get_screen_center_position().x
		if absf(camera_x - last_camera_x) > 0.5:
			last_camera_x = camera_x
			queue_redraw()
	redraw_clock += delta
	if redraw_clock >= 1.0 / 30:
		redraw_clock = fmod(redraw_clock, 1.0 / 30)
		queue_redraw()

func _draw() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0.0
	_draw_sky(camera_x)
	var zone_id: String = zone.id if zone != null else "periphery"
	DistrictDepth.draw_far(self, camera_x, time, zone_id, light["sky_bottom"])
	if district_background != null:
		DistrictDepth.draw_architecture(self, district_background, camera_x, time, zone_id)
		_draw_haze(camera_x, light["far_haze"] * 0.16)
	DistrictDepth.draw_near(self, camera_x, time, zone_id)
	for index: int in range(PROPS.size()):
		var texture: Texture2D = PROPS[index][0]
		var size: Vector2 = texture.get_size()
		var top_left: Vector2 = Vector2(roundf(PROPS[index][1] - size.x / 2.0), FLOOR_Y - size.y)
		if texture == LAMP and light["lamps"] > 0.05:
			_draw_lamp_glow(top_left + Vector2(size.x - 4.0, 4.0), index)
		draw_texture(texture, top_left)
	draw_rect(Rect2(-GameRules.MAP_HALF_WIDTH, FLOOR_Y, GameRules.MAP_HALF_WIDTH * 2, 80), Color("0b1322"))
	draw_texture_rect(GROUND, Rect2(-GameRules.MAP_HALF_WIDTH, FLOOR_Y, GameRules.MAP_HALF_WIDTH * 2, GROUND.get_height()), true)
	_draw_wet_ground(camera_x)
	_draw_ash(camera_x)
	if is_instance_valid(player) and player.health > 0 and (defenses.modules == null or "drone" in defenses.modules.equipped):
		_draw_drone(player.position + Vector2(-18, -48))
		if defenses.modules != null and defenses.modules.evolved.drone:
			_draw_drone(player.position + Vector2(18, -44))
	for beam: Dictionary in defenses.beams:
		var tint: Color = Color("47dacb") if beam.get("electric", false) else Color("ffce75")
		draw_line(beam.from, beam.to, Color(1.0, 0.66, 0.3, 0.12), 7.0)
		draw_line(beam.from, beam.to, tint, 2.0)
		draw_line(beam.from, beam.to, Color("fff2cd"), 1.0)

func _draw_drone(origin: Vector2) -> void:
	origin.y += roundf(sin(time * 3.0) * 2.0)
	draw_circle(origin, 12, Color(0.28, 0.85, 0.8, 0.06))
	draw_rect(Rect2(origin + Vector2(-7, -3), Vector2(14, 6)), Color("0b1322"))
	draw_rect(Rect2(origin + Vector2(-5, -2), Vector2(10, 4)), Color("8299a8"))
	draw_rect(Rect2(origin + Vector2(-2, -1), Vector2(4, 2)), Color("47dacb"))
	for side: int in [-1, 1]:
		draw_line(origin + Vector2(side * 7, -4), origin + Vector2(side * 3, -4), Color("304356"), 2)
		draw_rect(Rect2(origin + Vector2(side * 4 - 1, 4), Vector2(2, 2 + int(time * 12) % 2)), Color("47dacb"))
	for rank: int in range(defenses.drone_rank):
		draw_rect(Rect2(origin + Vector2(-3 + rank * 3, -3), Vector2(2, 1)), Color("ffce75"))

func _draw_ash(camera_x: float) -> void:
	if not GamePreferences.current().particles:
		return
	# Campo determinista acotado; no usa el RNG de combate ni crea nodos.
	for index: int in range(54):
		var x: float = fposmod(index * 73.0 + time * (5.0 + index % 4) - camera_x * 0.25, 800.0) + camera_x - 400
		var y: float = fposmod(index * 47.0 + time * (9.0 + index % 7), 370.0) - 100
		var ember: bool = index % 11 == 0
		draw_rect(Rect2(roundf(x), roundf(y), 1, 2 if ember else 1), Color(0.9, 0.57, 0.3, 0.45) if ember else Color(0.73, 0.8, 0.85, 0.22))

func _draw_wet_ground(camera_x: float) -> void:
	for index: int in range(floori((camera_x - 450) / 106), ceili((camera_x + 450) / 106)):
		var x: float = index * 106.0
		if absf(x - camera_x) > 430:
			continue
		var width: float = 32.0 + index % 3 * 13.0
		draw_rect(Rect2(x, FLOOR_Y + 2, width, 7), Color("111e30"))
		draw_line(Vector2(x + 3, FLOOR_Y + 3), Vector2(x + width - 4, FLOOR_Y + 3), Color(0.51, 0.65, 0.73, 0.16), 1)
	for entry: Array in PROPS:
		if entry[0] != LAMP or light["lamps"] <= 0.05:
			continue
		var x: float = entry[1] + LAMP.get_width() * 0.5 - 4
		for line: int in range(7):
			var half: float = 11 - line + sin(time * 2.0 + line) * 2
			draw_line(Vector2(x - half, FLOOR_Y + 2 + line * 2), Vector2(x + half, FLOOR_Y + 2 + line * 2), Color(1.0, 0.7, 0.3, light["lamps"] * (0.17 - line * 0.02)), 1)
	_reflect_actor(player)
	var count: int = 0
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if count >= 24:
			break
		if absf(enemy.position.x - camera_x) < 370:
			_reflect_actor(enemy)
			count += 1

func _reflect_actor(actor: Node2D) -> void:
	if not is_instance_valid(actor) or absf(actor.position.y - FLOOR_Y) > 5:
		return
	var sprite: AnimatedSprite2D = actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or not sprite.visible or sprite.sprite_frames == null:
		return
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var size: Vector2 = texture.get_size() * sprite.scale
	draw_set_transform(Vector2(actor.position.x, FLOOR_Y + 2), 0, Vector2(-1 if sprite.flip_h else 1, -0.23))
	draw_texture_rect(texture, Rect2(-size.x / 2, -size.y, size.x, size.y), false, Color(0.5, 0.67, 0.78, 0.17))
	draw_set_transform(Vector2.ZERO)

func _draw_sky(_camera_x: float) -> void:
	var left: float = -GameRules.MAP_HALF_WIDTH - 400.0
	var right: float = GameRules.MAP_HALF_WIDTH + 400.0
	var top: float = -420.0
	var horizon: float = FLOOR_Y
	var points: PackedVector2Array = [Vector2(left, top), Vector2(right, top), Vector2(right, horizon), Vector2(left, horizon)]
	var colors: PackedColorArray = [light["sky_top"], light["sky_top"], light["sky_bottom"], light["sky_bottom"]]
	draw_polygon(points, colors)

func _draw_haze(_camera_x: float, amount: float) -> void:
	# Perspectiva atmosférica: de día lo lejano se aclara hacia el color del horizonte.
	if amount <= 0.01:
		return
	var haze: Color = light["sky_bottom"]
	var top: Color = Color(haze, 0.0)
	var bottom: Color = Color(haze, amount)
	var points: PackedVector2Array = [Vector2(-GameRules.MAP_HALF_WIDTH - 400, -100.0), Vector2(GameRules.MAP_HALF_WIDTH + 400, -100.0),
		Vector2(GameRules.MAP_HALF_WIDTH + 400, FLOOR_Y), Vector2(-GameRules.MAP_HALF_WIDTH - 400, FLOOR_Y)]
	draw_polygon(points, [top, top, bottom, bottom])

func _draw_lamp_glow(bulb: Vector2, index: int) -> void:
	# Parpadeo ocasional distinto por farola, sin aleatoriedad: depende del tiempo y del índice.
	var flicker: float = 1.0
	var phase: float = fmod(time * 0.7 + index * 1.37, 6.0)
	if phase < 0.25 and not GamePreferences.current().reduced_flashes:
		flicker = 0.35 if int(phase * 40.0) % 2 == 0 else 1.0
	var strength: float = light["lamps"] * flicker
	for ring: int in range(3):
		draw_circle(bulb, 26.0 - ring * 8.0, Color(1.0, 0.81, 0.46, (0.05 + ring * 0.04) * strength))
	draw_rect(Rect2(bulb - Vector2(2, 1), Vector2(4, 2)), Color(1.0, 0.9, 0.6, strength))

func _draw_layer(texture: Texture2D, offset_x: float) -> void:
	var width: float = texture.get_width()
	var start: float = roundf(offset_x - width * 3.0)
	draw_texture_rect(texture, Rect2(start, FLOOR_Y - texture.get_height(), width * 6.0, texture.get_height()), true)
