class_name NeuralClinic
extends Node2D
## Terminal propio dibujado en píxeles; comparte la paleta del núcleo.
var elapsed: float = 0.0
var available: bool = false

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var source: Rect2 = ArtScale.source(GameArt.CIVIC, 3)
	var frame: Rect2 = ArtScale.grounded(source, 40)
	ArtScale.footing(self, frame)
	draw_texture_rect_region(GameArt.CIVIC, frame, source)
	if available:
		draw_circle(Vector2(0, -30), 3, Color("47dacb", 0.2 + sin(elapsed * 3) * 0.1))
