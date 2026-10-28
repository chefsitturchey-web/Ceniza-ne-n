class_name WorkerVisual
extends EntityVisual

var actor: ColonyWorker

func _draw() -> void:
	if sprite != null:
		if actor.cargo > 0:
			draw_rect(Rect2(-5, -42, 10, 8), Color("0b1322"))
			draw_rect(Rect2(-4, -41, 8, 6), Color("8299a8"))
			draw_line(Vector2(-3, -39), Vector2(3, -39), Color("b075ae"), 2)
			draw_line(Vector2(0, -41), Vector2(0, -35), Color("304356"), 1)
		return
	draw_rect(Rect2(-5, -19, 10, 19), Color("b075ae"))
	if actor.cargo > 0:
		draw_rect(Rect2(5, -12, 6, 6), Color("8299a8"))
