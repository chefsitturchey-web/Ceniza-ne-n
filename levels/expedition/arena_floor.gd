extends Node2D

## Suelo de la arena del Recaudador: baldosas, bordes y detalles de ambiente dibujados una sola vez.
## Los detalles usan una semilla fija para que la arena se vea igual en cada visita.

const FLOOR: Texture2D = preload("res://assets/expedition/arena/floor.png")
const EDGE: Texture2D = preload("res://assets/expedition/arena/edge.png")
const SIZE: Vector2 = Vector2(640, 480)
const SEED: int = 1907

const SHADOW: Color = Color("0b1322")
const DARK: Color = Color("182639")
const METAL: Color = Color("304356")
const LIGHT_METAL: Color = Color("8299a8")
const AMBER: Color = Color("ffce75")
const RUST: Color = Color("e89e54")
const ENEMY: Color = Color("dd6482")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var light_time: float = 0.0
var theme_id: String = "periphery"
var dust: CPUParticles2D

func _ready() -> void:
	_add_dust()

func _process(delta: float) -> void:
	if theme_id == "foundry" and int(light_time * 8) != int((light_time + delta) * 8): queue_redraw()
	if dust != null:
		dust.emitting = GamePreferences.current().particles
	# Luces industriales con parpadeos ocasionales y alarma que respira.
	light_time += delta
	var index: int = 0
	for light: Node in get_tree().get_nodes_in_group(&"arena_light"):
		var phase: float = fmod(light_time * 0.8 + index * 1.7, 7.0)
		(light as PointLight2D).energy = 0.45 if phase < 0.18 and int(phase * 40.0) % 2 == 0 and not GamePreferences.current().reduced_flashes else 1.1
		index += 1
	for alarm: Node in get_tree().get_nodes_in_group(&"arena_alarm"):
		(alarm as PointLight2D).energy = 0.25 + 0.15 * sin(light_time * 2.0)

func _draw() -> void:
	rng.seed = SEED
	_draw_tiles()
	_draw_rails()
	_draw_toll_circle()
	_draw_decals()
	_draw_cables()
	_draw_debris()
	_draw_edges()
	_draw_wall_pipes()
	if theme_id == "foundry":
		for x: int in [130, 325, 520]:
			for y: int in range(80, 430, 18):
				draw_rect(Rect2(x - 25, y, 50, 10), Color("0b1322", 0.7))
				for rib: int in range(8):
					draw_line(Vector2(x - 22 + rib * 6, y + 1), Vector2(x - 22 + rib * 6, y + 8), Color("704c43"), 2)
	elif theme_id == "flooded":
		draw_rect(Rect2(15, 55, 610, 410), Color("103b4a", 0.26))
		for y: int in range(90, 450, 45):
			draw_line(Vector2(30, y), Vector2(610, y + 2), Color("47dacb", 0.08), 1)
	for x: int in [48, 592]:
		for y: int in [80, 400]:
			draw_rect(Rect2(x - 5, y - 2, 10, 4), AMBER)
	if theme_id == "foundry": _draw_foundry_basin()

