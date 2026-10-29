class_name GameHud
extends CanvasLayer

const PHASE_DURATION: float = 2.5
var icons: Dictionary = {}
var values: Dictionary = {}
var elapsed: float = 0.0
var phase_key: String = ""
var phase_remaining: float = 0.0
var phase_banner: HBoxContainer
var context_label: Label
var context_row: HBoxContainer
var context_keycap: PanelContainer
var context_cost: Label
var context_icon: TextureRect
var context_progress: ColorRect
var toast: Label
var left_arrow: Control
var right_arrow: Control
var left_count: int = 0
var right_count: int = 0
var objective: Label
var poison_label: Label
var result_actions: HBoxContainer
var result_was_visible: bool = false
var pause_was_visible: bool = false
signal restart_requested
signal menu_requested
@onready var pause_panel: PausePanel = $PausePanel

func _ready() -> void:
	objective = _label($Gameplay)
	objective.position = Vector2(10, 10)
	objective.size = Vector2(620, 20)
	objective.add_theme_color_override("font_color", Color("8299a8"))
	poison_label = _label($Gameplay)
	poison_label.position = Vector2(10, 33)
	poison_label.add_theme_color_override("font_color", Color("7dd84f"))
	poison_label.text = "ENVENENADO"
	poison_label.hide()
	var resources: HBoxContainer = HBoxContainer.new()
	resources.position = Vector2(10, 337)
	resources.add_theme_constant_override("separation", 6)
	$Gameplay.add_child(resources)
	for key: String in ["chatarra", "energia"]:
		_icon(resources, key)
		values[key] = _label(resources)
	var overload_icon: TextureRect = _icon($Gameplay, "sobrecarga")
	overload_icon.position = Vector2(616, 338)
	phase_banner = HBoxContainer.new()
	phase_banner.add_theme_constant_override("separation", 6)
	$Gameplay.add_child(phase_banner)
	for key: String in ["dia", "aviso", "noche"]:
		_icon(phase_banner, key)
	values.phase = _label(phase_banner)
	values.phase.theme_type_variation = &"Title"
	context_row = HBoxContainer.new()
	context_row.add_theme_constant_override("separation", 4)
	$Gameplay.add_child(context_row)
	context_keycap = PanelContainer.new()
	var key_style: StyleBoxFlat = StyleBoxFlat.new()
	key_style.bg_color = Color("0b1322")
	key_style.border_color = Color("8299a8")
	key_style.set_border_width_all(1)
	key_style.content_margin_left = 3
	key_style.content_margin_right = 3
	context_keycap.add_theme_stylebox_override("panel", key_style)
	context_row.add_child(context_keycap)
	_label(context_keycap).text = "E"
	context_label = _label(context_row)
	context_label.add_theme_color_override("font_color", Color("ffce75"))
	context_icon = _icon(context_row, "chatarra")
	context_cost = _label(context_row)
	context_progress = ColorRect.new()
	context_progress.color = Color("ffce75")
	context_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Gameplay.add_child(context_progress)
	toast = _label($Gameplay)
	toast.position = Vector2(100, 303)
	toast.size = Vector2(440, 30)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_arrow = _arrow(Vector2(4, 174), -1)
	right_arrow = _arrow(Vector2(628, 174), 1)
	phase_banner.hide()
	result_actions = HBoxContainer.new()
	result_actions.position = Vector2(190, 245)
	result_actions.add_theme_constant_override("separation", 12)
	add_child(result_actions)
	for pair: Array in [["Reintentar", func() -> void: restart_requested.emit()], ["Menú principal", func() -> void: menu_requested.emit()]]:
		var button: Button = Button.new()
		button.text = pair[0]
		button.custom_minimum_size = Vector2(124, 25)
		button.pressed.connect(pair[1])
		result_actions.add_child(button)
	result_actions.hide()

