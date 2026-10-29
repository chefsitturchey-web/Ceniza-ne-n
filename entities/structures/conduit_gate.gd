class_name ConduitGate
extends EnemyRepeater

func _draw() -> void:
	var source: Rect2 = ArtScale.source(GameArt.CIVIC, 5)
	if health.current <= 0:
		source.position.y += source.size.y * 0.84
		source.size.y *= 0.16
		draw_texture_rect_region(GameArt.CIVIC, Rect2(-44, -13, 88, 13), source, Color("8299a8"))
		return
	draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(source, 72), source)
	var center: Vector2 = Vector2(0, -39)
	draw_arc(center, 13, effects.elapsed * 1.4, effects.elapsed * 1.4 + 4.5, 24, Color("dd6482", 0.7), 1)
	for index: int in range(6):
		var point: Vector2 = center + Vector2.from_angle(effects.elapsed + index * TAU / 6) * (14 + sin(effects.elapsed * 3 + index) * 5)
		draw_rect(Rect2(point, Vector2(1, 2)), Color("dd6482"))
	if defense_warning > 0:
		draw_arc(center, 27, 0, TAU, 32, Color("ffce75", 0.8), 2)
