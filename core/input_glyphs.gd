class_name InputGlyphs
extends RefCounted
## Nombre de la tecla o el botón de cada acción según el último dispositivo usado.
## Teclado y ratón muestran teclas; botones o sticks del mando muestran el mando.
## Opciones puede fijar Teclado o Mando (preferencia "glyphs"). Respeta lo remapeado en KeyRemap.

const MODES: Array[String] = ["Automático", "Teclado", "Mando"]
## Un stick apenas desviado no cambia los avisos: evita parpadeos por deriva.
const AXIS_DEADZONE: float = 0.5
static var last_pad: bool = false

## Registra el dispositivo del evento; devuelve true si cambió.
static func observe(event: InputEvent) -> bool:
	var pad: bool
	if event is InputEventJoypadButton:
		if not event.pressed: return false
		pad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < AXIS_DEADZONE: return false
		pad = true
	elif event is InputEventKey:
		if not event.pressed: return false
		pad = false
	elif event is InputEventMouseButton:
		# Los toques emulan ratón: no deben quitar los avisos del mando.
		if not event.pressed or event.device == InputEvent.DEVICE_ID_EMULATION: return false
		pad = false
	elif event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION or event.relative.is_zero_approx(): return false
		pad = false
	else:
		return false
	if pad == last_pad: return false
	last_pad = pad
	return true

static func mode() -> int:
	var prefs: GamePreferences = KeyRemap.preferences()
	return int(prefs.values.get("glyphs", 0)) if prefs != null else 0

static func using_pad() -> bool:
	match mode():
		1: return false
		2: return true
	return last_pad

## Tecla o botón de la acción para el dispositivo activo; con controles táctiles, su botón.
static func action_name(action: String) -> String:
	if action == "mute": return KeyRemap.key_name(KEY_M)
	if TouchOverlay.showing():
		if action in ["move", "move_left", "move_right"]: return "Stick"
		if action == "journal": return "Diario"
		if action == "pause": return "Pausa"
		var overlay: TouchOverlay = TouchOverlay.current()
		for entry: Array in (TouchOverlay.ARENA_BUTTONS if overlay.mode == TouchOverlay.MODE_ARENA else TouchOverlay.ZONE_BUTTONS):
			if entry[0] == action: return entry[1]
	if action == "move":
		if using_pad(): return "Stick"
		return "%s %s" % [action_name("move_left"), action_name("move_right")]
	var binding: Dictionary = KeyRemap.binding(action)
	if binding.is_empty(): return action
	return KeyRemap.pad_name(int(binding.pad)) if using_pad() else KeyRemap.key_name(int(binding.key))

## Color propio de cada símbolo de PlayStation; transparente si el texto no lo contiene.
static func pad_color(text: String) -> Color:
	if "✕" in text: return Color("7fa7ff")
	if "○" in text: return Color("ff6b6b")
	if "□" in text: return Color("f59ad8")
	if "△" in text: return Color("5fe0a8")
	return Color.TRANSPARENT

## Sustituye {accion} por su tecla o botón: "Mantén {interact}" -> "Mantén E" o "Mantén Y".
static func fill(text: String) -> String:
	if not "{" in text: return text
	for action: String in KeyRemap.DEFAULTS:
		var token: String = "{%s}" % action
		if token in text: text = text.replace(token, action_name(action))
	text = text.replace("{mute}", action_name("mute"))
	if "{move}" in text: text = text.replace("{move}", action_name("move"))
	return text

## Mantiene un texto con {accion} al día mientras el control sigue en escena:
## cambia al alternar teclado y mando, al remapear o al fijar el modo en Opciones.
static func bind(control: Control, template: String) -> void:
	var update: Callable = func() -> void: control.set("text", fill(template))
	update.call()
	var prefs: GamePreferences = KeyRemap.preferences()
	if prefs == null: return
	var attach: Callable = func() -> void:
		if not prefs.device_changed.is_connected(update): prefs.device_changed.connect(update)
		if not prefs.changed.is_connected(update): prefs.changed.connect(update)
		update.call()
	var detach: Callable = func() -> void:
		if prefs.device_changed.is_connected(update): prefs.device_changed.disconnect(update)
		if prefs.changed.is_connected(update): prefs.changed.disconnect(update)
	control.tree_entered.connect(attach)
	control.tree_exiting.connect(detach)
	if control.is_inside_tree(): attach.call()
