class_name DepotArenaVisual
extends Node2D
const FLOOR: Texture2D = preload("res://assets/world/expedition/arena/floor.png")
const CANAL: Texture2D = preload("res://assets/world/backgrounds/layers/periphery_alive_v2.png")
var elapsed: float = 0
var redraw_clock: float = 0

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _process(delta: float) -> void:
	elapsed += delta
	redraw_clock += delta
	if redraw_clock >= 1.0 / 24:
		redraw_clock = fmod(redraw_clock, 1.0 / 24)
		queue_redraw()

func draw_prop(index: int, at: Vector2, extent: Vector2) -> void:
	draw_texture_rect(DepotArt.prop(index), Rect2(at, extent), false)

func _draw() -> void:
	draw_rect(Rect2(-130, -90, 900, 660), Color("091823"))
	for row: int in range(8):
		var drift: float = sin(elapsed * 0.6 + row * 1.2) * 3
		draw_texture_rect_region(CANAL, Rect2(-130 + drift, -50 + row * 80, 900, 80), Rect2(0, 850, CANAL.get_width(), 80), Color(0.28, 0.43, 0.52))
	var edge: PackedVector2Array = ArenaLayout.boundary(0)
	var shadow: PackedVector2Array = []
	var uv: PackedVector2Array = []
	for point: Vector2 in edge:
		shadow.append(point + Vector2(0, 11))
		uv.append(point / 32)
	draw_colored_polygon(shadow, Color("050c13", 0.85))
	draw_polygon(edge, PackedColorArray([Color("7a8c96")]), uv, FLOOR)
	var closed: PackedVector2Array = edge.duplicate()
	closed.append(edge[0])
	draw_polyline(closed, Color("0b1322"), 14)
	draw_polyline(closed, Color("6c716c"), 8)
	draw_polyline(closed, Color("b28a56"), 2)
	for index: int in range(edge.size()):
		var a: Vector2 = edge[index]
		var b: Vector2 = edge[(index + 1) % edge.size()]
		for bolt: int in range(1, 5):
			var at: Vector2 = a.lerp(b, bolt / 5.0)
			draw_circle(at, 2, Color("172b37"))
			draw_line(at - Vector2(1, 0), at + Vector2(1, 0), Color("a4a8a1"))
	for y: int in [63, 77]:
		draw_line(Vector2(138, y + 2), Vector2(502, y + 2), Color("101c25"), 6)
		draw_line(Vector2(138, y), Vector2(502, y), Color("8299a8"), 2)
	for x: int in range(145, 501, 15): draw_line(Vector2(x, 58), Vector2(x, 82), Color("6c5945"), 3)
	draw_arc(Vector2(320, 240), 66, 0.2, TAU - 0.2, 64, Color("ffce75", 0.18), 3)
	draw_arc(Vector2(320, 240), 57, 0, TAU, 64, Color("47dacb", 0.12), 1)
	draw_string(ThemeDB.fallback_font, Vector2(247, 294), "ESTACIÓN DE COBRO 07", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b6c5c5", 0.26))
	for side: int in [-1, 1]:
		for band: int in range(5):
			var at: Vector2 = Vector2(320 + side * (110 + band * 5), 395)
			draw_line(at, at + Vector2(side * 4, 12), Color("ffce75", 0.3), 2)
	draw_prop(0, Vector2(8, 4), Vector2(98, 70))
	draw_prop(1, Vector2(230, -18), Vector2(180, 52))
	draw_prop(2, Vector2(-24, 370), Vector2(125, 85))
	draw_prop(3, Vector2(543, 400), Vector2(86, 68))
	# Cabrestante suspendido fuera del área de combate, con carga y cable en movimiento.
	var hoist: Vector2 = Vector2(320 + sin(elapsed * 0.33) * 24, 25 + sin(elapsed * 0.7) * 3)
	draw_line(Vector2(320, 5), hoist, Color("263b47"), 2)
	draw_texture_rect(DepotArt.part(2), Rect2(hoist - Vector2(5, 0), Vector2(10, 22)), false)
	draw_set_transform(Vector2(60, 418), elapsed * 1.7)
	draw_texture_rect(DepotArt.part(5), Rect2(-10, -10, 20, 20), false)
	draw_set_transform(Vector2.ZERO)
	AmbientSteam.draw_plume(self, Vector2(18, 390), elapsed, 14)
	AmbientSteam.draw_plume(self, Vector2(78, 18), elapsed + 2, 10)
	for point: Vector2 in [Vector2(108, 91), Vector2(566, 98), Vector2(110, 393), Vector2(526, 398)]:
		var brightness: float = 0.7 if GamePreferences.current().reduced_flashes else 0.65 + sin(elapsed * 1.5 + point.x) * 0.18
		draw_circle(point, 4, Color("ffce75", 0.08))
		draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), Color("ffce75", brightness))
