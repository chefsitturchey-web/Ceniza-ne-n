class_name WorkerVisual
extends EntityVisual

var actor: ColonyWorker

func _draw() -> void:
	if sprite != null:
		return
	draw_rect(Rect2(-5, -19, 10, 19), Color("b075ae"))
	if actor.cargo > 0:
		draw_rect(Rect2(5, -12, 6, 6), Color("8299a8"))
