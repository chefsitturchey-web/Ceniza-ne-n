class_name MainMenu
extends Control

signal launch_requested(fresh: bool)
var checkpoint_path: String = "user://partida.json"
var navigation_enabled: bool = true
var continue_button: Button
var new_button: Button
var options_button: Button
var status: Label
var options: SettingsPanel = SettingsPanel.new()
var confirm: ConfirmationDialog
var elapsed: float = 0.0
var illustration: Texture2D
var music: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://ui/theme.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	InputSetup.configure_input()
	get_tree().paused = false
	if ResourceLoader.exists("res://assets/menu/ruinas_menu.png"):
		illustration = load("res://assets/menu/ruinas_menu.png") as Texture2D
	var content: VBoxContainer = VBoxContainer.new()
	content.position = Vector2(38, 23)
	content.size = Vector2(258, 310)
	content.add_theme_constant_override("separation", 7)
	add_child(content)
	var marker: Label = Label.new()
	marker.text = "ENLACE NEURONAL // SEÑAL ACTIVA"
	marker.add_theme_color_override("font_color", Color("47dacb"))
	content.add_child(marker)
	var title: Label = Label.new()
	title.text = "CENIZA\nNEÓN"
	title.theme_type_variation = &"Title"
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)
	var tagline: Label = Label.new()
	tagline.text = "Construye de día. Resiste de noche.\nRecupera la ciudad."
	tagline.add_theme_font_size_override("font_size", 13)
	content.add_child(tagline)
	continue_button = _button(content, "Continuar", _continue_game)
	new_button = _button(content, "Nueva partida", request_new_game)
	options_button = _button(content, "Opciones", options.open_panel)
	_button(content, "Salir", func() -> void: get_tree().quit())
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(258, 22)
	status.add_theme_color_override("font_color", Color("8299a8"))
	content.add_child(status)
	add_child(options)
	options.closed.connect(func() -> void: options_button.grab_focus())
	confirm = ConfirmationDialog.new()
	confirm.title = "Nueva partida"
	confirm.dialog_text = "Tu partida actual se archivará antes de empezar.\n¿Iniciar una nueva colonia?"
	confirm.ok_button_text = "Nueva colonia"
	confirm.cancel_button_text = "Volver"
	confirm.confirmed.connect(func() -> void: _launch(true))
	add_child(confirm)
	music.stream = GameSound.MUSIC[0]
	music.bus = &"Music"
	music.volume_db = -18
	add_child(music)
	if DisplayServer.get_name() != "headless":
		music.play()
	refresh_checkpoint()
	(continue_button if not continue_button.disabled else new_button).grab_focus()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(252, 25)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("182639", 0.88 if state != "disabled" else 0.45)
		style.content_margin_left = 12
		style.content_margin_right = 10
		style.border_width_left = 2
		style.border_color = Color("47dacb") if state in ["focus", "hover"] else Color("304356")
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color("dcf6ee"))
	button.add_theme_color_override("font_disabled_color", Color("8299a8", 0.5))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func refresh_checkpoint() -> void:
	var info: Dictionary = SaveSystem.checkpoint_info(checkpoint_path)
	continue_button.disabled = info.is_empty()
	status.text = "Sin partida guardada. Empieza una colonia." if info.is_empty() else "Día %d · %d chatarra · último amanecer" % [info.day, info.scrap]

func request_new_game() -> void:
	if FileAccess.file_exists(checkpoint_path):
		confirm.popup_centered()
	else:
		_launch(true)

func _continue_game() -> void:
	if not SaveSystem.checkpoint_info(checkpoint_path).is_empty():
		_launch(false)

func _launch(fresh: bool) -> void:
	if fresh and not SaveSystem.archive_checkpoint(checkpoint_path):
		status.text = "No se pudo archivar la partida. Tu guardado sigue intacto."
		return
	launch_requested.emit(fresh)
	if navigation_enabled:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/main.tscn")

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b1322"))
	if illustration != null:
		draw_texture_rect(illustration, Rect2(0, 0, 640, 360), false)
	# Velo graduado: la ilustración no compite con el texto interactivo.
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(390, 0), Vector2(390, 360), Vector2(0, 360)]),
		PackedColorArray([Color("0b1322", 0.98), Color("0b1322", 0.15), Color("0b1322", 0.15), Color("0b1322", 0.98)]))
	if GamePreferences.current().particles:
		for index: int in range(30):
			var x: float = fposmod(index * 79.0 + elapsed * 6, 640)
			var y: float = fposmod(index * 37.0 + elapsed * 10, 360)
			draw_rect(Rect2(roundf(x), roundf(y), 1, 1), Color("ffce75", 0.22))
	draw_line(Vector2(38, 345), Vector2(602, 345), Color("304356"), 1)
