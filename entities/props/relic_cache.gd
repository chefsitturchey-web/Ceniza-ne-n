class_name RelicCache
extends Node2D

var system: SettlementSystem
var kind: int = 0
var claimed: bool = false
var elapsed: float = 0
var art: Texture2D
const CRATE: Texture2D = preload("res://assets/world/props/crate.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art = load("res://assets/world/settlements/components.png")

func tick(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(CRATE, Rect2(-17, -21, 34, 22), false, Color("53616d") if claimed else Color.WHITE)
	if claimed:
		draw_line(Vector2(-10, -17), Vector2(11, -9), Color("0b1322"), 3)
		return
	draw_texture_rect_region(art, Rect2(-12, -38 + sin(elapsed * 2), 24, 24), Rect2(kind * 24, 0, 24, 24))
	for index: int in 3: draw_rect(Rect2(-7 + index * 6, -4, 3, 2), Color("47dacb"))
