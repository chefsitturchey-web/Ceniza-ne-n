class_name ConduitGate
extends EnemyRepeater

func _draw() -> void:
	var center: Vector2 = Vector2(0, -33)
	if health.current <= 0:
		draw_rect(Rect2(-24, -8, 48, 8), Color("304356"))
		return
	draw_circle(center, 29, Color("0b1322"))
	draw_arc(center, 28, 0, TAU, 32, Color("8299a8"), 4)
	for index: int in range(8):
		var point: Vector2 = center + Vector2.from_angle(index * TAU / 8) * 28
		draw_rect(Rect2(point - Vector2(3, 4), Vector2(6, 8)), Color("704c43"))
	draw_arc(center, 21, effects.elapsed, effects.elapsed + 5.4, 28, Color("dd6482"), 2)
	draw_circle(center, 17, Color("dd6482", 0.15))
	draw_line(center + Vector2(-10, -13), center + Vector2(5, 0), Color("dd6482"), 2)
	draw_line(center + Vector2(5, 0), center + Vector2(-7, 14), Color("ffce75"), 1)
