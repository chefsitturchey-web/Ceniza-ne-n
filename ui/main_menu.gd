class_name MainMenu
extends Control

signal launch_requested(fresh: bool)
const CRT: Shader = preload("res://ui/shaders/crt_vignette.gdshader")
var checkpoint_path: String = "user://partida.json"
var navigation_enabled: bool = true
var continue_button: Button
var new_button: Button
var options_button: Button
var boss_rush_button: Button
var status: Label
var options: SettingsPanel = SettingsPanel.new()
var confirm: ConfirmationDialog
var elapsed: float = 0.0
var illustration: Texture2D
var music: AudioStreamPlayer = AudioStreamPlayer.new()
var neon_title: Label
var neon_tween: Tween
var neon_level: float = 1.0
var embers: CPUParticles2D
var ash: CPUParticles2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://ui/theme.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	InputSetup.configure_input()
	get_tree().paused = false
	if ResourceLoader.exists("res://assets/ui/menu/ruinas_menu.png"):
		illustration = load("res://assets/ui/menu/ruinas_menu.png") as Texture2D
	_build_particles()
	# En moviles con notch el panel se aparta del recorte izquierdo (margen del contenedor raiz).
	var inset: int = roundi(float(ScreenFit.safe_margins(self).left))
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24 + inset)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.add_theme_constant_override("margin_right", 24)
	add_child(margin)
	var frame: PanelContainer = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	frame.custom_minimum_size = Vector2(320, 0)
	frame.add_theme_stylebox_override("panel", MenuSkin.panel())
	margin.add_child(frame)
	var inner: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 20 if side == "left" or side == "right" else 12)
	frame.add_child(inner)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	inner.add_child(content)
	var marker: Label = Label.new()
	marker.text = "ENLACE NEURONAL // SEÑAL ACTIVA"
	marker.add_theme_font_size_override("font_size", 10)
	marker.add_theme_color_override("font_color", Color("47dacb"))
	content.add_child(marker)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.add_theme_constant_override("separation", -4)
	content.add_child(title_box)
	var title: Label = Label.new()
	title.text = "CENIZA"
	title.theme_type_variation = &"Title"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("dcf6ee"))
	title.add_theme_color_override("font_outline_color", Color("0b1322"))
	title.add_theme_constant_override("outline_size", 4)
	title_box.add_child(title)
	neon_title = Label.new()
	neon_title.text = "NEÓN"
	neon_title.theme_type_variation = &"Title"
	neon_title.add_theme_font_size_override("font_size", 32)
	neon_title.add_theme_color_override("font_color", Color("ffce75"))
	neon_title.add_theme_constant_override("outline_size", 5)
	title_box.add_child(neon_title)
	_set_neon(1.0)
	var tagline: Label = Label.new()
	tagline.text = "Construye de día. Resiste de noche.\nRecupera la ciudad."
	tagline.add_theme_font_size_override("font_size", 11)
	content.add_child(tagline)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 5)
	content.add_child(buttons)
	continue_button = _button(buttons, "Continuar", _continue_game)
	new_button = _button(buttons, "Nueva partida", request_new_game)
	boss_rush_button = _button(buttons, "Boss Rush", start_boss_rush)
	options_button = _button(buttons, "Opciones", options.open_panel)
	_button(buttons, "Salir", func() -> void: get_tree().quit())
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(250, 22)
	status.add_theme_color_override("font_color", Color("8299a8"))
	status.add_theme_font_override("font", ThemeDB.fallback_font)
	status.add_theme_font_size_override("font_size", 11)
	content.add_child(status)
	# Velo de escaneo y vineta sobre todo el menu; ignora el raton.
	var crt: ColorRect = ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_material: ShaderMaterial = ShaderMaterial.new()
	crt_material.shader = CRT
	crt_material.set_shader_parameter("scanline", 0.0 if GamePreferences.current().reduced_flashes else 0.06)
	crt.material = crt_material
	add_child(crt)
	add_child(options)
	options.closed.connect(func() -> void: options_button.grab_focus())
	confirm = ConfirmationDialog.new()
	confirm.title = "Nueva partida"
	confirm.dialog_text = "Tu partida actual se archivará antes de empezar.\n¿Iniciar una nueva colonia?"
	confirm.ok_button_text = "Nueva colonia"
	confirm.cancel_button_text = "Volver"
	confirm.confirmed.connect(func() -> void: _launch(true))
	add_child(confirm)
	UiSound.attach(confirm.get_ok_button())
	UiSound.attach(confirm.get_cancel_button())
	music.stream = MusicLibrary.MENU
	music.bus = &"Music"
	music.volume_db = -18
	add_child(music)
	if DisplayServer.get_name() != "headless":
		music.play()
	refresh_checkpoint()
	(continue_button if not continue_button.disabled else new_button).grab_focus()
	_play_entrance([marker, title, neon_title, tagline], buttons, status)
	_flicker()

