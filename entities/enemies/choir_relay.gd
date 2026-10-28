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
		draw_rect(Rect2(-12, -5, 24, 10), Color("304356"))
		draw_line(Vector2(-11, -7), Vector2(8, 3), Color("8299a8"), 2)
		return
	draw_rect(Rect2(-8, -24, 16, 25), Color("0b1322"))
	draw_rect(Rect2(-6, -23, 12, 23), Color("304356"))
	draw_circle(Vector2(0, -24), 12, Color("0b1322"))
	draw_arc(Vector2(0, -24), 9, 0.2, TAU - 0.2, 16, Color("8299a8"), 2)
	draw_circle(Vector2(0, -24), 4, Color("ffce75") if pulse > 0 else Color("dd6482"))
	for y: int in [-15, -11, -7]:
		draw_rect(Rect2(-3, y, 6, 1), Color("8299a8"))
