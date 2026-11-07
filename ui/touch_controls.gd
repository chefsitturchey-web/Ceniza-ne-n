class_name TouchOverlay
extends CanvasLayer
## Controles táctiles en pantalla (autoload "TouchControls").
## Solo aparecen con pantalla táctil (o en móvil), durante el juego y sin pausa; Opciones permite ocultarlos.
## Inyectan InputEventAction con Input.parse_input_event: la lógica que consulta Input.is_action_*
## y la que recibe eventos en _input/_unhandled_input funcionan igual que con teclado o mando.
## Los menús no los necesitan: los toques ya llegan a los botones como ratón emulado.

const MODE_NONE: String = "none"
const MODE_ZONE: String = "zone"
const MODE_ARENA: String = "arena"
## Botones redondos: [acción, texto, distancia al borde derecho e inferior, radio, color de borde].
const ZONE_BUTTONS: Array[Array] = [
	["interact", "Operar", Vector2(44, 54), 24.0, "ffce75"],
	["dodge", "Esquivar", Vector2(100, 34), 20.0, "47dacb"],
	["sprint", "Correr", Vector2(44, 110), 19.0, "47dacb"],
	["escort", "Asaltar", Vector2(98, 90), 17.0, "8299a8"],
	["overload", "Sobrec.", Vector2(150, 44), 17.0, "8299a8"],
	["toggle_power", "Torreta", Vector2(146, 102), 17.0, "8299a8"],
	["mount", "Plataf.", Vector2(44, 160), 17.0, "8299a8"]]
const ARENA_BUTTONS: Array[Array] = [
	["attack", "Atacar", Vector2(44, 54), 24.0, "ffce75"],
	["dodge", "Esquivar", Vector2(100, 34), 20.0, "47dacb"],
	["sprint", "Correr", Vector2(44, 110), 19.0, "47dacb"],
	["interact", "Operar", Vector2(98, 90), 17.0, "8299a8"],
	["overload", "Sobrec.", Vector2(146, 102), 17.0, "8299a8"]]
const STICK_RADIUS: float = 40.0
const KNOB_RADIUS: float = 15.0
const STICK_DEADZONE: float = 0.25
## Margen extra para acertar con el pulgar.
const TOUCH_SLOP: float = 6.0

## Las pruebas lo activan para simular un dispositivo táctil en escritorio.
var force_touch: bool = false
## Las pruebas fijan el modo sin montar una zona completa; vacío = detección normal.
var mode_override: String = ""
var mode: String = MODE_NONE
## Botones del modo actual: {action, label, center, radius, color} o {action, label, rect}.
var buttons: Array[Dictionary] = []
## Índice de dedo -> acción que mantiene pulsada.
var touches: Dictionary = {}
## Acciones inyectadas ahora mismo -> intensidad.
var held: Dictionary = {}
var stick_touch: int = -1
var stick_rest: Vector2 = Vector2(64, 288)
var stick_origin: Vector2 = Vector2(64, 288)
var stick_vector: Vector2 = Vector2.ZERO
var screen: Vector2 = Vector2(640, 360)
var surface: Control

static func current() -> TouchOverlay:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TouchControls") as TouchOverlay

## True cuando el panel táctil está en pantalla durante el juego.
static func showing() -> bool:
	var overlay: TouchOverlay = current()
	return overlay != null and overlay.visible and overlay.mode != MODE_NONE

static func touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Por encima del HUD y de la arena; los paneles modales pausan el árbol y lo ocultan.
	layer = 50
	surface = Control.new()
	surface.name = "Surface"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	surface.draw.connect(_draw_surface)
	add_child(surface)
	visible = false
	UiSound.warm_up()

## Preferencia activa y dispositivo táctil (o simulado en pruebas).
func enabled() -> bool:
	var prefs: Node = get_node_or_null("/root/Preferences")
	var wanted: bool = true
	if prefs != null:
		wanted = bool((prefs as GamePreferences).values.get("touch_controls", true))
	return wanted and (force_touch or touch_device())

