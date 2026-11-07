class_name KeyRemap
extends RefCounted
## Reasignación de la tecla y el botón principales de cada acción jugable.
## Las asignaciones personalizadas viven en GamePreferences.bindings y se guardan en opciones.cfg.

const ACTIONS: Array[Array] = [
	["move_left", "Mover a la izquierda"], ["move_right", "Mover a la derecha"], ["sprint", "Correr"],
	["interact", "Construir / operar"], ["escort", "Asaltar / retirar"], ["dodge", "Esquivar"],
	["overload", "Sobrecargar"], ["toggle_power", "Alimentar torreta"], ["mount", "Plataforma"],
	["journal", "Diario"], ["attack", "Atacar"], ["pause", "Pausar"], ["restart", "Reiniciar"]]
const DEFAULTS: Dictionary = {
	"move_left": {"key": KEY_A, "pad": JOY_BUTTON_DPAD_LEFT}, "move_right": {"key": KEY_D, "pad": JOY_BUTTON_DPAD_RIGHT},
	"sprint": {"key": KEY_SHIFT, "pad": JOY_BUTTON_DPAD_DOWN}, "interact": {"key": KEY_E, "pad": JOY_BUTTON_Y},
	"escort": {"key": KEY_F, "pad": JOY_BUTTON_DPAD_UP}, "dodge": {"key": KEY_SPACE, "pad": JOY_BUTTON_A},
	"overload": {"key": KEY_Q, "pad": JOY_BUTTON_LEFT_SHOULDER}, "toggle_power": {"key": KEY_T, "pad": JOY_BUTTON_B},
	"mount": {"key": KEY_V, "pad": JOY_BUTTON_LEFT_STICK}, "journal": {"key": KEY_L, "pad": JOY_BUTTON_RIGHT_SHOULDER},
	"attack": {"key": KEY_J, "pad": JOY_BUTTON_X}, "pause": {"key": KEY_ESCAPE, "pad": JOY_BUTTON_START},
	"restart": {"key": KEY_R, "pad": JOY_BUTTON_BACK}}
