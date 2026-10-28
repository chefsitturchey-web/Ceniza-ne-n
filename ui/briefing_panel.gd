class_name BriefingPanel
extends CanvasLayer
## La primera explicación detiene el reloj; no modifica la duración del día.
var opened: bool = false
var closed_frame: int = -1
var begin_button: Button
var zone: ZoneData

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("0b1322", 0.94)
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.position = Vector2(60, 30)
	panel.size = Vector2(520, 300)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)
	var title: Label = Label.new()
	title.theme_type_variation = &"Title"
	title.text = "LEVANTA LA COLONIA"
	if zone != null and zone.id != "periphery":
		title.text = zone.title.to_upper()
	title.add_theme_color_override("font_color", Color("47dacb"))
	rows.add_child(title)
	var instructions: Array[String] = ["Encarga ambas murallas y torretas manteniendo E en los marcos. El constructor se ocupa de levantarlas.", "En el núcleo puedes curarte y reclutar de día. El recuperador trae chatarra automáticamente.", "Defiende ambos frentes. Esquiva con Espacio; Q sobrecarga las defensas del lado donde estás.", "Destruye las dos antenas de los extremos. Cuando llegue el tren, viaja de día para derrotar al jefe.", "A/D: mover   J: atacar   E: mantener para interactuar\nMando: stick / X / A / Y / LB   Esc o Start: pausa"]
	if zone != null and zone.id != "periphery":
		instructions = ["Tus mejoras y habitantes han llegado contigo. Levanta las defensas de esta colonia con E antes del asedio.", "Las rejillas avisan en amarillo antes de quemar durante la noche." if zone.id == "foundry" else "Los charcos frenan tus pasos. Puedes cruzarlos con una esquiva.", "Destruye los repetidores de ambos extremos y toma el tren de día para desafiar a " + zone.boss_title + ".", zone.briefing, "A/D: mover   J: atacar   E: interactuar\nEspacio: esquivar   Q: sobrecarga   Esc: pausa"]
	for text: String in instructions:
		var label: Label = Label.new()
		label.text = text
		label.custom_minimum_size.x = 480
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 13)
		rows.add_child(label)
	begin_button = Button.new()
	begin_button.text = "Comenzar"
	begin_button.custom_minimum_size.y = 24
	begin_button.pressed.connect(close_panel)
	rows.add_child(begin_button)
	hide()

func open_panel() -> void:
	opened = true
	get_tree().paused = true
	show()
	begin_button.grab_focus()

func close_panel() -> void:
	if not opened:
		return
	opened = false
	closed_frame = Engine.get_process_frames()
	GamePreferences.current().block_gameplay_input()
	hide()
	get_tree().paused = false