func _build_particles() -> void:
	var width: float = maxf(640.0, get_viewport_rect().size.x)
	# Brasas que suben desde el suelo y ceniza gris que cae despacio.
	embers = _emitter(width, Color("ffb25a"), Vector2(0, -1), 14.0, 34.0, 26)
	embers.position = Vector2(width * 0.5, 372)
	ash = _emitter(width, Color("8299a8", 0.55), Vector2(0.15, 1), 6.0, 16.0, 36)
	ash.position = Vector2(width * 0.5, -12)

func _emitter(width: float, color: Color, direction: Vector2, speed_min: float, speed_max: float, amount: int) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = 14.0
	particles.preprocess = 14.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(width * 0.5, 2)
	particles.direction = direction
	particles.spread = 24.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = speed_min
	particles.initial_velocity_max = speed_max
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color
	particles.emitting = GamePreferences.current().particles
	add_child(particles)
	return particles

func _play_entrance(heading: Array[Control], buttons: VBoxContainer, footer: Control) -> void:
	var delay: float = 0.05
	for item: Control in heading:
		MenuFx.slide_in(item, delay)
		delay += 0.08
	for child: Node in buttons.get_children():
		MenuFx.slide_in(child as Control, delay, -36.0)
		delay += 0.07
	MenuFx.slide_in(footer, delay, 0.0)

## Brillo del neon: 1 encendido, valores menores simulan el tubo fallando.
func _set_neon(level: float) -> void:
	neon_level = level
	neon_title.self_modulate = Color(0.55 + 0.45 * level, 0.5 + 0.5 * level, 0.55 + 0.45 * level)
	neon_title.add_theme_color_override("font_outline_color", Color("e89e54", 0.12 + 0.42 * level))

func _flicker() -> void:
	if GamePreferences.current().reduced_flashes or not is_inside_tree():
		_set_neon(1.0)
		return
	neon_tween = create_tween()
	neon_tween.tween_interval(randf_range(2.0, 5.0))
	for level: float in [0.3, 1.0, 0.45, 1.0, 0.2, 0.9, 1.0]:
		neon_tween.tween_callback(_set_neon.bind(level))
		neon_tween.tween_interval(randf_range(0.03, 0.09))
	neon_tween.tween_callback(_flicker)

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.theme_type_variation = &"MenuEntry"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 24)
	button.pressed.connect(action)
	MenuSkin.button(button)
	UiSound.attach(button)
	parent.add_child(button)
	return button

func refresh_checkpoint() -> void:
	var info: Dictionary = SaveSystem.checkpoint_info(checkpoint_path)
	continue_button.disabled = info.is_empty()
	status.text = "Sin partida guardada. Empieza una colonia." if info.is_empty() else "%s\nDía %d · %d chatarra" % [CampaignRoute.zone(int(info.get("zone", 0))).title, info.day, info.scrap]

func request_new_game() -> void:
	if FileAccess.file_exists(checkpoint_path):
		confirm.popup_centered()
	else:
		_launch(true)

## Los cinco jefes seguidos; no lee ni modifica la partida guardada.
func start_boss_rush() -> void:
	if navigation_enabled:
		get_tree().paused = false
		ScreenFade.change_scene(get_tree(), "res://levels/expedition/boss_rush.tscn")

