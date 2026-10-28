class_name MachineRig
extends Node2D
## Siluetas originales animadas por piezas; coordenadas redondeadas a píxeles.
## Ningún estado visual determina el instante del daño.
const OUTLINE: Color = Color("0b1322")
const STEEL: Color = Color("304356")
const EDGE: Color = Color("8299a8")
const RUST: Color = Color("e89e54")
const SENSOR: Color = Color("dd6482")
var actor: Node2D
var kind: String = ""
var elapsed: float = 0.0
var death_time: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	if actor.health <= 0:
		death_time += delta
	queue_redraw()

func _plate(rect: Rect2, fill: Color = STEEL) -> void:
	draw_rect(rect.grow(1), OUTLINE)
	draw_rect(rect, fill)
	if rect.size.y >= 6:
		draw_rect(Rect2(rect.end - Vector2(rect.size.x, 2), Vector2(rect.size.x, 2)), fill.darkened(0.3))
		draw_line(rect.position + Vector2(rect.size.x - 1, 1), rect.end - Vector2(1, 1), OUTLINE, 1)
	draw_line(rect.position, rect.position + Vector2(rect.size.x - 1, 0), EDGE, 1)
	if rect.size.x >= 9 and rect.size.y >= 8:
		for point: Vector2 in [rect.position + Vector2(2, 2), rect.end - Vector2(3, 3)]:
			draw_rect(Rect2(point, Vector2.ONE), EDGE)
		draw_line(rect.position + Vector2(3, rect.size.y - 4), rect.position + Vector2(6, rect.size.y - 4), fill.lightened(0.17), 1)

func _joint(from: Vector2, to: Vector2, width: float = 3.0, tint: Color = EDGE) -> void:
	from = from.round()
	to = to.round()
	draw_line(from, to, OUTLINE, width + 2)
	draw_line(from, to, tint, width)
	draw_rect(Rect2(from - Vector2.ONE, Vector2(2, 2)), RUST)

func _sensor(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at, at + Vector2(6, 2), at + Vector2(0, 4)]), SENSOR)
	draw_rect(Rect2(at + Vector2(1, 1), Vector2.ONE), Color("ffce75"))

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	if actor.health <= 0:
		modulate.a = clampf(1.0 - death_time / 1.0, 0.0, 1.0)
		_plate(Rect2(-13, -7, 19, 6))
		_plate(Rect2(4, -11, 9, 9), RUST if kind == "ariete" else STEEL)
		_joint(Vector2(-9, -5), Vector2(-18, -1), 2)
		_joint(Vector2(7, -4), Vector2(18, -2), 2)
		return
	modulate.a = 1
	var step: float = roundf(sin(elapsed * (8.0 if kind == "saltador" else 5.0)) * 3) if actor.visual.walking else 0.0
	var anticipation: float = 1.0 if actor.windup > 0 else 0.0
	var damaged: bool = actor.flash > 0 and not GamePreferences.current().reduced_flashes
	draw_set_transform(Vector2.ZERO, 0, Vector2(actor.facing, 1))
	match kind:
		"blindado": _draw_shielded(step, anticipation, damaged)
		"saltador": _draw_jumper(step, anticipation, damaged)
		"ariete": _draw_ram(step, anticipation, damaged)
	draw_set_transform(Vector2.ZERO)

func _draw_shielded(step: float, anticipation: float, damaged: bool) -> void:
	# Cabeza hundida, pecho ancho y piernas cortas: peso y protección frontal.
	_joint(Vector2(-6, -16), Vector2(-7 + step, -5), 4, STEEL)
	_joint(Vector2(5, -16), Vector2(7 - step, -5), 4, STEEL)
	_plate(Rect2(-13 + step, -5, 10, 4))
	_plate(Rect2(3 - step, -5, 12, 4))
	_plate(Rect2(-12, -32, 24, 18), EDGE if damaged else STEEL)
	_plate(Rect2(-8, -38, 15, 9), STEEL)
	_sensor(Vector2(1, -35))
	_plate(Rect2(-14, -32, 9, 7), Color("526978"))
	_plate(Rect2(4, -32, 10, 8), Color("526978"))
	_joint(Vector2(8, -24), Vector2(13 + anticipation * 2, -19), 4)
	for y: int in [-27, -24, -21]:
		draw_rect(Rect2(-8, y, 7, 1), OUTLINE)
	for point: Vector2 in [Vector2(-10, -30), Vector2(10, -30), Vector2(-10, -16), Vector2(10, -16)]:
		draw_rect(Rect2(point, Vector2.ONE), EDGE)
	draw_rect(Rect2(2, -25, 3, 6), RUST)
	draw_line(Vector2(-10, -13), Vector2(9, -13), OUTLINE, 2)

