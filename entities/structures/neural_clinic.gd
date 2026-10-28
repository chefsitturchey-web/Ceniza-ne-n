class_name NeuralClinic
extends Node2D
## Terminal propio dibujado en píxeles; comparte la paleta del núcleo.
var elapsed: float = 0.0
var available: bool = false

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-18, -2, 36, 2), Color("0b1322"))
	draw_rect(Rect2(-14, -35, 28, 33), Color("0b1322"))
	draw_rect(Rect2(-12, -33, 24, 29), Color("304356"))
	draw_rect(Rect2(-11, -32, 22, 2), Color("8299a8"))
	draw_rect(Rect2(-9, -28, 18, 13), Color("182639"))
	var pulse: float = 0.65 + sin(elapsed * 3.0) * 0.25
	var color: Color = Color("47dacb") if available else Color("8299a8")
	draw_rect(Rect2(-1, -26, 3, 9), color)
	draw_rect(Rect2(-4, -23, 9, 3), color)
	draw_rect(Rect2(-7, -11, 14, 2), Color(color, pulse))
	for x: int in [-9, 8]:
		draw_rect(Rect2(x, -6, 2, 2), Color("ffce75"))
	if available:
		draw_line(Vector2(-8, -40), Vector2(0, -37), Color(color, pulse), 1)
		draw_line(Vector2(0, -37), Vector2(8, -40), Color(color, pulse), 1)
