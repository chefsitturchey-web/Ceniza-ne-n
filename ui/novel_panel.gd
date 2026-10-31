class_name NovelPanel
extends CanvasLayer
## Modal con dueño de pausa; el texto no avanza el reloj ni ejecuta acciones del mundo.
signal finished(scene_id: String)
## Abre y cierra para que el audio del mundo baje mientras se lee.
signal panel_opened
signal panel_closed
const PORTRAITS: Texture2D = preload("res://assets/characters/portraits/portraits_manga_v2.png")
const ANTAGONISTS: Texture2D = preload("res://assets/characters/portraits/antagonists_manga_v2.png")
const CAST: Array[String] = ["mara", "ivo", "vera", "nox", "eco", "portador"]
## Voz de texto: un blip corto por personaje, emoción y altura, sin voces reales.
const VOICE_INTERVAL: float = 0.08
## Varias voces a la vez: un blip largo no corta al siguiente.
const VOICE_VOICES: int = 3
var opened: bool = false
var closed_frame: int = -1
var scene_data: Dictionary = {}
var line_index: int = 0
var body: RichTextLabel
var speaker: Label
var title: Label
var counter: Label
var left: TextureRect
var right: TextureRect
var background: TextureRect
var curtain: ColorRect
var next_button: Button
var skip_button: Button
var previous_button: Button
var previous_pause: bool = false
var transitioning: bool = false
var reveal: float = 0
var elapsed: float = 0
var input_after: int = -1
var partner: String = "mara"
var transition: Tween
var stage: Control
var reduced_motion: bool = false
var boss_portraits: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_stream: AudioStream
var voice_pitch: float = 1.0
var voice_db: float = -14.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var blip_wait: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 45
	stage = Control.new()
	stage.size = Vector2(640, 360)
	stage.theme = preload("res://ui/theme.tres").duplicate()
	stage.theme.default_font = ThemeDB.fallback_font
	stage.theme.default_font_size = 14
	add_child(stage)
	var opaque_back: ColorRect = ColorRect.new()
	opaque_back.size = stage.size
	opaque_back.color = Color("07101b")
	opaque_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(opaque_back)
	background = TextureRect.new()
	background.size = stage.size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stage.add_child(background)
	var veil: ColorRect = ColorRect.new()
	veil.size = stage.size
	veil.color = Color("07101b", 0.58)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(veil)
	left = portrait(Vector2(-4, 24))
	right = portrait(Vector2(388, 24))
	title = label("", Vector2(24, 12), Vector2(480, 25), 16)
	title.add_theme_color_override("font_color", Color("b8e5e6"))
	var box: Panel = Panel.new()
	box.position = Vector2(24, 214)
	box.size = Vector2(592, 130)
	box.add_theme_stylebox_override("panel", MenuSkin.panel())
	stage.add_child(box)
	speaker = label("", Vector2(42, 222), Vector2(420, 23), 16)
	speaker.add_theme_color_override("font_color", Color("ffce75"))
	body = RichTextLabel.new()
	body.position = Vector2(42, 248)
	body.size = Vector2(552, 61)
	body.scroll_active = false
	body.add_theme_font_size_override("normal_font_size", 14)
	body.add_theme_color_override("default_color", Color("edf3f4"))
	body.add_theme_constant_override("normal_line_separation", 3)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(body)
	counter = label("", Vector2(42, 319), Vector2(90, 19), 11)
	previous_button = button("Anterior", Vector2(320, 318), Vector2(85, 23), previous_line)
	next_button = button("Continuar  ›", Vector2(420, 318), Vector2(172, 23), advance)
	skip_button = button("Omitir", Vector2(548, 12), Vector2(68, 24), close_panel)
	curtain = ColorRect.new()
	curtain.size = stage.size
	curtain.color = Color.BLACK
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(curtain)
	for index: int in range(VOICE_VOICES):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		voices.append(player)
	rng.randomize()
	hide()

func portrait(at: Vector2) -> TextureRect:
	var result: TextureRect = TextureRect.new()
	result.position = at
	result.size = Vector2(256, 269)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(result)
	return result

func label(text: String, at: Vector2, extent: Vector2, font_size: int) -> Label:
	var result: Label = Label.new()
	result.position = at
	result.size = extent
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(result)
	return result

func button(text: String, at: Vector2, extent: Vector2, action: Callable) -> Button:
	var result: Button = Button.new()
	result.position = at
	result.size = extent
	result.text = text
	result.add_theme_font_size_override("font_size", 12)
	result.pressed.connect(action)
	UiSound.attach(result)
	stage.add_child(result)
	return result

func actor_texture(id: String) -> Texture2D:
	if id in ["recaudador", "caldera", "coro"]:
		if not boss_portraits.has(id): boss_portraits[id] = load("res://assets/characters/portraits/bosses/%s.png" % id)
		return boss_portraits[id]
	if id in ["prefect", "mother"]: return ArtScale.atlas(ANTAGONISTS, 0 if id == "prefect" else 1)
	return ArtScale.atlas(PORTRAITS, maxi(0, CAST.find(id)))

