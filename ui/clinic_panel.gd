class_name ClinicPanel
extends CanvasLayer
## Panel contextual; abrirlo detiene el tiempo y cerrarlo devuelve el control.
var district: Node2D
var opened: bool = false
var closed_frame: int = -1
var panel: PanelContainer
var status: Label
var buttons: Array[Button] = []
const TITLES: Array[String] = ["FILO DE INDUCCIÓN", "DRON PERFORADOR", "CAPACITOR SINÁPTICO"]
const DETAILS: Array[String] = ["+10 daño por rango; también contra el jefe", "+4 daño; intervalo de disparo -10% por rango", "+5 resistencia por segundo y por rango"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.9)
	shade.size = Vector2(640, 360)
	add_child(shade)
	panel = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.position = Vector2(66, 35)
	panel.size = Vector2(508, 290)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)
	var title: Label = Label.new()
	title.text = "CLÍNICA DE ENLACE"
	title.theme_type_variation = &"Title"
	rows.add_child(title)
	status = Label.new()
	rows.add_child(status)
	for index: int in range(NeuralSystem.IDS.size()):
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_install.bind(NeuralSystem.IDS[index]))
		rows.add_child(button)
		buttons.append(button)
	var close: Button = Button.new()
	close.text = "Volver  [Esc / Start]"
	close.pressed.connect(close_panel)
	rows.add_child(close)
	hide()

func open_panel() -> bool:
	if opened or district.cycle.phase != "DÍA" or district.session.finished or district.player.health <= 0 or get_tree().paused:
		return false
	opened = true
	get_tree().paused = true
	show()
	refresh()
	buttons[0].grab_focus()
	return true

func refresh() -> void:
	var neural: NeuralSystem = district.neural
	status.text = "Datos %d/%d   |   Puntos disponibles: %d\nCada 6 máquinas recuperas un punto. Cada mejora cuesta 1." % [neural.kills % NeuralSystem.KILLS_PER_POINT, NeuralSystem.KILLS_PER_POINT, neural.points()]
	for index: int in range(buttons.size()):
		var rank: int = neural.ranks[NeuralSystem.IDS[index]]
		buttons[index].text = "%s   %d/3\n%s%s" % [TITLES[index], rank, DETAILS[index], "  [MÁX.]" if rank == 3 else ""]

func _install(id: String) -> void:
	if district.neural.install(id):
		district.sound.play_cue("upgrade")
		if district.session.save_system != null:
			district.session.save_system.save_game()
	refresh()

func close_panel() -> void:
	if not opened:
		return
	opened = false
	closed_frame = Engine.get_process_frames()
	hide()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("pause") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
