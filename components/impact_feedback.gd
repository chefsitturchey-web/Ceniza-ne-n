class_name ImpactFeedback
extends Node2D
## Efectos locales al viewport. Solo el hit-stop usa tiempo global y lo restaura.
const FONT: Font = preload("res://assets/fonts/Micro5-Regular.ttf")
static var hit_stops: int = 0
var camera: Camera2D
var rings: Array[Dictionary] = []
var sparks: DebrisEmitter = DebrisEmitter.new()
var numbers: Array[Dictionary] = []
var flights: Array[Dictionary] = []
var shake: float = 0
var clock: float = 0
var stop_active: bool = false
var previous_scale: float = 1
var active: bool = true
var hud_target: Vector2 = Vector2(24, 344)
var camera_rest: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_child(sparks)
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(camera): camera_rest = camera.offset

func number(at: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if not active: return
	if numbers.size() >= 32: numbers.pop_front()
	numbers.append({"at": at + Vector2(-10, -35), "text": text, "color": color, "age": 0.0})

func hit(at: Vector2, amount: int, killed: bool = false) -> void:
	if not active: return
	number(at, str(amount), Color("ffce75") if killed else Color.WHITE)
	kick(2.5 if killed else 0.8)
	sparks.emit_pixels(at + Vector2(0, -18), 6 if killed else 3, Color("ffce75"))
	if killed:
		burst(at + Vector2(0, -18), Color("ffce75"), 26)
		sparks.emit_pixels(at + Vector2(0, -18), 4, Color("89939e", 0.6), true)
		hit_stop()

func burst(at: Vector2, color: Color, radius: float = 30) -> void:
	if not active or not GamePreferences.current().particles: return
	if rings.size() >= 12: rings.pop_front()
	rings.append({"at": at, "color": color, "radius": radius, "age": 0.0})

func kick(strength: float) -> void:
	if active and not GamePreferences.current().reduced_flashes: shake = maxf(shake, strength)

func collect(at: Vector2, amount: int, parts: bool = false) -> void:
	if amount <= 0 or not active: return
	number(at, "+%d %s" % [amount, "piezas" if parts else "chatarra"], Color("47dacb"))
	if not GamePreferences.current().particles: return
	for index: int in mini(amount, 6):
		if flights.size() >= 36: flights.pop_front()
		flights.append({"at": at + Vector2(index * 3 - 8, -20), "age": -index * 0.035})

func hit_stop() -> void:
	if not active or stop_active or GamePreferences.current().reduced_flashes: return
	previous_scale = Engine.time_scale
	stop_active = true
	hit_stops += 1
	Engine.time_scale = 0.001
	get_tree().create_timer(0.055, true, false, true).timeout.connect(restore_time)

func restore_time() -> void:
	if not stop_active: return
	if is_equal_approx(Engine.time_scale, 0.001): Engine.time_scale = previous_scale
	stop_active = false
	hit_stops = maxi(0, hit_stops - 1)

func _exit_tree() -> void:
	restore_time()
	if is_instance_valid(camera): camera.offset = camera_rest

func _process(delta: float) -> void:
	if get_tree().paused: return
	clock += delta
	for ring: Dictionary in rings: ring.age += delta
	rings = rings.filter(func(ring: Dictionary) -> bool: return ring.age < 0.5)
	shake = move_toward(shake, 0, delta * 22)
	if GamePreferences.current().reduced_flashes: shake = 0
	if is_instance_valid(camera): camera.offset = camera_rest + Vector2(sin(clock * 107), cos(clock * 89)) * shake
	for entry: Dictionary in numbers: entry.age += delta
	numbers = numbers.filter(func(entry: Dictionary) -> bool: return entry.age < 0.75)
	for entry: Dictionary in flights: entry.age += delta
	flights = flights.filter(func(entry: Dictionary) -> bool: return entry.age < 0.65)
	queue_redraw()

func _draw() -> void:
	for ring: Dictionary in rings:
		var t: float = float(ring.age) / 0.5
		var tint: Color = ring.color
		tint.a = (1 - t) * (0.2 if GamePreferences.current().reduced_flashes else 0.65)
		draw_arc(to_local(ring.at), lerpf(3, ring.radius, t), 0, TAU, 32, tint, 1)
	for entry: Dictionary in numbers:
		var tint: Color = entry.color
		tint.a = 1.0 - float(entry.age) / 0.75
		var at: Vector2 = entry.at + Vector2(0, -float(entry.age) * 28)
		draw_string_outline(FONT, at, entry.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 3, Color(0.02, 0.04, 0.07, tint.a))
		draw_string(FONT, at, entry.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, tint)
	var destination: Vector2 = get_global_transform_with_canvas().affine_inverse() * hud_target
	for entry: Dictionary in flights:
		var progress: float = clampf(float(entry.age) / 0.65, 0, 1)
		var at: Vector2 = (entry.at as Vector2).lerp(destination, progress * progress)
		at.y -= sin(progress * PI) * 45
		draw_rect(Rect2(at, Vector2(3, 3)), Color("ffce75"))
