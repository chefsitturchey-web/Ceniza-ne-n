extends SceneTree
## Controles táctiles, pantalla ancha y latencia de audio en Android.

var checks: int = 0
var failures: int = 0
const SETTINGS: String = "user://opciones_tactil_test.cfg"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func pressed(action: String) -> bool:
	Input.flush_buffered_events()
	return Input.is_action_pressed(action)

func center_of(overlay: TouchOverlay, action: String) -> Vector2:
	for button: Dictionary in overlay.buttons:
		if button.action == action:
			return (button.rect as Rect2).get_center() if button.has("rect") else button.center
	return Vector2(-100, -100)

func actions_of(overlay: TouchOverlay) -> Array[String]:
	var result: Array[String] = []
	for button: Dictionary in overlay.buttons:
		result.append(String(button.action))
	return result

func buttons_fit(overlay: TouchOverlay) -> bool:
	var area: Rect2 = Rect2(Vector2.ZERO, overlay.screen)
	for index: int in range(overlay.buttons.size()):
		var a: Dictionary = overlay.buttons[index]
		if a.has("rect"):
			if not area.encloses(a.rect): return false
			continue
		if not area.has_point(a.center - Vector2.ONE * a.radius) or not area.has_point(a.center + Vector2.ONE * a.radius): return false
		for other: int in range(index + 1, overlay.buttons.size()):
			var b: Dictionary = overlay.buttons[other]
			if not b.has("rect") and a.center.distance_to(b.center) < a.radius + b.radius + 4: return false
		if a.center.distance_to(overlay.stick_rest) < a.radius + TouchOverlay.STICK_RADIUS: return false
	return true