func _continue_game() -> void:
	if not SaveSystem.checkpoint_info(checkpoint_path).is_empty():
		_launch(false)

## Una partida nueva vuelve a enseñar la guía con flechas; récord y logros se conservan.
static func reset_guide() -> void:
	var profile: Dictionary = SaveSystem.engagement_profile()
	profile.guide = 0
	profile.tips = []
	SaveSystem.store_engagement(profile)

func _launch(fresh: bool) -> void:
	if fresh and not SaveSystem.archive_checkpoint(checkpoint_path):
		status.text = "No se pudo archivar la partida. Tu guardado sigue intacto."
		return
	launch_requested.emit(fresh)
	if navigation_enabled:
		if fresh: reset_guide()
		GamePreferences.current().briefing_requested = fresh
		get_tree().paused = false
		CampaignRoute.pending.clear()
		var info: Dictionary = SaveSystem.checkpoint_info(checkpoint_path)
		CampaignRoute.resume_path = checkpoint_path
		FrontierLayout.active_seed = FrontierLayout.new_seed() if fresh else int(info.get("seed", 0))
		if not fresh and int(info.get("zone", 0)) > 0:
			GamePreferences.current().briefing_requested = true
		ScreenFade.change_scene(get_tree(), CampaignRoute.SCENES[0 if fresh else int(info.get("zone", 0))])

func _process(delta: float) -> void:
	if not GamePreferences.current().reduced_flashes:
		elapsed += delta
	var show_particles: bool = GamePreferences.current().particles
	embers.emitting = show_particles
	ash.emitting = show_particles
	queue_redraw()

func _draw() -> void:
	# Ancho visible: 640 en 16:9; en moviles anchos la ilustracion cubre todo sin deformarse.
	var width: float = maxf(640.0, get_viewport_rect().size.x)
	draw_rect(Rect2(0, 0, width, 360), Color("0b1322"))
	# Capa lejana: estrellas que titilan.
	for index: int in range(26):
		var twinkle: float = 0.5 + 0.5 * sin(elapsed * (0.8 + index % 5 * 0.3) + index * 1.7)
		draw_rect(Rect2(roundf(fposmod(index * 97.0, width)), roundf(fposmod(index * 53.0, 120)), 1, 1), Color("dcf6ee", 0.15 + 0.4 * twinkle))
	if illustration != null:
		# Capa media: la ilustracion respira y deriva lentamente (paralaje con el raton).
		var cursor: Vector2 = get_local_mouse_position() / Vector2(width, 360) - Vector2(0.5, 0.5)
		var zoom: float = 1.07 + sin(elapsed * 0.15) * 0.01
		var cover: Vector2 = Vector2(640, 360) * (width / 640.0) * zoom
		var drift: Vector2 = Vector2(sin(elapsed * 0.1) * 9.0, cos(elapsed * 0.07) * 4.0) - cursor.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5)) * 10.0
		draw_texture_rect(illustration, Rect2((Vector2(width, 360) - cover) / 2.0 + drift, cover), false)
	# Capa cercana: bancos de niebla que cruzan despacio.
	for index: int in range(3):
		var fog_x: float = fposmod(elapsed * (5.0 + index * 3.0) + index * 260.0, width + 400.0) - 200.0
		var fog_y: float = 230.0 + index * 46.0
		draw_polygon(PackedVector2Array([Vector2(fog_x - 200, fog_y + 30), Vector2(fog_x, fog_y - 6), Vector2(fog_x + 200, fog_y + 30)]),
			PackedColorArray([Color("8299a8", 0.0), Color("8299a8", 0.1), Color("8299a8", 0.0)]))
	# Velo graduado: la ilustracion no compite con el texto interactivo.
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(400, 0), Vector2(400, 360), Vector2(0, 360)]),
		PackedColorArray([Color("0b1322", 0.98), Color("0b1322", 0.1), Color("0b1322", 0.1), Color("0b1322", 0.98)]))
	draw_line(Vector2(38, 345), Vector2(width - 38, 345), Color("304356"), 1)