func _draw_jumper(step: float, anticipation: float, damaged: bool) -> void:
	# Torso en cuña, patas largas y muelles visibles; compresión antes del salto.
	var crouch: float = 5.0 if float(actor.get("crouch")) > 0 else anticipation * 2
	var body: Vector2 = Vector2(0, crouch)
	_joint(body + Vector2(-6, -16), Vector2(-13 + step, -10), 2)
	_joint(Vector2(-13 + step, -10), Vector2(-8 - step, -2), 2)
	_joint(body + Vector2(6, -16), Vector2(12 - step, -11), 2)
	_joint(Vector2(12 - step, -11), Vector2(8 + step, -2), 2)
	for index: int in range(4):
		draw_line(Vector2(-11, -15 + index * 2), Vector2(-6, -13 + index * 2), RUST, 1)
	_plate(Rect2(-12 - step, -3, 8, 2))
	_plate(Rect2(5 + step, -3, 10, 2))
	var hull: PackedVector2Array = PackedVector2Array([body + Vector2(-14, -26), body + Vector2(8, -29), body + Vector2(16, -22), body + Vector2(8, -16), body + Vector2(-11, -17)])
	draw_colored_polygon(hull, EDGE if damaged else Color("526978"))
	hull.append(hull[0])
	draw_polyline(hull, OUTLINE, 1)
	draw_line(body + Vector2(-11, -25), body + Vector2(5, -27), EDGE, 1)
	_sensor(body + Vector2(7, -24))
	_plate(Rect2(body + Vector2(-15, -22), Vector2(6, 8)), RUST)
	draw_rect(Rect2(body + Vector2(-6, -22), Vector2(6, 2)), OUTLINE)
	if float(actor.get("airborne")) > 0:
		draw_line(body + Vector2(-13, -14), body + Vector2(-17, -6), Color("ffce75"), 2)
		draw_rect(Rect2(body + Vector2(-16, -9), Vector2(2, 4)), RUST)

func _draw_ram(step: float, anticipation: float, damaged: bool) -> void:
	# Bloque pesado con contrapeso, cilindro hidráulico y placas de impacto.
	_joint(Vector2(-8, -16), Vector2(-9 + step, -5), 5, STEEL)
	_joint(Vector2(6, -16), Vector2(8 - step, -5), 5, STEEL)
	_plate(Rect2(-15 + step, -5, 12, 4))
	_plate(Rect2(3 - step, -5, 14, 4))
	_plate(Rect2(-14, -34, 28, 19), EDGE if damaged else Color("704c43"))
	_plate(Rect2(-16, -32, 10, 17), STEEL)
	_plate(Rect2(-5, -38, 17, 9), STEEL)
	_sensor(Vector2(5, -35))
	_joint(Vector2(-2, -23), Vector2(16 - anticipation * 3, -20), 5)
	draw_line(Vector2(-1, -25), Vector2(13, -22), EDGE, 1)
	_plate(Rect2(-12, -32, 6, 10), RUST)
	for y: int in [-29, -26, -23]:
		draw_rect(Rect2(-11, y, 4, 1), OUTLINE)
	for x: int in [-3, 1, 5]:
		draw_line(Vector2(x, -17), Vector2(x + 3, -20), Color("ffce75"), 1)
	for point: Vector2 in [Vector2(-12, -33), Vector2(11, -33), Vector2(-12, -16), Vector2(10, -16)]:
		draw_rect(Rect2(point, Vector2.ONE), EDGE)