func detect_mode() -> String:
	if not enabled() or not is_inside_tree() or get_tree().paused:
		return MODE_NONE
	if not mode_override.is_empty():
		return mode_override
	for node: Node in get_tree().get_nodes_in_group(&"boss_arena"):
		if not node.is_inside_tree() or not (node as CanvasLayer).visible:
			continue
		if bool(node.get("completed")) or bool(node.get("ending")):
			return MODE_NONE
		return MODE_ARENA
	var district: District = get_tree().current_scene as District
	if district == null or district.session == null or district.session.finished:
		return MODE_NONE
	if district.expedition != null and district.expedition.active:
		return MODE_NONE
	return MODE_ZONE

func _process(_delta: float) -> void:
	var wanted: String = detect_mode()
	var size_now: Vector2 = ScreenFit.visible_size(self)
	if wanted != mode or size_now != screen:
		set_mode(wanted)
	visible = mode != MODE_NONE

func set_mode(value: String) -> void:
	release_all()
	mode = value
	layout()
	visible = mode != MODE_NONE

## Coloca joystick y botones según el ancho visible y el área segura (notch).
func layout() -> void:
	screen = ScreenFit.visible_size(self)
	var safe: Dictionary = ScreenFit.safe_margins(self)
	var right_edge: float = screen.x - float(safe.right)
	var bottom_edge: float = screen.y - float(safe.bottom)
	surface.position = Vector2.ZERO
	surface.size = screen
	stick_rest = Vector2(float(safe.left) + 64.0, bottom_edge - 72.0)
	stick_origin = stick_rest
	buttons.clear()
	if mode == MODE_NONE:
		surface.queue_redraw()
		return
	for spec: Array in (ARENA_BUTTONS if mode == MODE_ARENA else ZONE_BUTTONS):
		var offset: Vector2 = spec[2]
		buttons.append({"action": spec[0], "label": spec[1], "center": Vector2(right_edge - offset.x, bottom_edge - offset.y),
			"radius": spec[3], "color": Color(spec[4])})
	# Esquina superior derecha: pausa siempre; diario solo en las zonas (las arenas no lo usan).
	var top: float = float(safe.top) + 6.0
	buttons.append({"action": "pause", "label": "Pausa", "rect": Rect2(right_edge - 52, top, 46, 20), "color": Color("8299a8")})
	if mode == MODE_ZONE:
		buttons.append({"action": "journal", "label": "Diario", "rect": Rect2(right_edge - 104, top, 46, 20), "color": Color("8299a8")})
	surface.queue_redraw()

func _input(event: InputEvent) -> void:
	if mode == MODE_NONE:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if handle_touch(touch.index, touch.position, touch.pressed):
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if handle_drag(drag.index, drag.position):
			get_viewport().set_input_as_handled()

## Devuelve true si el toque pertenece a los controles (no debe llegar al resto).
func handle_touch(index: int, at: Vector2, pressed: bool) -> bool:
	if not pressed:
		var consumed: bool = false
		if touches.has(index):
			set_action(String(touches[index]), 0.0)
			touches.erase(index)
			consumed = true
		if index == stick_touch:
			stick_touch = -1
			stick_vector = Vector2.ZERO
			stick_origin = stick_rest
			apply_stick()
			consumed = true
		surface.queue_redraw()
		return consumed
	if mode == MODE_NONE:
		return false
	var button: Dictionary = button_at(at)
	if not button.is_empty():
		touches[index] = button.action
		set_action(String(button.action), 1.0)
		surface.queue_redraw()
		return true
	if stick_touch < 0 and in_stick_zone(at):
		stick_touch = index
		# Joystick flotante: nace donde apoya el pulgar, sin salirse de la pantalla.
		stick_origin = Vector2(clampf(at.x, STICK_RADIUS + 4, screen.x * 0.45), clampf(at.y, 80.0, screen.y - STICK_RADIUS - 4))
		update_stick(at)
		return true
	return false

func handle_drag(index: int, at: Vector2) -> bool:
	if index == stick_touch:
		update_stick(at)
		return true
	return touches.has(index)

func in_stick_zone(at: Vector2) -> bool:
	return at.x < screen.x * 0.45 and at.y > 70.0

