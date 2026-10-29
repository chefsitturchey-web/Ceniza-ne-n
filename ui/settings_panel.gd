class_name SettingsPanel
extends CanvasLayer

signal closed
var opened: bool = false
var closed_frame: int = -1
var was_paused: bool = false
var status: Label
var sliders: Dictionary = {}
var toggles: Dictionary = {}
var window_size: OptionButton
var first: HSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.94)
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
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
	for pair: Array in [["muted", "Silenciar todo  [M]"], ["fullscreen", "Pantalla completa"], ["reduced_flashes", "Reducir destellos y sacudidas"], ["particles", "Partículas ambientales y de combate"]]:
		var toggle: CheckButton = CheckButton.new()
		toggle.text = pair[1]
		toggle.custom_minimum_size.y = 20
		rows.add_child(toggle)
		toggles[pair[0]] = toggle
		toggle.toggled.connect(func(value: bool) -> void: _set_option(pair[0], value))
	window_size = OptionButton.new()
	for caption: String in ["Ventana: 1280 × 720", "Ventana: 1600 × 900", "Ventana: 1920 × 1080"]:
		window_size.add_item(caption)
	window_size.item_selected.connect(func(index: int) -> void: _set_option("window_size", index))
	rows.add_child(window_size)
	status = Label.new()
	status.text = "Los ajustes se guardan automáticamente."
	rows.add_child(status)
	var back: Button = Button.new()
	back.text = "Volver  [Esc / Start]"
	back.pressed.connect(close_panel)
	rows.add_child(back)
	GamePreferences.current().changed.connect(refresh)
	hide()

func refresh() -> void:
	for key: String in sliders:
		sliders[key].slider.set_value_no_signal(float(GamePreferences.current().values[key]) * 100.0)
		sliders[key].number.text = "%d%%" % int(float(GamePreferences.current().values[key]) * 100)
	for key: String in toggles:
		toggles[key].set_pressed_no_signal(GamePreferences.current().values[key])
	window_size.select(GamePreferences.current().values.window_size)
	window_size.disabled = GamePreferences.current().values.fullscreen

func _set_option(key: String, value: Variant) -> void:
	status.text = "Ajustes guardados" if GamePreferences.current().update_value(key, value) else "No se pudo guardar; el ajuste sigue activo en esta sesión."

func open_panel() -> void:
	if opened:
		return
	was_paused = get_tree().paused
	get_tree().paused = true
	opened = true
	refresh()
	show()
	first.grab_focus()

func close_panel() -> void:
	if not opened:
		return
	opened = false
	closed_frame = Engine.get_process_frames()
	GamePreferences.current().block_gameplay_input()
	get_tree().paused = was_paused
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if opened and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