func play(data: Dictionary, allow_paused: bool = false) -> bool:
	if opened or (get_tree().paused and not allow_paused) or data.get("lines", []).is_empty(): return false
	previous_pause = get_tree().paused
	scene_data = data.duplicate(true)
	line_index = 0
	opened = true
	transitioning = true
	input_after = Engine.get_process_frames() + 1
	reduced_motion = GamePreferences.current().reduced_flashes
	get_tree().paused = true
	background.texture = load(data.background) as Texture2D
	title.text = data.title
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size = Vector2(480, 25)
	partner = "eco"
	for line: Dictionary in data.lines:
		if line.speaker not in ["portador", "narrator"]:
			partner = line.speaker
			break
	right.texture = actor_texture("portador")
	curtain.color.a = 1
	show()
	show_line()
	transition = create_tween()
	transition.tween_property(curtain, "color:a", 0.0, 0.12 if reduced_motion else 0.35)
	transition.finished.connect(func() -> void: transitioning = false; next_button.grab_focus())
	panel_opened.emit()
	return true

func show_line() -> void:
	var line: Dictionary = scene_data.lines[line_index]
	var parts: PackedStringArray = String(scene_data.get("id", "")).split(":")
	var section: String = parts[parts.size() - 1] if parts.size() > 1 else "opening"
	if line.speaker not in ["portador", "narrator"]: partner = line.speaker
	left.texture = actor_texture(partner)
	left.modulate = Color.WHITE if line.speaker == partner else Color(0.56, 0.64, 0.72, 0.85)
	right.modulate = Color.WHITE if line.speaker == "portador" else Color(0.56, 0.64, 0.72, 0.85)
	if not reduced_motion and line.speaker == partner:
		left.position.x = -12
		create_tween().tween_property(left, "position:x", -4.0, 0.22).set_trans(Tween.TRANS_SINE)
	speaker.text = VisualStory.actor_name(line.speaker)
	body.text = line.text
	body.visible_characters = 0
	reveal = 0
	blip_wait = 0.0
	var actor: String = String(line.speaker)
	voice_stream = VoiceLibrary.stream_for(actor, VoiceLibrary.emotion_for(section), rng.randi_range(1, VoiceLibrary.VARIANTS))
	voice_pitch = pow(2.0, VoiceLibrary.shift_for(actor) / 12.0)
	voice_db = -20.0 if actor == "narrator" else -14.0
	counter.text = "%d / %d" % [line_index + 1, scene_data.lines.size()]
	previous_button.disabled = line_index == 0
	next_button.text = "Continuar  ›" if line_index < scene_data.lines.size() - 1 else "Volver al juego"

func _process(delta: float) -> void:
	if not opened: return
	elapsed += delta
	if not reduced_motion:
		left.position.y = 24 + sin(elapsed * 1.7) * 0.8
		right.position.y = 24 + sin(elapsed * 1.6 + 1) * 0.8
	blip_wait = maxf(0.0, blip_wait - delta)
	var total: int = body.get_total_character_count()
	# Solo avanza y suena mientras quede texto: sin la condición, reveal seguía
	# creciendo y los blips se repetían en bucle con la línea ya completa.
	if not transitioning and body.visible_characters < total:
		var before: int = int(reveal)
		reveal = minf(reveal + delta * 44.0, float(total))
		body.visible_characters = mini(total, int(reveal))
		if int(reveal) > before:
			_speak()

func _speak() -> void:
	if blip_wait > 0.0 or DisplayServer.get_name() == "headless" or voice_stream == null:
		return
	var target: AudioStreamPlayer = null
	for player: AudioStreamPlayer in voices:
		if not player.playing:
			target = player
			break
	if target == null:
		return
	blip_wait = VOICE_INTERVAL
	target.stream = voice_stream
	target.pitch_scale = voice_pitch * (1.0 + rng.randf_range(-0.015, 0.015))
	target.volume_db = voice_db
	target.play()

func advance() -> void:
	if not opened or transitioning or Engine.get_process_frames() <= input_after: return
	if body.visible_characters < body.get_total_character_count():
		reveal = body.get_total_character_count()
		body.visible_characters = int(reveal)
	elif line_index + 1 < scene_data.lines.size():
		line_index += 1
		show_line()
	else: close_panel()

func previous_line() -> void:
	if not opened or transitioning or line_index <= 0: return
	line_index -= 1
	show_line()
	reveal = body.get_total_character_count()
	body.visible_characters = int(reveal)

func close_panel() -> void:
	if not opened or transitioning: return
	transitioning = true
	if transition != null and transition.is_running(): transition.kill()
	transition = create_tween()
	transition.tween_property(curtain, "color:a", 1.0, 0.12 if reduced_motion else 0.22)
	transition.finished.connect(finish_close)

func finish_close() -> void:
	opened = false
	transitioning = false
	closed_frame = Engine.get_process_frames()
	hide()
	get_tree().paused = previous_pause
	GamePreferences.current().block_gameplay_input()
	panel_closed.emit()
	finished.emit(scene_data.id)

func _input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if not opened or event.is_echo(): return
	if event.is_action_pressed("pause"):
		close_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE):
		advance()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if opened and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
