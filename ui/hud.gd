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
var toast: Label
var left_arrow: Label
var right_arrow: Label
var left_count: int = 0
var right_count: int = 0
@onready var pause_panel: PausePanel = $PausePanel

func _ready() -> void:
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
	context_label = _label($Gameplay)
	context_label.add_theme_color_override("font_color", Color("ffce75"))
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_label.size = Vector2(280, 36)
	toast = _label($Gameplay)
	toast.position = Vector2(100, 303)
	toast.size = Vector2(440, 30)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_arrow = _label($Gameplay)
	left_arrow.text = "‹"
	left_arrow.position = Vector2(3, 168)
	right_arrow = _label($Gameplay)
	right_arrow.text = "›"
	right_arrow.position = Vector2(627, 168)
	for arrow: Label in [left_arrow, right_arrow]:
		arrow.add_theme_font_size_override("font_size", 20)
		arrow.add_theme_color_override("font_color", Color("dd6482"))
		arrow.hide()
	phase_banner.hide()

func _label(parent: Node) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 11)
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
	pause_panel.display_dashboard(data)
	pause_panel.visible = data.get("paused", false) and not data.get("finished", false)
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
		values.phase.text = {"DÍA": "AMANECE · Día %d" % data.day,
			"AVISO": "ATARDECER · Prepárate", "NOCHE": "NOCHE %d · Llegan por ambos lados" % data.day}[data.phase]
		icons.dia.visible = data.phase == "DÍA"
		icons.aviso.visible = data.phase == "AVISO"
		icons.noche.visible = data.phase == "NOCHE"
		phase_banner.reset_size()
	left_count = data.get("offscreen_left", 0)
	right_count = data.get("offscreen_right", 0)
	left_arrow.visible = left_count > 0
	right_arrow.visible = right_count > 0
	context_label.text = data.get("context", "")
	context_label.visible = not context_label.text.is_empty() and data.health > 0
	var anchor: Vector2 = data.get("context_screen", Vector2.ZERO)
	context_label.position = Vector2(clampf(anchor.x - 140, 8, 352), clampf(anchor.y - 40, 50, 260)).round()
	toast.text = data.get("notice", "")
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
