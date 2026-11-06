class_name SettingsPanel
extends CanvasLayer

signal closed
signal guide_reset_requested
var opened: bool = false
var closed_frame: int = -1
var was_paused: bool = false
var status: Label
var sliders: Dictionary = {}
var toggles: Dictionary = {}
var window_size: OptionButton
var first: HSlider
var general: VBoxContainer
var controls: VBoxContainer
var controls_button: Button
var controls_status: Label
var binding_rows: Dictionary = {}
var listening: String = ""
var listen_frame: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	var shade: MenuBackdrop = MenuBackdrop.new()
	shade.size = Vector2(640, 360)
	add_child(shade)
	MenuFx.polish_layer(self)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	panel.position = Vector2(100, 18)
	panel.size = Vector2(440, 324)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 5)
	margin.add_child(rows)
	general = rows
	var title: Label = Label.new()
	title.text = "OPCIONES"
	title.theme_type_variation = &"Title"
	title.add_theme_color_override("font_color", Color("47dacb"))
	rows.add_child(title)
	for pair: Array in [["master", "Volumen general"], ["music", "Música"], ["sfx", "Efectos"]]:
		var row: HBoxContainer = HBoxContainer.new()
		rows.add_child(row)
		var caption: Label = Label.new()
		caption.text = pair[1]
		caption.custom_minimum_size.x = 110
		row.add_child(caption)
		var slider: HSlider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 18
		row.add_child(slider)
		var number: Label = Label.new()
		number.custom_minimum_size.x = 34
		row.add_child(number)
		sliders[pair[0]] = {"slider": slider, "number": number}
		slider.value_changed.connect(func(value: float) -> void:
			number.text = "%d%%" % int(value)
			_set_option(pair[0], value / 100.0))
	first = sliders.master.slider
	for pair: Array in [["muted", "Silenciar todo  [M]"], ["fullscreen", "Pantalla completa"], ["reduced_flashes", "Reducir destellos y sacudidas"], ["particles", "Partículas ambientales y de combate"], ["touch_controls", "Controles táctiles en pantalla"]]:
		var toggle: CheckButton = CheckButton.new()
		toggle.text = pair[1]
		toggle.custom_minimum_size.y = 20
		rows.add_child(toggle)
		toggles[pair[0]] = toggle
		toggle.toggled.connect(func(value: bool) -> void: _set_option(pair[0], value))
		UiSound.attach(toggle)
	window_size = OptionButton.new()
	for caption: String in ["Ventana: 1280 × 720", "Ventana: 1600 × 900", "Ventana: 1920 × 1080"]:
		window_size.add_item(caption)
	window_size.item_selected.connect(func(index: int) -> void: _set_option("window_size", index))
	rows.add_child(window_size)
	# En móvil la ventana la gestiona el sistema; en escritorio sin pantalla táctil sobra el panel táctil.
	if OS.has_feature("mobile"):
		toggles.fullscreen.hide()
		window_size.hide()
	elif not TouchOverlay.touch_device():
		toggles.touch_controls.hide()
	status = Label.new()
	status.text = "Los ajustes se guardan automáticamente."
	rows.add_child(status)
	var buttons: HBoxContainer = HBoxContainer.new()
	rows.add_child(buttons)
	controls_button = Button.new()
	controls_button.text = "Controles"
	controls_button.pressed.connect(show_controls)
	UiSound.attach(controls_button)
	buttons.add_child(controls_button)
	var reset_guide: Button = Button.new()
	reset_guide.text = "Reiniciar guía"
	reset_guide.pressed.connect(func() -> void:
		var profile: Dictionary = SaveSystem.engagement_profile()
		profile.guide = 0
		SaveSystem.store_engagement(profile)
		guide_reset_requested.emit()
		status.text = "Guía lista")
	buttons.add_child(reset_guide)
	var back: Button = Button.new()
	back.text = "Volver  [Esc / Start]"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close_panel)
	UiSound.attach(back)
	buttons.add_child(back)
	_build_controls(margin)
	GamePreferences.current().changed.connect(refresh)
	hide()
	ScreenFit.fit_layer(self, [shade])

func refresh() -> void:
	for key: String in sliders:
		sliders[key].slider.set_value_no_signal(float(GamePreferences.current().values[key]) * 100.0)
		sliders[key].number.text = "%d%%" % int(float(GamePreferences.current().values[key]) * 100)
	for key: String in toggles:
		toggles[key].set_pressed_no_signal(GamePreferences.current().values[key])
	window_size.select(GamePreferences.current().values.window_size)
	window_size.disabled = GamePreferences.current().values.fullscreen
	for action: String in binding_rows:
		var current: Dictionary = KeyRemap.binding(action)
		binding_rows[action].key.text = KeyRemap.key_name(current.key)
		binding_rows[action].pad.text = KeyRemap.pad_name(current.pad)
		binding_rows[action].change.text = "..." if listening == action else "Cambiar"

