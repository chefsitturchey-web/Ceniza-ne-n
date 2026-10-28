class_name NetworkRelay
extends Node2D
const ART: Texture2D = preload("res://assets/expedition/repeater.png")
var health: int = 120
var elapsed: float = 0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(ART, Rect2(-16, -40, 32, 60), false, Color("47dacb") if health > 0 else Color("53616d"))
	draw_rect(Rect2(-18, -49, 36, 4), Color("182639"))
	draw_rect(Rect2(-18, -49, 36.0 * health / 120, 4), Color("47dacb") if health > 30 else Color("ffce75"))
	if health > 0:
		draw_arc(Vector2(0, -8), 21, elapsed, elapsed + 3.5, 28, Color("47dacb", 0.35), 1)
