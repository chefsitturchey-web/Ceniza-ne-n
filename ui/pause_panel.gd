class_name PausePanel
extends PanelContainer

signal options_requested
signal menu_requested
signal resume_requested

const ICON_NAMES: Array[String] = ["dia", "aviso", "noche", "chatarra", "energia", "habitantes", "vida", "resistencia", "nucleo", "amenaza", "sobrecarga"]
var icons: Dictionary = {}
var values: Dictionary = {}
var bars: Dictionary = {}
var rows: VBoxContainer
var phase: String = "DÍA"
var resume_button: Button
var controls: GridContainer
const CONTROL_LIST: Array[Array] = [["move_left", "Mover"], ["attack", "Atacar"], ["dodge", "Esquivar"],
	["interact", "Mantén: usar"], ["sprint", "Correr"], ["overload", "Sobrecarga"]]

func _ready() -> void:
	add_theme_stylebox_override("panel", MenuSkin.panel())
	# Velo detras del panel: oscurece la partida y aparece junto con el.
	var dim: MenuBackdrop = MenuBackdrop.new()
	dim.visible = false
	dim.size = Vector2(640, 360)
	get_parent().add_child.call_deferred(dim)
	get_parent().move_child.call_deferred(dim, get_index())
	visibility_changed.connect(func() -> void:
		dim.visible = visible
		if visible:
			dim.size = Vector2(maxf(640.0, get_viewport_rect().size.x), 360)
			MenuFx.enter(dim, 0.0))
	MenuFx.polish_control(self, 24.0)
	custom_minimum_size.x = 544
	_fit.call_deferred()
	rows = VBoxContainer.new()
	rows.add_theme_font_size_override("font_size", 10)
	rows.add_theme_constant_override("separation", 6)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("Margin").add_child(rows)
	var heading: Label = Label.new()
	heading.text = "PAUSA"
	heading.theme_type_variation = &"Title"
	heading.add_theme_color_override("font_color", Color("ffce75"))
	rows.add_child(heading)
	var first: HBoxContainer = _row()
	for key: String in ["dia", "aviso", "noche"]:
		_icon(first, key)
		icons[key].visible = key == "dia"
	_label(first, "phase")
	for key: String in ["chatarra", "energia", "habitantes"]:
		_item(first, key)
	var second: HBoxContainer = _row()
	var colors: Array[Color] = [Color("dd6482"), Color("47dacb"), Color("ffce75")]
	var keys: Array[String] = ["vida", "resistencia", "nucleo"]
	for index: int in range(keys.size()):
		var group: HBoxContainer = HBoxContainer.new()
		second.add_child(group)
		_icon(group, keys[index])
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(62, 6)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = GameRules.CORE_HEALTH if index == 2 else 100
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = colors[index]
		var background: StyleBoxFlat = StyleBoxFlat.new()
		background.bg_color = Color("304356")
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", background)
		group.add_child(bar)
		bars[keys[index]] = bar
		_label(group, keys[index])
	var third: HBoxContainer = _row()
	_item(third, "amenaza")
	_item(third, "sobrecarga")
	controls = GridContainer.new()
	controls.columns = 3
	controls.add_theme_constant_override("h_separation", 18)
	controls.add_theme_constant_override("v_separation", 4)
	rows.add_child(controls)
	visibility_changed.connect(func() -> void: if visible: _fill_controls())
	_fill_controls()
	var actions: HBoxContainer = _row()
	resume_button = Button.new()
	resume_button.theme_type_variation = &"MenuEntry"
	resume_button.text = "Continuar"
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	UiSound.attach(resume_button)
	actions.add_child(resume_button)
	for pair: Array in [["Opciones", func() -> void: options_requested.emit()], ["Menú principal", func() -> void: menu_requested.emit()]]:
		var button: Button = Button.new()
		button.theme_type_variation = &"MenuEntry"
		button.text = pair[0]
		button.pressed.connect(pair[1])
		UiSound.attach(button)
		actions.add_child(button)


## Solo las acciones básicas, con la tecla real (respeta lo remapeado) o el botón del mando.
func _fill_controls() -> void:
	for child: Node in controls.get_children():
		controls.remove_child(child)
		child.queue_free()
	controls.visible = not TouchOverlay.showing()
	var pad: bool = not Input.get_connected_joypads().is_empty()
	for pair: Array in CONTROL_LIST:
		var binding: Dictionary = KeyRemap.binding(pair[0])
		var key: String = KeyRemap.pad_name(int(binding.pad)) if pad else KeyRemap.key_name(int(binding.key))
		if pair[0] == "move_left":
			key = "Stick" if pad else "%s %s" % [key, KeyRemap.key_name(int(KeyRemap.binding("move_right").key))]
		var entry: HBoxContainer = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)
		entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip: Label = Label.new()
		chip.text = key
		chip.add_theme_font_size_override("font_size", 10)
		chip.add_theme_color_override("font_color", Color("ffce75"))
		chip.add_theme_stylebox_override("normal", _key_chip())
		entry.add_child(chip)
		var name_label: Label = Label.new()
		name_label.text = pair[1]
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color("9fb4c4"))
		entry.add_child(name_label)
		controls.add_child(entry)
	_fit.call_deferred()

func _key_chip() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("0b1322")
	box.border_color = Color("ffce75", 0.55)
	box.set_border_width_all(1)
	box.border_width_bottom = 2
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	return box

## El panel ocupa lo que necesita su contenido y se centra en vertical.
func _fit() -> void:
	reset_size()
	position.y = roundf((360.0 - size.y) / 2.0)

func _row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rows.add_child(row)
	return row

func _icon(parent: Control, key: String) -> void:
	var icon: TextureRect = TextureRect.new()
	icon.name = key
	icon.texture = load("res://assets/ui/icons/%s.png" % key)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(12, 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	icons[key] = icon

func _label(parent: Control, key: String) -> void:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 10)
	parent.add_child(label)
	values[key] = label

func _item(parent: Control, key: String) -> void:
	var group: HBoxContainer = HBoxContainer.new()
	parent.add_child(group)
	_icon(group, key)
	_label(group, key)

func display_dashboard(data: Dictionary) -> void:
	phase = data.phase
	icons.dia.visible = phase == "DÍA"
	icons.aviso.visible = phase == "AVISO"
	icons.noche.visible = phase == "NOCHE"
	values.phase.text = "%s %d   %ds" % [phase, data.day, data.seconds]
	values.chatarra.text = str(data.scrap)
	values.energia.text = "%d/%d" % [data.energy, data.capacity]
	values.habitantes.text = "%d/%d" % [data.population, data.population_max]
	var amounts: Array[int] = [data.health, data.stamina, data.core]
	bars.nucleo.max_value = data.get("core_max", GameRules.CORE_HEALTH)
	var keys: Array[String] = ["vida", "resistencia", "nucleo"]
	for index: int in range(keys.size()):
		bars[keys[index]].value = amounts[index]
		values[keys[index]].text = str(amounts[index])
	values.amenaza.text = "IZQ %d / DER %d" % [data.left, data.right]
	values.sobrecarga.text = "IZQ %s / DER %s" % [data.overload_left, data.overload_right]