func _draw_foundry_basin() -> void:
	var boundary: PackedVector2Array = PackedVector2Array([Vector2(140, 24), Vector2(500, 24), Vector2(616, 140), Vector2(616, 340), Vector2(500, 456), Vector2(140, 456), Vector2(24, 340), Vector2(24, 140), Vector2(140, 24)])
	for corner: Vector2 in [Vector2.ZERO, Vector2(640, 0), Vector2(640, 480), Vector2(0, 480)]:
		var inward: Vector2 = Vector2(1 if corner.x == 0 else -1, 1 if corner.y == 0 else -1)
		draw_colored_polygon(PackedVector2Array([corner, corner + Vector2(inward.x * 164, 0), corner + Vector2(0, inward.y * 164)]), Color("140f15"))
		for line: int in range(7):
			var at: Vector2 = corner + inward * (12 + line * 10)
			draw_line(at, at + Vector2(inward.x * (120 - line * 15), 0), Color(0.8, 0.27 + 0.04 * sin(light_time + line), 0.09, 0.5), 3)
	draw_polyline(boundary, Color("0b1322"), 13)
	draw_polyline(boundary, Color("704c43"), 8)
	draw_polyline(boundary, Color("8299a8"), 1)
	for side: int in [-1, 1]:
		for y: int in [195, 285]:
			var center: Vector2 = Vector2(320 + side * 269, y)
			draw_circle(center, 15, Color("0b1322"))
			draw_arc(center, 13, 0, TAU, 20, Color("704c43"), 3)
			for tooth: int in range(8):
				var arm: Vector2 = Vector2.from_angle(light_time * side * 0.4 + tooth * TAU / 8) * 11
				draw_line(center, center + arm, Color("8299a8"), 2)
			if GamePreferences.current().particles:
				for puff: int in range(4):
					var rise: float = fposmod(light_time * 14 + puff * 8, 35)
					draw_rect(Rect2(center + Vector2(-3 + sin(rise) * 2, -rise), Vector2(5, 4)), Color(0.6, 0.7, 0.75, (1.0 - rise / 35) * 0.25))
	for index: int in range(8):
		var point: Vector2 = boundary[index]
		draw_circle(point, 7, Color("182639"))
		draw_circle(point, 2, Color("ffce75"))

func _draw_tiles() -> void:
	for x: int in range(20):
		for y: int in range(15):
			# Variación leve por baldosa: placas más gastadas o más limpias.
			var shade: float = rng.randf_range(0.82, 1.0)
			var tint: Color = Color("b8947a") if theme_id == "foundry" else (Color("628c96") if theme_id == "flooded" else Color("929aa4"))
			draw_texture(FLOOR, Vector2(x * 32, y * 32), tint * Color(shade, shade, shade))

func _draw_rails() -> void:
	# Vías del tren blindado que cruzan la parte alta de la plataforma.
	var top: float = 30.0
	for x: int in range(16, 628, 14):
		draw_rect(Rect2(x, top - 3, 8, 22), Color(DARK, 0.9))
	for y: float in [top, top + 14.0]:
		draw_rect(Rect2(12, y, 616, 3), METAL)
		draw_line(Vector2(12, y), Vector2(628, y), LIGHT_METAL)

func _draw_toll_circle() -> void:
	# Círculo de cobro pintado donde espera el jefe.
	var center: Vector2 = Vector2(320, 230)
	draw_arc(center, 92.0, 0.0, TAU, 64, Color(AMBER, 0.22), 4.0)
	draw_arc(center, 78.0, 0.0, TAU, 64, Color(AMBER, 0.12), 2.0)
	for index: int in range(12):
		var angle: float = TAU * index / 12.0
		var from: Vector2 = center + Vector2.from_angle(angle) * 82.0
		draw_line(from, from + Vector2.from_angle(angle) * 8.0, Color(AMBER, 0.25), 2.0)

func _draw_decals() -> void:
	# Rejillas de drenaje.
	for spot: Vector2 in [Vector2(96, 120), Vector2(544, 360), Vector2(260, 420), Vector2(420, 96)]:
		draw_rect(Rect2(spot, Vector2(20, 12)), SHADOW)
		for i: int in range(5):
			draw_line(spot + Vector2(2 + i * 4, 1), spot + Vector2(2 + i * 4, 11), METAL)
	# Manchas de aceite y óxido.
	for i: int in range(14):
		var pos: Vector2 = Vector2(rng.randf_range(40, 600), rng.randf_range(70, 450))
		var radius: float = rng.randf_range(4, 11)
		var color: Color = Color(SHADOW, 0.45) if rng.randf() < 0.6 else Color(RUST, 0.16)
		draw_circle(pos, radius, color)
		draw_circle(pos + Vector2(radius * 0.6, radius * 0.3), radius * 0.55, color)
	# Charcos que reflejan las luces.
	for spot: Vector2 in [Vector2(140, 380), Vector2(500, 150)]:
		draw_circle(spot, 14, Color("101a2b"))
		draw_circle(spot + Vector2(10, 4), 9, Color("101a2b"))
		draw_arc(spot, 14, -2.6, -1.2, 8, Color(LIGHT_METAL, 0.5), 1.0)
	# Grietas.
	for i: int in range(9):
		var point: Vector2 = Vector2(rng.randf_range(40, 600), rng.randf_range(70, 450))
		for step: int in range(rng.randi_range(3, 6)):
			var next: Vector2 = point + Vector2(rng.randf_range(-7, 7), rng.randf_range(-7, 7))
			draw_line(point.round(), next.round(), Color(SHADOW, 0.8), 1.0)
			point = next

