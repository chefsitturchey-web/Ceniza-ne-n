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

func _ready() -> void:
	add_theme_stylebox_override("panel", MenuSkin.panel())
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
	var controls: GridContainer = GridContainer.new()
	controls.columns = 4
	controls.add_theme_constant_override("h_separation", 12)
	controls.add_theme_constant_override("v_separation", 2)
	rows.add_child(controls)
	for text: String in ["Mover", "A/D / Stick", "Atacar", "J / X", "Esquivar", "Espacio / A",
		"Interactuar", "Mantén E / Y", "Sobrecarga", "Q / LB", "Continuar", "Esc / Start",
		"Reintentar", "R / Select", "Audio", "M", "Escolta", "F / Arriba"]:
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 10)
		label.text = text
		controls.add_child(label)
	var actions: HBoxContainer = _row()
	resume_button = Button.new()
	resume_button.text = "Continuar"
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	UiSound.attach(resume_button)
	actions.add_child(resume_button)
	for pair: Array in [["Opciones", func() -> void: options_requested.emit()], ["Menú principal", func() -> void: menu_requested.emit()]]:
		var button: Button = Button.new()
		button.text = pair[0]
		button.pressed.connect(pair[1])
		UiSound.attach(button)
		actions.add_child(button)


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

