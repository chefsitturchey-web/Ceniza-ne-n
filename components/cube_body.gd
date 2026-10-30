class_name CubeBody
extends Node2D

## Reusable placeholder body (corpses, gravedigger, future rats/survivors).
## Draws a centered rectangle with a dark border and an optional single glyph.

@export var fill: Color = Color.WHITE:
	set(value):
		fill = value
		queue_redraw()
@export var size: Vector2 = Vector2(16, 16):
	set(value):
		size = value
		queue_redraw()
@export var glyph: String = "":
	set(value):
		glyph = value
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(-size.x * 0.5, -size.y), size)
	draw_rect(rect, fill)
	draw_rect(rect, Color("0b1322"), false, 1.0)
	if not glyph.is_empty():
		var font: Font = ThemeDB.fallback_font
		var font_size: int = clampi(int(minf(size.x, size.y)) - 6, 4, 16)
		draw_char(font, Vector2(-font_size * 0.3, -3.0), glyph.left(1), font_size, Color("0b1322"))
