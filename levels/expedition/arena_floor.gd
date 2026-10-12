extends Node2D

const FLOOR: Texture2D = preload("res://assets/expedition/arena/floor.png")
const EDGE: Texture2D = preload("res://assets/expedition/arena/edge.png")

func _draw() -> void:
	for x: int in range(20):
		for y: int in range(15):
			draw_texture(FLOOR, Vector2(x * 32, y * 32), Color("929aa4"))
	for x: int in range(20):
		draw_texture(EDGE, Vector2(x * 32, 0))
		draw_texture(EDGE, Vector2(x * 32, 468))
	draw_set_transform(Vector2(12, 0), PI / 2)
	for y: int in range(15):
		draw_texture(EDGE, Vector2(y * 32, 0))
	draw_set_transform(Vector2(640, 0), PI / 2)
	for y: int in range(15):
		draw_texture(EDGE, Vector2(y * 32, 0))
	draw_set_transform(Vector2.ZERO)
	for x: int in [48, 592]:
		for y: int in [80, 400]:
			draw_rect(Rect2(x - 5, y - 2, 10, 4), Color("ffce75"))
