extends SceneTree

var checks: int = 0
var failures: int = 0
const SETTINGS: String = "user://opciones_remap_test.cfg"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func first_key(action: String) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return KEY_NONE

func first_pad(action: String) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return (event as InputEventJoypadButton).button_index
	return -1

func key_event(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func pad_event(button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event

func run_checks() -> void:
	var prefs: GamePreferences = GamePreferences.current() as GamePreferences
	var previous_path: String = prefs.config_path
	var previous_values: Dictionary = prefs.values.duplicate()
	var previous_bindings: Dictionary = prefs.bindings.duplicate(true)
	prefs.config_path = SETTINGS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	prefs.load_settings()
	InputSetup.configure_input()
	InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)
	verify(prefs.bindings.is_empty(), "Sin archivo no hay asignaciones personalizadas")
	var matches: bool = true
	for action: String in KeyRemap.DEFAULTS:
		matches = matches and first_key(action) == KeyRemap.DEFAULTS[action].key and first_pad(action) == KeyRemap.DEFAULTS[action].pad
	verify(matches, "Los predeterminados de KeyRemap coinciden con InputSetup")
	verify(KeyRemap.key_name(KEY_SPACE) == "Espacio" and KeyRemap.pad_name(JOY_BUTTON_LEFT_SHOULDER) == "LB", "Nombres de teclas y botones en español / Xbox")
	var result: Dictionary = KeyRemap.assign("dodge", "key", KEY_K)
	verify(result.ok and first_key("dodge") == KEY_K and first_pad("dodge") == JOY_BUTTON_A, "Cambia solo la tecla de esquivar")
	result = KeyRemap.assign("dodge", "pad", JOY_BUTTON_RIGHT_STICK)
	verify(result.ok and first_pad("dodge") == JOY_BUTTON_RIGHT_STICK and first_key("dodge") == KEY_K, "Cambia solo el botón de esquivar")
	result = KeyRemap.assign("attack", "key", KEY_E)
	verify(result.swapped == "interact" and first_key("attack") == KEY_E and first_key("interact") == KEY_J, "Un conflicto intercambia las teclas")
	verify("intercambiadas" in String(result.message), "El conflicto se comunica al jugador")
	result = KeyRemap.assign("overload", "pad", JOY_BUTTON_A)
	verify(result.ok and result.swapped.is_empty(), "El botón A quedó libre tras mover esquivar")
	result = KeyRemap.assign("move_left", "key", KEY_Z)
	var arrow_kept: bool = false
	for event: InputEvent in InputMap.action_get_events("move_left"):
		arrow_kept = arrow_kept or (event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_LEFT)
	verify(first_key("move_left") == KEY_Z and arrow_kept, "Mover conserva las flechas como alternativa")
	result = KeyRemap.assign("dodge", "key", KEY_M)
	verify(not result.ok and first_key("dodge") == KEY_K, "Rechaza teclas reservadas")
	verify(not KeyRemap.valid_binding("volar", {"key": KEY_K}) and not KeyRemap.valid_binding("dodge", {"pad": 999}), "Valida acción y rango de botón")
	var saved: Dictionary = prefs.bindings.duplicate(true)
	prefs.bindings = {}
	prefs.load_settings()
	verify(prefs.bindings == saved, "Las asignaciones sobreviven una recarga")
	verify(prefs.values == GamePreferences.DEFAULTS, "Los controles no alteran las demás opciones")
	InputSetup.configure_input()
	verify(first_key("dodge") == KEY_K and first_key("interact") == KEY_J and first_pad("dodge") == JOY_BUTTON_RIGHT_STICK, "Se aplican al iniciar, después de InputSetup")
	InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)
	KeyRemap.assign("journal", "key", KEY_N)
	InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)
	verify(first_key("journal") == KEY_N, "Las acciones añadidas tarde también usan su tecla guardada")
	var malformed: ConfigFile = ConfigFile.new()
	malformed.set_value("controls", "dodge", {"key": "corrupto"})
	malformed.set_value("controls", "volar", {"key": KEY_K})
	malformed.set_value("controls", "attack", {"key": KEY_P})
	malformed.save(SETTINGS)
	prefs.load_settings()
	verify(prefs.bindings == {"attack": {"key": KEY_P}}, "Asignaciones inválidas se descartan; conserva las válidas")
	verify(KeyRemap.reset_defaults() and prefs.bindings.is_empty(), "Restablecer borra las asignaciones")
	InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)
	verify(first_key("attack") == KEY_J and first_key("dodge") == KEY_SPACE and first_pad("dodge") == JOY_BUTTON_A and first_key("journal") == KEY_L, "Restablecer devuelve el mapa original")
	var panel: SettingsPanel = SettingsPanel.new()
	root.add_child(panel)
	panel.open_panel()
	panel.show_controls()
	verify(panel.controls.visible and not panel.general.visible, "Opciones muestra la sección Controles")
	verify(panel.binding_rows.size() == KeyRemap.ACTIONS.size() and panel.binding_rows.dodge.key.text == "Espacio" and panel.binding_rows.dodge.pad.text == "A", "Cada acción lista su tecla y su botón")
	panel.start_listening("sprint")
	verify(panel.binding_rows.sprint.change.text == "...", "Cambiar espera la siguiente entrada")
	verify(panel.capture_event(key_event(KEY_G)) and first_key("sprint") == KEY_G and panel.binding_rows.sprint.key.text == "G", "Una tecla se asigna desde el menú")
	panel.start_listening("sprint")
	verify(panel.capture_event(pad_event(JOY_BUTTON_Y)) and first_pad("sprint") == JOY_BUTTON_Y and first_pad("interact") == JOY_BUTTON_DPAD_DOWN, "Un botón en conflicto se intercambia desde el menú")
	verify("intercambiadas" in panel.controls_status.text, "El menú avisa del intercambio")
	panel.start_listening("sprint")
	verify(panel.capture_event(key_event(KEY_ESCAPE)) and first_key("sprint") == KEY_G and panel.listening.is_empty(), "Esc cancela el cambio")
	verify(not panel.capture_event(key_event(KEY_H)), "Sin espera activa no se asigna nada")
	panel.reset_bindings()
	verify(first_key("sprint") == KEY_SHIFT and panel.binding_rows.sprint.key.text == "Shift", "Restablecer desde el menú")
	panel.show_general()
	verify(panel.general.visible and not panel.controls.visible, "Volver regresa a las opciones generales")
	panel.close_panel()
	panel.free()
	prefs.config_path = previous_path
	prefs.values = previous_values
	prefs.bindings = previous_bindings
	KeyRemap.apply_saved()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	await process_frame
	print("Reasignación de controles: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
