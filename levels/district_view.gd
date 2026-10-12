class_name DistrictView
extends Node2D

const FLOOR_Y: float = GameRules.FLOOR_Y
var cycle: CycleSystem
var defenses: DefenseSystem
var player: Player
const GROUND: Texture2D = preload("res://assets/structures/ground_strip.png")
const BACKGROUND_FAR: Texture2D = preload("res://assets/background/background_far.png")
const BACKGROUND_MID: Texture2D = preload("res://assets/background/background_mid.png")
## Cuánto siguen las capas a la cámara: 1 queda fija en pantalla, 0 se mueve con el mundo.
const FAR_FOLLOW: float = 0.8
## Decoración fija del distrito: [textura, x]. Lejos de las obras (±180, ±240) y del núcleo.
const PROPS: Array = [
	[preload("res://assets/props/sign.png"), -880.0], [preload("res://assets/props/car.png"), -720.0],
	[preload("res://assets/props/crate.png"), -630.0], [preload("res://assets/props/lamp.png"), -560.0],
	[preload("res://assets/props/scrap.png"), -470.0], [preload("res://assets/props/barrel.png"), -395.0],
	[preload("res://assets/props/barrel.png"), -380.0], [preload("res://assets/props/lamp.png"), -330.0],
	[preload("res://assets/props/lamp.png"), 330.0], [preload("res://assets/props/scrap.png"), 420.0],
	[preload("res://assets/props/crate.png"), 520.0], [preload("res://assets/props/lamp.png"), 610.0],
	[preload("res://assets/props/spool.png"), 700.0], [preload("res://assets/props/sign.png"), 860.0],
]
const LAMP: Texture2D = preload("res://assets/props/lamp.png")
const MID_FOLLOW: float = 0.55

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _draw() -> void:
	var night: bool = cycle.phase == "NOCHE"
	var tint: Color = Color(0.6, 0.62, 0.78) if night else Color.WHITE
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0.0
	_draw_layer(BACKGROUND_FAR, camera_x * FAR_FOLLOW, tint)
	_draw_layer(BACKGROUND_MID, camera_x * MID_FOLLOW, tint)
	for prop: Array in PROPS:
		var texture: Texture2D = prop[0]
		var size: Vector2 = texture.get_size()
		var top_left: Vector2 = Vector2(roundf(prop[1] - size.x / 2.0), FLOOR_Y - size.y)
		if night and texture == LAMP:  # halo de la farola encendida
			var bulb: Vector2 = top_left + Vector2(size.x - 4.0, 4.0)
			for ring: int in range(3):
				draw_circle(bulb, 26.0 - ring * 8.0, Color(1.0, 0.81, 0.46, 0.05 + ring * 0.04))
		draw_texture(texture, top_left, tint)
	draw_rect(Rect2(-960, FLOOR_Y, 1920, 80), Color("0b1322"))
	draw_texture_rect(GROUND, Rect2(-960, FLOOR_Y, 1920, GROUND.get_height()), true)
	if is_instance_valid(player) and player.health > 0:
		draw_circle(player.position + Vector2(-18, -48), 5, Color("47dacb"))
	for beam: Dictionary in defenses.beams:
		draw_line(beam.from, beam.to, Color("ffce75"), 2.0)

func _draw_layer(texture: Texture2D, offset_x: float, tint: Color) -> void:
	var width: float = texture.get_width()
	var start: float = roundf(offset_x - width * 3.0)
	draw_texture_rect(texture, Rect2(start, FLOOR_Y - texture.get_height(), width * 6.0, texture.get_height()), true, tint)