func _build_controls(margin: MarginContainer) -> void:
	controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	controls.hide()
	margin.add_child(controls)
	var title: Label = Label.new()
	title.text = "CONTROLES"
	title.theme_type_variation = &"Title"
	title.add_theme_color_override("font_color", Color("47dacb"))
	controls.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid)
	for caption: String in ["Acción", "Teclado", "Mando Xbox", ""]:
		var header: Label = Label.new()
		header.text = caption
		header.add_theme_color_override("font_color", Color("47dacb"))
		grid.add_child(header)
	for entry: Array in KeyRemap.ACTIONS:
		var action: String = entry[0]
		var name_label: Label = Label.new()
		name_label.text = entry[1]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		var key_label: Label = Label.new()
		key_label.custom_minimum_size.x = 70
		grid.add_child(key_label)
		var pad_label: Label = Label.new()
		pad_label.custom_minimum_size.x = 96
		grid.add_child(pad_label)
		var change: Button = Button.new()
		change.text = "Cambiar"
		change.custom_minimum_size.x = 64
		change.pressed.connect(func() -> void: start_listening(action))
		UiSound.attach(change)
		grid.add_child(change)
		binding_rows[action] = {"key": key_label, "pad": pad_label, "change": change}
	controls_status = Label.new()
	controls_status.text = "Pulsa «Cambiar» y luego una tecla o un botón del mando."
	controls_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(controls_status)
	var buttons: HBoxContainer = HBoxContainer.new()
	controls.add_child(buttons)
	var reset: Button = Button.new()
	reset.text = "Restablecer predeterminados"
	reset.pressed.connect(reset_bindings)
	UiSound.attach(reset)
	buttons.add_child(reset)
	var back: Button = Button.new()
	back.text = "Volver"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(show_general)
	UiSound.attach(back)
	buttons.add_child(back)

func show_controls() -> void:
	listening = ""
	general.hide()
	controls.show()
	refresh()
	binding_rows[KeyRemap.ACTIONS[0][0]].change.grab_focus()

func show_general() -> void:
	listening = ""
	controls.hide()
	general.show()
	refresh()
	controls_button.grab_focus()

func start_listening(action: String) -> void:
	listening = action
	listen_frame = Engine.get_process_frames()
	controls_status.text = "%s: pulsa una tecla o un botón del mando (Esc cancela)." % KeyRemap.label(action)
	refresh()

func reset_bindings() -> void:
	listening = ""
	controls_status.text = "Controles predeterminados restablecidos." if KeyRemap.reset_defaults() else "No se pudo guardar; los predeterminados siguen activos en esta sesión."
	refresh()

## Asigna la siguiente tecla o botón recibido a la acción en espera.
func capture_event(event: InputEvent) -> bool:
	if listening.is_empty() or not event.is_pressed() or event.is_echo():
		return false
	var action: String = listening
	if event is InputEventKey:
		var code: int = (event as InputEventKey).physical_keycode
		if code == KEY_NONE:
			code = (event as InputEventKey).keycode
		listening = ""
		if code == KEY_ESCAPE:
			controls_status.text = "Cambio cancelado."
		else:
			controls_status.text = KeyRemap.assign(action, "key", code).message
	elif event is InputEventJoypadButton:
		listening = ""
		controls_status.text = KeyRemap.assign(action, "pad", (event as InputEventJoypadButton).button_index).message
	else:
		return false
	refresh()
	return true

func _set_option(key: String, value: Variant) -> void:
	status.text = "Ajustes guardados" if GamePreferences.current().update_value(key, value) else "No se pudo guardar; el ajuste sigue activo en esta sesión."

func open_panel() -> void:
	if opened:
		return
	was_paused = get_tree().paused
	get_tree().paused = true
	opened = true
	listening = ""
	controls.hide()
	general.show()
	refresh()
	show()
	first.grab_focus()

func close_panel() -> void:
	if not opened:
		return
	opened = false
	listening = ""
	closed_frame = Engine.get_process_frames()
	GamePreferences.current().block_gameplay_input()
	get_tree().paused = was_paused
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if opened and not listening.is_empty():
		# Mientras espera una tecla, nada llega a la navegación ni al juego.
		if Engine.get_process_frames() > listen_frame:
			capture_event(event)
		if not (event is InputEventMouse):
			get_viewport().set_input_as_handled()
		return
	if opened and controls.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
		show_general()
		get_viewport().set_input_as_handled()
		return
	if opened and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