func _draw_cables() -> void:
	# Cables gruesos que salen de las paredes hacia el centro.
	var cables: Array = [[Vector2(12, 150), Vector2(120, 210), Vector2(150, 280)],
		[Vector2(628, 300), Vector2(530, 270), Vector2(470, 220)],
		[Vector2(200, 468), Vector2(230, 420), Vector2(300, 400)]]
	for cable: Array in cables:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in range(17):
			var t: float = i / 16.0
			var a: Vector2 = (cable[0] as Vector2).lerp(cable[1], t)
			var b: Vector2 = (cable[1] as Vector2).lerp(cable[2], t)
			points.append(a.lerp(b, t).round())
		draw_polyline(points, SHADOW, 4.0)
		draw_polyline(points, DARK, 2.0)
		var tip: Vector2 = cable[2]
		draw_rect(Rect2(tip - Vector2(3, 3), Vector2(6, 6)), METAL)
		draw_rect(Rect2(tip - Vector2(1, 1), Vector2(2, 2)), ENEMY if (cable[0] as Vector2).x > 320 else AMBER)

func _draw_debris() -> void:
	# Chatarra suelta y tornillos.
	var colors: Array[Color] = [METAL, LIGHT_METAL, RUST, DARK]
	for i: int in range(40):
		var pos: Vector2 = Vector2(rng.randf_range(24, 616), rng.randf_range(60, 456)).round()
		var size: Vector2 = Vector2(rng.randi_range(1, 4), rng.randi_range(1, 3))
		draw_rect(Rect2(pos, size), colors[rng.randi_range(0, 3)])

func _draw_edges() -> void:
	for x: int in range(20):
		draw_texture(EDGE, Vector2(x * 32, 0))
		draw_texture(EDGE, Vector2(x * 32, 468))
	draw_set_transform(Vector2(12, 0), PI / 2)
	for y: int in range(15):
		draw_texture(EDGE, Vector2(y * 32, 0))
	draw_set_transform(Vector2(640, 0), PI / 2)
	for y: int in range(15):
		draw_texture(EDGE, Vector2(y * 32, 0))
	draw_set_transform(Vector2.ZERO)

func _draw_wall_pipes() -> void:
	# Tuberías verticales pegadas a las paredes laterales, con abrazaderas.
	for x: float in [14.0, 620.0]:
		draw_rect(Rect2(x, 60, 6, 380), SHADOW)
		draw_rect(Rect2(x + 1, 60, 4, 380), METAL)
		draw_line(Vector2(x + 2, 60), Vector2(x + 2, 440), LIGHT_METAL)
		for y: int in range(80, 440, 48):
			draw_rect(Rect2(x - 1, y, 8, 3), DARK)

func _add_dust() -> void:
	# Polvo y ceniza flotando con la luz.
	dust = CPUParticles2D.new()
	dust.emitting = GamePreferences.current().particles
	dust.amount = 40
	dust.lifetime = 6.0
	dust.preprocess = 6.0
	dust.position = SIZE / 2.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = SIZE / 2.0
	dust.direction = Vector2(1, -0.3)
	dust.spread = 30.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 9.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.0
	dust.color = Color(0.86, 0.8, 0.7, 0.35)
	dust.z_index = 5
	add_child(dust)
