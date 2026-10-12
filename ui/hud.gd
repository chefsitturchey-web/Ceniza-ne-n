class_name GameHud
extends CanvasLayer

const ICON_NAMES: Array[String] = ["dia", "aviso", "noche", "chatarra", "energia", "habitantes", "vida", "resistencia", "nucleo", "amenaza", "sobrecarga"]
var icons: Dictionary = {}
var values: Dictionary = {}
var bars: Dictionary = {}
var rows: VBoxContainer
var phase: String = "DÍA"
var elapsed: float = 0.0

func _ready() -> void:
	rows = VBoxContainer.new()
	rows.position = Vector2(12, 4)
	rows.add_theme_constant_override("separation", 2)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rows)
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
	var controls: Label = Label.new()
	controls.text = "A/D mover · J ataque · Espacio esquiva · E obra · Q sobrecarga · Esc pausa"
	controls.add_theme_font_size_override("font_size", 10)
	controls.add_theme_color_override("font_color", Color("8299a8"))
	rows.add_child(controls)
	$Status.hide()

func _row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
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
	label.add_theme_font_size_override("font_size", 12)
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
	values.phase.text = "%s %d/%d · %ds" % [phase, data.day, data.nights, data.seconds]
	values.chatarra.text = str(data.scrap)
	values.energia.text = "%d/%d" % [data.energy, data.capacity]
	values.habitantes.text = "%d/%d" % [data.population, data.population_max]
	var amounts: Array[int] = [data.health, data.stamina, data.core]
	var keys: Array[String] = ["vida", "resistencia", "nucleo"]
	for index: int in range(keys.size()):
		bars[keys[index]].value = amounts[index]
		values[keys[index]].text = str(amounts[index])
	values.amenaza.text = "◀ %d / %d ▶" % [data.left, data.right]
	values.sobrecarga.text = "IZQ %s / DER %s" % [data.overload_left, data.overload_right]

func _process(delta: float) -> void:
	elapsed += delta
	icons.aviso.modulate.a = 0.75 + 0.25 * sin(elapsed * 6.0) if phase == "AVISO" else 1.0

## El texto completo se conserva en Status (oculto) para pruebas y accesibilidad; el panel visible es el de íconos.
func display(text: String, hint: String, result: String) -> void:
	$Status.text = text
	$Hint.text = hint
	$Result.text = result