func button_at(at: Vector2) -> Dictionary:
	for button: Dictionary in buttons:
		if button.has("rect"):
			if (button.rect as Rect2).grow(4).has_point(at):
				return button
		elif at.distance_to(button.center) <= float(button.radius) + TOUCH_SLOP:
			return button
	return {}

func update_stick(at: Vector2) -> void:
	stick_vector = ((at - stick_origin) / STICK_RADIUS).limit_length(1.0)
	apply_stick()
	surface.queue_redraw()

## Zona: solo izquierda/derecha. Arena: también arriba/abajo (W/S), con intensidad analógica.
func apply_stick() -> void:
	var x: float = stick_vector.x
	var y: float = stick_vector.y if mode == MODE_ARENA else 0.0
	var digital: bool = mode != MODE_ARENA
	set_action("move_left", axis_strength(-x, digital))
	set_action("move_right", axis_strength(x, digital))
	if InputMap.has_action("arena_up"):
		set_action("arena_up", axis_strength(-y, false))
	if InputMap.has_action("arena_down"):
		set_action("arena_down", axis_strength(y, false))

func axis_strength(value: float, digital: bool) -> float:
	if value < STICK_DEADZONE:
		return 0.0
	return 1.0 if digital else clampf(value, 0.0, 1.0)

## Pulsa o suelta una acción como lo haría una tecla; solo emite eventos cuando algo cambia.
func set_action(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	var previous: float = float(held.get(action, 0.0))
	if strength > 0.0:
		if previous > 0.0 and absf(previous - strength) < 0.05:
			return
		held[action] = strength
	else:
		if previous <= 0.0:
			return
		held.erase(action)
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)

func release_all() -> void:
	for action: String in held.keys():
		set_action(action, 0.0)
	touches.clear()
	stick_touch = -1
	stick_vector = Vector2.ZERO
	stick_origin = stick_rest
	if surface != null:
		surface.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()

func pressed_action(action: String) -> bool:
	return touches.values().has(action)

func _draw_surface() -> void:
	if mode == MODE_NONE:
		return
	var font: Font = ThemeDB.fallback_font
	var fill: Color = Color("0b1322", 0.42)
	# Joystick: aro base, guía y pomo.
	surface.draw_circle(stick_origin, STICK_RADIUS, fill)
	surface.draw_arc(stick_origin, STICK_RADIUS, 0, TAU, 40, Color("47dacb", 0.45), 1.5)
	if mode == MODE_ZONE:
		for side: float in [-1.0, 1.0]:
			var tip: Vector2 = stick_origin + Vector2(side * (STICK_RADIUS - 8), 0)
			surface.draw_line(tip, tip + Vector2(-side * 6, -5), Color("47dacb", 0.5), 1.5)
			surface.draw_line(tip, tip + Vector2(-side * 6, 5), Color("47dacb", 0.5), 1.5)
	var knob: Vector2 = stick_origin + stick_vector * (STICK_RADIUS - KNOB_RADIUS * 0.5)
	surface.draw_circle(knob, KNOB_RADIUS, Color("47dacb", 0.38 if stick_touch >= 0 else 0.22))
	surface.draw_arc(knob, KNOB_RADIUS, 0, TAU, 24, Color("dcf6ee", 0.5), 1.0)
	for button: Dictionary in buttons:
		var active: bool = pressed_action(String(button.action))
		var tint: Color = button.color
		var text: String = String(button.label)
		var size: int = 9
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if button.has("rect"):
			var rect: Rect2 = button.rect
			surface.draw_rect(rect, Color(tint, 0.35) if active else fill)
			surface.draw_rect(rect, Color(tint, 0.6), false, 1.0)
			surface.draw_string(font, Vector2(rect.get_center().x - width / 2.0, rect.get_center().y + 3.0), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("dcf6ee", 0.9))
			continue
		var center: Vector2 = button.center
		var radius: float = button.radius
		surface.draw_circle(center, radius, Color(tint, 0.35) if active else fill)
		surface.draw_arc(center, radius, 0, TAU, 32, Color(tint, 0.65 if active else 0.5), 1.5)
		surface.draw_string(font, Vector2(center.x - width / 2.0, center.y + 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
			Color("dcf6ee", 0.95 if active else 0.8))
