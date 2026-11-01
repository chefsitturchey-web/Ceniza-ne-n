class_name MenuBackdrop
extends Control
var art: Texture2D
var elapsed: float = 0

func _ready() -> void:
	if size.x < 640: size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	art = load("res://assets/ui/menu/ruinas_menu.png")

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not GamePreferences.current().reduced_flashes: elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07101b"))
	if art != null:
		# Cubre todo el ancho sin deformar: en pantallas anchas se recorta arriba y abajo.
		var cover: Vector2 = (Vector2(640, 360) + Vector2(16, 8)) * maxf(1.0, size.x / 640.0)
		draw_texture_rect(art, Rect2(Vector2(-8 + sin(elapsed * 0.08) * 5, (size.y - cover.y) / 2.0), cover), false, Color(0.3, 0.4, 0.45))
	draw_rect(Rect2(Vector2.ZERO, size), Color("050c17", 0.58))
	for index: int in 4:
		var y: float = 32 + index * 88
		draw_line(Vector2(0, y), Vector2(size.x, y - 75 * size.x / 640.0), Color("678984", 0.04), 24)
	if GamePreferences.current().particles:
		for index: int in 24:
			var at: Vector2 = Vector2(fposmod(index * 83 + elapsed * 4, size.x), fposmod(index * 47 - elapsed * 3, 360))
			draw_circle(at, 0.7 + index % 2 * 0.4, Color("c5ae7b", 0.17))
	draw_line(Vector2(14, 14), Vector2(size.x - 14, 14), Color("b5a275", 0.3), 1)
	draw_line(Vector2(14, 346), Vector2(size.x - 14, 346), Color("b5a275", 0.3), 1)