func _label(parent: Node) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("8299a8"))
	label.add_theme_color_override("font_shadow_color", Color("0b1322"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label

func _icon(parent: Node, key: String) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.texture = load("res://assets/ui/icons/%s.png" % key)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(12, 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	icons[key] = icon
	return icon

func display_dashboard(data: Dictionary) -> void:
	objective.text = data.get("objective", "")
	poison_label.visible = data.get("poisoned", false)
	var result_visible: bool = data.get("finished", false)
	result_actions.visible = result_visible
	if result_visible and not result_was_visible:
		result_actions.get_child(0).grab_focus()
	result_was_visible = result_visible
	pause_panel.display_dashboard(data)
	pause_panel.visible = data.get("paused", false) and not data.get("finished", false)
	if pause_panel.visible and not pause_was_visible:
		pause_panel.resume_button.grab_focus()
	pause_was_visible = pause_panel.visible
	$Gameplay.visible = not pause_panel.visible and not data.get("finished", false)
	$DamageEdges.visible = $Gameplay.visible
	values.chatarra.text = str(data.scrap)
	values.energia.text = "%d/%d" % [data.energy, data.capacity]
	icons.sobrecarga.modulate = Color("47dacb") if "LISTA" in [data.overload_left, data.overload_right] else Color("304356")
	var next_phase: String = "%s:%d" % [data.phase, data.day]
	if next_phase != phase_key:
		phase_key = next_phase
		phase_remaining = PHASE_DURATION
		phase_banner.show()
		phase_banner.modulate.a = 1.0
		values.phase.text = {"DÍA": "DÍA %d" % data.day,
			"AVISO": "ATARDECER", "NOCHE": "NOCHE %d" % data.day}[data.phase]
		icons.dia.visible = data.phase == "DÍA"
		icons.aviso.visible = data.phase == "AVISO"
		icons.noche.visible = data.phase == "NOCHE"
		phase_banner.reset_size()
	left_count = data.get("offscreen_left", 0)
	right_count = data.get("offscreen_right", 0)
	left_arrow.visible = left_count > 0
	right_arrow.visible = right_count > 0
	context_label.text = data.get("context", "")
	context_row.visible = not context_label.text.is_empty() and data.health > 0
	context_keycap.visible = data.get("context_key", true)
	var cost: int = data.get("context_cost", -1)
	context_icon.visible = cost >= 0
	context_cost.visible = cost >= 0
	context_cost.text = str(cost) if cost >= 0 else ""
	context_row.reset_size()
	var anchor: Vector2 = data.get("context_screen", Vector2.ZERO)
	context_row.position = Vector2(clampf(anchor.x - context_row.size.x / 2, 8, 632 - context_row.size.x), clampf(anchor.y - 24, 50, 280)).round()
	var progress: float = clampf(data.get("context_progress", 0.0), 0, 1)
	context_progress.visible = context_row.visible and progress > 0
	context_progress.position = context_row.position + Vector2(0, context_row.size.y + 2)
	context_progress.size = Vector2(roundf(context_row.size.x * progress), 1)
	toast.text = data.get("notice", "")
	toast.theme_type_variation = &"SmallTitle" if toast.text == "DEFIENDE EL NÚCLEO" else &"Label"
	toast.modulate.a = clampf(data.get("notice_time", 0.0) / 0.6, 0, 1)
	$DamageEdges.set_state(data)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed += delta
	phase_remaining = maxf(0, phase_remaining - delta)
	phase_banner.visible = phase_remaining > 0
	phase_banner.modulate.a = minf(1, phase_remaining / 0.65)
	phase_banner.position = ((Vector2(640, 360) - phase_banner.size) / 2).round()
	left_arrow.modulate.a = _threat_alpha(left_count)
	right_arrow.modulate.a = _threat_alpha(right_count)

func _threat_alpha(count: int) -> float:
	return minf(0.9, 0.35 + count * 0.1) * (0.8 + 0.2 * sin(elapsed * 3))

## Texto legado oculto para consumidores existentes; toda la presentación usa el Dictionary.
func display(text: String, _hint: String, result: String) -> void:
	$Status.text = text
	$Result.text = result


func _arrow(at: Vector2, direction: int) -> Control:
	var arrow: Control = Control.new()
	arrow.position = at
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(func() -> void:
		var tip: float = 0 if direction < 0 else 6
		var tail: float = 6 if direction < 0 else 0
		arrow.draw_line(Vector2(tail, 0), Vector2(tip, 4), Color("dd6482"), 1)
		arrow.draw_line(Vector2(tip, 4), Vector2(tail, 8), Color("dd6482"), 1)
	)
	$Gameplay.add_child(arrow)
	arrow.hide()
	return arrow
