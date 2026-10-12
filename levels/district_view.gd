class_name DistrictView
extends Node2D

const FLOOR_Y: float = GameRules.FLOOR_Y
var cycle: CycleSystem
var defenses: DefenseSystem
var player: Player
const GROUND: Texture2D = preload("res://assets/structures/ground_strip.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _draw() -> void:
	var night: bool = cycle.phase == "NOCHE"
	for index: int in range(24):
		var x: float = -960.0 + index * 80.0
		var height: float = 60.0 + float((index * 37) % 95)
		draw_rect(Rect2(x, FLOOR_Y - height, 55, height), Color("0b1322") if night else Color("182639"))
		draw_rect(Rect2(x + 12, FLOOR_Y - height + 12, 4, 16), Color("477687"))
	draw_rect(Rect2(-960, FLOOR_Y, 1920, 80), Color("0b1322"))
	draw_texture_rect(GROUND, Rect2(-960, FLOOR_Y, 1920, GROUND.get_height()), true)
	if is_instance_valid(player) and player.health > 0:
		draw_circle(player.position + Vector2(-18, -48), 5, Color("47dacb"))
	for beam: Dictionary in defenses.beams:
		draw_line(beam.from, beam.to, Color("ffce75"), 2.0)
