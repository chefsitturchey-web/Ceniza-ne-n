class_name BriefingPanel
extends CanvasLayer
signal closed
## La primera explicación detiene el reloj; no modifica la duración del día.
var opened: bool = false
var closed_frame: int = -1
var begin_button: Button
var zone: ZoneData

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var shade: MenuBackdrop = MenuBackdrop.new()
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	panel.position = Vector2(40, 15)
	panel.size = Vector2(560, 330)
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
	var index: int = maxi(0, ["periphery", "foundry", "flooded", "citadel", "network"].find(zone.id if zone != null else "periphery"))
	var chapter: Dictionary = CampaignStory.chapter(index)
	var instructions: Array[String] = [
		chapter.voice + ": " + String(chapter.opening).get_slice(".", 0) + ".",
		"OBJETIVO: sigue el texto superior del HUD. Siempre indica el siguiente paso y dónde hacerlo.",
		"De día construyes y exploras; de noche resistes tras las murallas. Tú organizas: tus tropas y torretas son las que luchan.",
		"Empieza recuperando piezas de las baterías junto al núcleo (mantén E) y levántalo." if index == 0 else "Tus mejoras y habitantes vienen contigo. Levanta el núcleo con las piezas del distrito.",
		"A/D mover - Shift correr - E interactuar - Espacio esquivar - F asaltar o retirar\nL diario - Q sobrecarga - Esc pausa - J atacar (solo contra jefes)"]
	for text: String in instructions:
		var label: Label = Label.new()
		label.text = text
		label.custom_minimum_size.x = 528
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		rows.add_child(label)
	begin_button = Button.new()
	begin_button.text = "Comenzar"
	begin_button.custom_minimum_size.y = 24
	begin_button.pressed.connect(close_panel)
	UiSound.attach(begin_button)
	rows.add_child(begin_button)
	hide()
	ScreenFit.fit_layer(self, [shade])

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
	closed.emit()