## Teclas con uso fijo: flechas y W/S de las arenas, silencio global y herramientas de depuración.
const RESERVED_KEYS: Array[int] = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_W, KEY_S, KEY_M, KEY_F1, KEY_F2, KEY_F3, KEY_F4]
const KEY_NAMES: Dictionary = {KEY_SPACE: "Espacio", KEY_SHIFT: "Shift", KEY_ESCAPE: "Esc", KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt", KEY_TAB: "Tab", KEY_ENTER: "Intro", KEY_BACKSPACE: "Retroceso", KEY_CAPSLOCK: "Bloq Mayús"}
## Nombres al estilo PlayStation (los mandos que se usan en el evento). Los símbolos salen
## de la fuente de respaldo PadSymbols y TextMarks los pinta con su color (InputGlyphs.pad_color).
const PAD_NAMES: Dictionary = {JOY_BUTTON_A: "✕", JOY_BUTTON_B: "○", JOY_BUTTON_X: "□", JOY_BUTTON_Y: "△",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_BACK: "Share",
	JOY_BUTTON_START: "Options", JOY_BUTTON_GUIDE: "PS", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_DPAD_UP: "Cruceta arriba",
	JOY_BUTTON_DPAD_DOWN: "Cruceta abajo", JOY_BUTTON_DPAD_LEFT: "Cruceta izq.", JOY_BUTTON_DPAD_RIGHT: "Cruceta der.",
	JOY_BUTTON_TOUCHPAD: "Panel táctil", JOY_BUTTON_MISC1: "Micrófono"}

static func preferences() -> GamePreferences:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or not tree.root.has_node("Preferences"):
		return null
	return tree.root.get_node("Preferences") as GamePreferences

static func label(action: String) -> String:
	for entry: Array in ACTIONS:
		if entry[0] == action:
			return entry[1]
	return action

static func binding(action: String) -> Dictionary:
	var result: Dictionary = DEFAULTS.get(action, {}).duplicate()
	var prefs: GamePreferences = preferences()
	if prefs != null and prefs.bindings.has(action):
		result.merge(prefs.bindings[action], true)
	return result

static func valid_binding(action: Variant, value: Variant) -> bool:
	if not (action is String) or not DEFAULTS.has(action) or not (value is Dictionary):
		return false
	for kind: String in value:
		if kind not in ["key", "pad"] or not value[kind] is int:
			return false
		if kind == "pad" and (value[kind] < 0 or value[kind] >= JOY_BUTTON_SDL_MAX):
			return false
		if kind == "key" and (value[kind] <= 0 or value[kind] in RESERVED_KEYS):
			return false
	return true

static func key_name(code: int) -> String:
	if KEY_NAMES.has(code):
		return KEY_NAMES[code]
	var text: String = OS.get_keycode_string(code as Key)
	return text if not text.is_empty() else "Tecla %d" % code

static func pad_name(code: int) -> String:
	return PAD_NAMES.get(code, "Botón %d" % code)

## Sustituye la primera tecla y el primer botón de la acción; las flechas y el stick siguen intactos.
static func apply_action(action: String) -> void:
	if not InputMap.has_action(action) or not DEFAULTS.has(action):
		return
	var wanted: Dictionary = binding(action)
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	var key_done: bool = false
	var pad_done: bool = false
	InputMap.action_erase_events(action)
	for event: InputEvent in events:
		if event is InputEventKey and not key_done:
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = wanted.key
			event = key
			key_done = true
		elif event is InputEventJoypadButton and not pad_done:
			var pad: InputEventJoypadButton = InputEventJoypadButton.new()
			pad.button_index = wanted.pad
			event = pad
			pad_done = true
		InputMap.action_add_event(action, event)

static func apply_saved() -> void:
	for action: String in DEFAULTS:
		apply_action(action)

## Asigna un código ("key" o "pad"). Si otra acción ya lo usa, intercambia ambas asignaciones.
## Devuelve {"ok", "swapped", "message"} para que el menú informe al jugador.
static func assign(action: String, kind: String, code: int) -> Dictionary:
	var prefs: GamePreferences = preferences()
	if prefs == null or not DEFAULTS.has(action) or kind not in ["key", "pad"]:
		return {"ok": false, "swapped": "", "message": "Acción desconocida."}
	if not valid_binding(action, {kind: code}):
		return {"ok": false, "swapped": "", "message": "%s está reservada; elige otra." % key_name(code)}
	var previous: int = binding(action)[kind]
	var swapped: String = ""
	for other: String in DEFAULTS:
		if other != action and binding(other)[kind] == code:
			swapped = other
			_store(prefs, other, kind, previous)
	_store(prefs, action, kind, code)
	var saved: bool = prefs.save_settings()
	apply_action(action)
	if not swapped.is_empty():
		apply_action(swapped)
	prefs.changed.emit()
	var shown: String = key_name(code) if kind == "key" else pad_name(code)
	var message: String = "%s → %s" % [label(action), shown]
	if not swapped.is_empty():
		var old: String = key_name(previous) if kind == "key" else pad_name(previous)
		message = "%s ya se usaba en «%s»; intercambiadas (%s ahora usa %s)." % [shown, label(swapped), label(swapped), old]
	if not saved:
		message += " No se pudo guardar."
	return {"ok": true, "swapped": swapped, "message": message}

static func reset_defaults() -> bool:
	var prefs: GamePreferences = preferences()
	if prefs == null:
		return false
	prefs.bindings.clear()
	var saved: bool = prefs.save_settings()
	apply_saved()
	prefs.changed.emit()
	return saved

static func _store(prefs: GamePreferences, action: String, kind: String, code: int) -> void:
	var entry: Dictionary = prefs.bindings.get(action, {}).duplicate()
	if DEFAULTS[action][kind] == code:
		entry.erase(kind)
	else:
		entry[kind] = code
	if entry.is_empty():
		prefs.bindings.erase(action)
	else:
		prefs.bindings[action] = entry
