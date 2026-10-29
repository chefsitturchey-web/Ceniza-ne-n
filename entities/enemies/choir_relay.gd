class_name ChoirRelay
extends Node2D

var health: int = 180
var maximum: int = 180
var elapsed: float = 0.0
var pulse: float = 0.0

func receive(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	pulse = 0.15
	queue_redraw()

func reset_relay(value: int) -> void:
	maximum = value
	health = value
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	pulse = maxf(0, pulse - delta)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_circle(Vector2(0, 3), 18, Color("0b1322"))
	draw_set_transform(Vector2.ZERO)
	if health <= 0:
		draw_set_transform(Vector2(0, -5), 0.3, Vector2(1, 0.55))
		draw_texture_rect(DepotArt.machine(1), Rect2(-17, -12, 34, 28), false, Color("45424a"))
		draw_set_transform(Vector2.ZERO)
		return
	draw_texture_rect(DepotArt.machine(1), Rect2(-21, -34, 42, 36), false, Color("d1b9c3"))
	var arm: Vector2 = Vector2.from_angle(elapsed * 1.3) * 10
	draw_line(Vector2(4, -25), Vector2(4, -25) + arm, Color("ffce75"), 1)
	draw_circle(Vector2(-8, -18), 2, Color("ffce75") if pulse > 0 else Color("dd6482"))
	draw_arc(Vector2(0, -13), 23, -PI / 2, -PI / 2 + TAU * health / maximum, 32, Color("dd6482", 0.65), 1)
