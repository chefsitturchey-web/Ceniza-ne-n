class_name UiSound
extends RefCounted
## Sonidos de interfaz compartidos por menús y paneles.
## Crea sus propios reproductores bajo la raíz: no necesita autoload ni referencias.

const CLICK: String = "res://assets/audio/sfx/8bit/interfaz/ui_click.wav"
const HOVER: String = "res://assets/audio/sfx/8bit/interfaz/ui_hover.wav"
const MOVE: String = "res://assets/audio/sfx/8bit/interfaz/ui_move.wav"
const BACK: String = "res://assets/audio/sfx/8bit/interfaz/ui_back.wav"
const VOICES: int = 3

static var voices: Array[AudioStreamPlayer] = []
static var streams: Dictionary = {}

## Carga diferida: si el WAV no estaba importado al compilar el script, un
## preload queda en null para toda la sesión y el sonido desaparece en silencio.
static func load_stream(path: String) -> AudioStream:
	if not streams.has(path):
		streams[path] = load(path) as AudioStream
		if streams[path] == null:
			push_warning("UiSound: no se pudo cargar " + path)
	return streams[path] as AudioStream

static func play(stream: AudioStream, gain_db: float = -8.0) -> void:
	if stream == null or DisplayServer.get_name() == "headless":
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_ensure_voices(tree)
	for player: AudioStreamPlayer in voices:
		if not is_instance_valid(player) or player.playing:
			continue
		player.stream = stream
		player.volume_db = gain_db
		# Durante el _ready de la escena inicial el reproductor todavía no entró
		# al árbol y play() falla. Se difiere al siguiente frame.
		if player.is_inside_tree():
			player.play()
		else:
			player.call_deferred("play")
		return

static func _ensure_voices(tree: SceneTree) -> void:
	if not voices.is_empty():
		return
	for index: int in range(VOICES):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		# Durante el _ready de la escena inicial la raíz todavía está armando
		# hijos y add_child falla; diferido entra sin error en el mismo frame.
		tree.root.call_deferred("add_child", player)
		voices.append(player)

## Carga los WAV y crea las voces al arrancar: el primer toque no espera a leer el disco
## (en Android esa lectura se notaba como retraso del primer sonido de cada tipo).
static func warm_up() -> void:
	for path: String in [CLICK, HOVER, MOVE, BACK]:
		load_stream(path)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and DisplayServer.get_name() != "headless":
		_ensure_voices(tree)

static func click() -> void:
	play(load_stream(CLICK), 0.0)

static func hover() -> void:
	play(load_stream(HOVER), -12.0)

## Cambio de foco con teclado o mando: láser corto.
static func move() -> void:
	play(load_stream(MOVE), 0.0)

static func back() -> void:
	play(load_stream(BACK), -4.0)

## Conecta los sonidos a un botón ya creado.
static func attach(button: BaseButton) -> void:
	if button == null:
		return
	# En pantallas táctiles cada toque también "entra" y enfoca el botón: roce y láser
	# sonarían encima del clic, así que allí solo suena el clic.
	if not DisplayServer.is_touchscreen_available():
		button.mouse_entered.connect(hover)
		button.focus_entered.connect(move)
	# Suena al apretar, no al soltar: con el dedo, esperar a levantarlo se percibe como retraso.
	button.button_down.connect(click)
