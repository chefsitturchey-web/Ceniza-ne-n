class_name BossMachineVisual
extends Node2D
## Cuerpos originales por piezas: caldera fija y núcleo de enlaces sumergido.
var actor: Node2D
var kind: String = "caldera"
var opening: float = 0.0
const DARK: Color = Color("0b1322")
const STEEL: Color = Color("304356")
const EDGE: Color = Color("8299a8")
const CHOIR_ART: Texture2D = preload("res://assets/expedition/boss/choir_v2.png")
const CALDERA_ART: Texture2D = preload("res://assets/expedition/boss/caldera_v2.png")

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or actor.health <= 0:
		return
	opening = move_toward(opening, 1.0 if actor.core_exposed else 0.0, delta * 4.0)
	queue_redraw()

func plate(rect: Rect2, color: Color = STEEL) -> void:
	draw_rect(rect.grow(1), DARK)
	draw_rect(rect, color)
	draw_line(rect.position, rect.position + Vector2(rect.size.x - 1, 0), EDGE, 1)
	if rect.size.y > 5:
		draw_rect(Rect2(rect.end - Vector2(rect.size.x, 2), Vector2(rect.size.x, 2)), color.darkened(0.3))

func _draw() -> void:
	if not is_instance_valid(actor) or actor.health <= 0:
		return
	if kind == "caldera":
		draw_caldera()
	else:
		draw_choir()

func draw_caldera() -> void:
	draw_detailed_caldera()

func draw_detailed_caldera() -> void:
	var moving: bool = actor.velocity.length() > 1
	var step: float = sin(actor.elapsed * 8) * (2.0 if moving else 0.4)
	draw_set_transform(Vector2(0, roundf(step)), sin(actor.elapsed * 3) * (0.025 if moving else 0.005))
	draw_texture_rect(CALDERA_ART, Rect2(-66, -66, 132, 132), false)
	for side: int in [-1, 1]:
		var foot: Vector2 = Vector2(side * 50, 28 + roundf(step * side))
		draw_line(Vector2(side * 35, 9), foot, DARK, 5)
		draw_line(Vector2(side * 35, 9), foot, EDGE, 2)
		if GamePreferences.current().particles:
			for puff: int in range(4):
				var age: float = fposmod(actor.elapsed * (25 if opening > 0 else 12) + puff * 8, 34)
				draw_rect(Rect2(side * 18 - 3 + sin(age * 0.3) * 3, -56 - age, 6, 4), Color(0.65, 0.76, 0.81, (1.0 - age / 34) * 0.35))
	if opening > 0:
		draw_circle(Vector2(0, -9), 13, Color(1, 0.78, 0.3, opening * 0.55))
		draw_arc(Vector2(0, -9), 18 + opening * 3, 0, TAU, 24, Color("ffce75"), 2)
	draw_set_transform(Vector2.ZERO)

func draw_legacy_caldera() -> void:
	var open: bool = actor.core_exposed
	for side: int in [-1, 1]:
		plate(Rect2(side * 35 - 9, 25, 18, 28))
		plate(Rect2(side * 37 - 14, 48, 28, 8))
		plate(Rect2(side * 48 - 5, -42, 10, 68), Color("704c43"))
		plate(Rect2(side * 28 - 6, -65, 12, 28))
		for y: int in [-50, -38, -26, -14, -2]:
			draw_line(Vector2(side * 48 - 4, y), Vector2(side * 48 + 4, y), EDGE, 2)
		if actor.state == Recaudador.State.CLAW:
			draw_colored_polygon(PackedVector2Array([Vector2(side * 28 - 5, -65), Vector2(side * 28 + 1, -80), Vector2(side * 28 + 5, -65)]), Color("ffce75"))
	draw_colored_polygon(PackedVector2Array([Vector2(-43, -35), Vector2(-32, -52), Vector2(32, -52), Vector2(43, -35), Vector2(43, 35), Vector2(28, 47), Vector2(-28, 47), Vector2(-43, 35)]), DARK)
	plate(Rect2(-36, -42, 72, 79), Color("704c43"))
	plate(Rect2(-23, -32, 46, 61), Color("182639"))
	draw_rect(Rect2(-17, -28, 34, 52), Color("ffce75") if open else Color("e89e54"))
	for index: int in range(7):
		draw_line(Vector2(-13, -24 + index * 7), Vector2(13, -24 + index * 7), Color("e89e54"), 2)
	var gap: float = roundf(20 * opening)
	plate(Rect2(-23 - gap, -32, 22, 61))
	plate(Rect2(1 + gap, -32, 22, 61))
	for side: int in [-1, 1]:
		var door_x: float = -23 - gap if side < 0 else 1 + gap
		for vent: int in range(5):
			draw_rect(Rect2(door_x + 4, -23 + vent * 9, 14, 2), DARK)
			draw_rect(Rect2(door_x + 5, -22 + vent * 9, 12, 1), Color("e89e54").darkened(0.5))
		# Pistones, válvulas y vapor de purga; no intervienen en el combate.
		var piston: float = roundf(sin(actor.elapsed * 5.0) * 2)
		draw_line(Vector2(side * 39, 4), Vector2(side * 39, 23 + piston), EDGE, 3)
		draw_circle(Vector2(side * 48, -28), 5, DARK)
		draw_line(Vector2(side * 48 - 4, -28), Vector2(side * 48 + 4, -28), EDGE, 1)
		if opening > 0.1 and GamePreferences.current().particles:
			for puff: int in range(5):
				var age: float = fposmod(actor.elapsed * 18 + puff * 7, 28)
				draw_rect(Rect2(side * 28 - 3 + sin(age) * 2, -66 - age, 5 + puff % 2, 3), Color(0.65, 0.76, 0.81, (1.0 - age / 28) * 0.45))
	for side: int in [-1, 1]:
		for y: int in [-36, 31]:
			draw_rect(Rect2(side * 30, y, 3, 3), EDGE)
	plate(Rect2(-12, -50, 24, 12))
	draw_rect(Rect2(-8, -46, 16, 3), Color("dd6482"))
	draw_circle(Vector2(0, -43), 5, DARK)
	var needle: Vector2 = Vector2.from_angle(-2.4 + (sin(actor.elapsed * 2) * 0.15 + 0.6) * 2.0) * 4
	draw_line(Vector2(0, -43), Vector2(0, -43) + needle, Color("ffce75"), 1)
	for x: int in [-15, -7, 1, 9]:
		draw_line(Vector2(x, 39), Vector2(x + 6, 34), Color("ffce75"), 2)

func draw_choir() -> void:
	var turn: float = sin(actor.elapsed * 0.5) * 0.05
	draw_set_transform(Vector2.ZERO, turn)
	draw_texture_rect(CHOIR_ART, Rect2(-73, -78, 146, 146), false, Color(1.12, 1.15, 1.2))
	draw_set_transform(Vector2.ZERO)
	var color: Color = Color("ffce75") if actor.core_exposed else Color("dd6482")
	var gap: float = 8 + opening * 7
	draw_arc(Vector2(0, -5), gap, actor.elapsed * 2, actor.elapsed * 2 + 5, 32, color, 2)
	if GamePreferences.current().particles:
		for index: int in range(5):
			var fall: float = fmod(actor.elapsed * 15 + index * 13, 48)
			draw_rect(Rect2(sin(index * 3.0) * 38, 25 + fall, 1, 2), Color("47dacb", (1 - fall / 48) * 0.5))
