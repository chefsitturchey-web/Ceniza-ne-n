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