func run_checks() -> void:
	# Pantalla: canvas_items + keep_height llena un 20:9 sin franjas y conserva el 16:9 de escritorio.
	verify(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "Stretch canvas_items")
	verify(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep_height", "Aspecto keep_height: el ancho crece en móviles anchos")
	verify(ProjectSettings.get_setting("display/window/size/viewport_width") == 640 and ProjectSettings.get_setting("display/window/size/viewport_height") == 360, "Base lógica 640x360")
	verify(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == true, "Los toques llegan a los botones de los menús como ratón")
	verify(ProjectSettings.has_setting("audio/driver/output_latency.android") and int(ProjectSettings.get_setting("audio/driver/output_latency.android")) <= 15, "Latencia de audio reducida en Android")
	var presets: ConfigFile = ConfigFile.new()
	if presets.load("res://export_presets.cfg") == OK:
		var android: String = ""
		for section: String in presets.get_sections():
			if section.ends_with(".options") or not presets.has_section_key(section, "platform"): continue
			if presets.get_value(section, "platform") == "Android": android = section + ".options"
		verify(not android.is_empty() and presets.get_value(android, "screen/edge_to_edge", false) == true, "Android dibuja bajo el notch (edge to edge)")
	verify(ScreenFit.layer_shift(640) == 0 and ScreenFit.layer_shift(800) == 80 and ScreenFit.layer_shift(600) == 0, "Las capas de 640 px se centran en pantallas anchas")
	verify(ScreenFit.safe_margins().left == 0.0 and ScreenFit.safe_margins().right == 0.0, "Sin márgenes de notch en escritorio")
	var fitted: CanvasLayer = CanvasLayer.new()
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(640, 360)
	fitted.add_child(shade)
	root.add_child(fitted)
	ScreenFit.fit_layer(fitted, [shade])
	var width: float = ScreenFit.visible_size(fitted).x
	verify(fitted.offset.x == ScreenFit.layer_shift(width) and shade.size.x == maxf(640, width) and shade.position.x == -fitted.offset.x, "El fondo de una capa centrada cubre todo el ancho")
	fitted.free()
	# Audio de interfaz: precargado y suena al apretar, no al soltar.
	UiSound.warm_up()
	verify(UiSound.streams.size() >= 4, "Los sonidos de interfaz se cargan al arrancar")
	var probe: Button = Button.new()
	UiSound.attach(probe)
	verify(probe.button_down.get_connections().size() == 1 and probe.pressed.get_connections().is_empty(), "El clic suena al apretar")
	probe.free()

	var prefs: GamePreferences = GamePreferences.current() as GamePreferences
	var previous_path: String = prefs.config_path
	var previous_values: Dictionary = prefs.values.duplicate()
	prefs.config_path = SETTINGS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	prefs.load_settings()
	verify(prefs.values.touch_controls == true, "Controles táctiles activados por defecto")
	InputSetup.configure_input()
	InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)
	var overlay: TouchOverlay = TouchOverlay.current()
	verify(overlay != null, "Autoload TouchControls presente")
	if overlay == null:
		quit(1)
		return
	await process_frame
	verify(not overlay.visible and overlay.detect_mode() == TouchOverlay.MODE_NONE and not TouchOverlay.showing(), "Oculto en escritorio sin pantalla táctil")
	overlay.force_touch = true
	await process_frame
	verify(overlay.detect_mode() == TouchOverlay.MODE_NONE and not overlay.visible, "Sin partida (menús) no tapa nada")

	# Zona: movimiento horizontal y botones de la colonia.
	overlay.mode_override = TouchOverlay.MODE_ZONE
	await process_frame
	verify(overlay.visible and overlay.mode == TouchOverlay.MODE_ZONE and TouchOverlay.showing(), "Visible en una zona con pantalla táctil")
	var zone_actions: Array[String] = actions_of(overlay)
	var all_exist: bool = true
	for action: String in ["dodge", "interact", "overload", "escort", "toggle_power", "mount", "sprint", "pause", "journal"]:
		all_exist = all_exist and action in zone_actions and InputMap.has_action(action)
	verify(all_exist and not "attack" in zone_actions, "Zona: Esquivar, Operar, Sobrecargar, Asaltar, Torreta, Plataforma, Correr, Pausa y Diario; sin Atacar")
	verify(buttons_fit(overlay), "Zona: botones dentro de pantalla y sin solaparse")
	verify(overlay.stick_rest.y + TouchOverlay.STICK_RADIUS < 337, "El joystick no tapa los recursos del HUD")
	verify(overlay.handle_touch(0, center_of(overlay, "interact"), true) and pressed("interact"), "Tocar Operar pulsa E")
	for frame: int in 3: await process_frame
	verify(pressed("interact"), "Operar se mantiene mientras el dedo sigue apoyado")
	overlay.handle_touch(1, center_of(overlay, "sprint"), true)
	verify(pressed("sprint") and pressed("interact"), "Multitáctil: correr y operar a la vez")
	overlay.handle_touch(0, center_of(overlay, "interact"), false)
	overlay.handle_touch(1, center_of(overlay, "sprint"), false)
	verify(not pressed("interact") and not pressed("sprint"), "Levantar el dedo suelta las acciones")
	overlay.handle_touch(2, center_of(overlay, "dodge"), true)
	Input.flush_buffered_events()
	verify(Input.is_action_just_pressed("dodge"), "Esquivar llega como pulsación nueva")
	overlay.handle_touch(2, Vector2.ZERO, false)
	var start: Vector2 = overlay.stick_rest
	verify(overlay.handle_touch(3, start, true), "El pulgar izquierdo toma el joystick")
	overlay.handle_drag(3, start + Vector2(30, -30))
	verify(pressed("move_right") and not pressed("move_left"), "Joystick a la derecha mueve a la derecha")
	verify(not InputMap.has_action("arena_up") or not pressed("arena_up"), "En zona el joystick no mueve en vertical")
	overlay.handle_drag(3, start + Vector2(-35, 0))
	verify(pressed("move_left") and not pressed("move_right"), "Joystick a la izquierda")
	overlay.handle_touch(3, start, false)
	verify(not pressed("move_left") and not pressed("move_right"), "Soltar el joystick detiene al Portador")
	verify(not overlay.handle_touch(4, Vector2(320, 20), true), "Un toque fuera de los controles no se consume")
	overlay.handle_touch(4, Vector2(320, 20), false)
	overlay.handle_touch(5, center_of(overlay, "pause"), true)
	verify(pressed("pause"), "Pausa desde la esquina superior")
	overlay.handle_touch(5, center_of(overlay, "pause"), false)
	overlay.handle_touch(6, center_of(overlay, "journal"), true)
	verify(pressed("journal"), "Diario desde la esquina superior")
	# Pausar oculta los controles y suelta lo que estuviera pulsado.
	paused = true
	await process_frame
	verify(not overlay.visible and not pressed("journal") and overlay.held.is_empty(), "En pausa se oculta y no deja teclas pegadas")
	paused = false

	# Arena: joystick 2D (W/S) y Atacar.
	for entry: Array in [["arena_up", KEY_W], ["arena_down", KEY_S]]:
		if not InputMap.has_action(entry[0]): InputSetup.add_action(entry[0], entry[1], JOY_BUTTON_DPAD_UP)
	overlay.mode_override = TouchOverlay.MODE_ARENA
	await process_frame
	var arena_actions: Array[String] = actions_of(overlay)
	verify(overlay.visible and "attack" in arena_actions and "dodge" in arena_actions and "pause" in arena_actions and not "journal" in arena_actions and not "mount" in arena_actions, "Arena: Atacar, Esquivar y Pausa; sin Diario ni Plataforma")
	verify(buttons_fit(overlay), "Arena: botones dentro de pantalla y sin solaparse")
	overlay.handle_touch(0, center_of(overlay, "attack"), true)
	verify(pressed("attack"), "Atacar pulsa J")
	overlay.handle_touch(0, Vector2.ZERO, false)
	start = overlay.stick_rest
	overlay.handle_touch(1, start, true)
	overlay.handle_drag(1, start + Vector2(28, -28))
	verify(pressed("arena_up") and pressed("move_right") and not pressed("arena_down"), "Arena: el joystick mueve también en vertical")
	var vector: Vector2 = Input.get_vector("move_left", "move_right", "arena_up", "arena_down")
	verify(vector.x > 0.3 and vector.y < -0.3, "Arena: dirección diagonal analógica")
	overlay.handle_touch(1, start, false)
	verify(not pressed("arena_up") and not pressed("move_right"), "Arena: soltar detiene")

	# Opción: desactivarlos los oculta aunque haya pantalla táctil.
	verify(prefs.update_value("touch_controls", false), "Guarda la opción de controles táctiles")
	await process_frame
	verify(not overlay.visible and not overlay.enabled(), "La opción los oculta")
	prefs.load_settings()
	verify(prefs.values.touch_controls == false, "La opción sobrevive una recarga")
	var panel: SettingsPanel = SettingsPanel.new()
	root.add_child(panel)
	verify(panel.toggles.has("touch_controls"), "Opciones incluye Controles táctiles")
	panel.free()
	prefs.update_value("touch_controls", true)

	# Menús: un toque real (ratón emulado) pulsa un botón de Control.
	var layer: CanvasLayer = CanvasLayer.new()
	var menu_button: Button = Button.new()
	menu_button.position = Vector2(100, 100)
	menu_button.size = Vector2(80, 30)
	layer.add_child(menu_button)
	root.add_child(layer)
	var taps: Array[int] = []
	menu_button.pressed.connect(func() -> void: taps.append(1))
	await process_frame
	var at: Vector2 = root.get_final_transform() * Vector2(140, 115)
	for down: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = 0
		touch.position = at
		touch.pressed = down
		Input.parse_input_event(touch)
		Input.flush_buffered_events()
		await process_frame
	verify(taps.size() == 1, "Un toque pulsa los botones de los menús")
	layer.free()

	# HUD a todo el ancho visible.
	var hud: GameHud = (load("res://ui/hud.tscn") as PackedScene).instantiate() as GameHud
	root.add_child(hud)
	var visible_width: float = ScreenFit.visible_size(hud).x
	verify(hud.screen_width == visible_width and hud.icons.sobrecarga.position.x == visible_width - 24 and hud.get_node("DamageEdges").size == Vector2(visible_width, 360), "El HUD se reparte por el ancho visible")
	hud.free()

	overlay.mode_override = ""
	overlay.force_touch = false
	overlay.release_all()
	await process_frame
	verify(not overlay.visible, "Vuelve a ocultarse en escritorio")
	prefs.config_path = previous_path
	prefs.values = previous_values
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	print("Controles táctiles y pantalla: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
