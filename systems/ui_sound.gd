class_name UiSound
extends RefCounted
## Sonidos de interfaz compartidos por menús y paneles.
## Crea sus propios reproductores bajo la raíz: no necesita autoload ni referencias.

const CLICK: AudioStream = preload("res://assets/audio/sfx/8bit/interfaz/ui_click.wav")
const HOVER: AudioStream = preload("res://assets/audio/sfx/8bit/interfaz/ui_hover.wav")
const MOVE: AudioStream = preload("res://assets/audio/sfx/8bit/interfaz/ui_move.wav")
const BACK: AudioStream = preload("res://assets/audio/sfx/8bit/interfaz/ui_back.wav")
const VOICES: int = 3

static var voices: Array[AudioStreamPlayer] = []

static func play(stream: AudioStream, gain_db: float = -8.0) -> void:
	if stream == null or DisplayServer.get_name() == "headless":
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if voices.is_empty():
		for index: int in range(VOICES):
			var player: AudioStreamPlayer = AudioStreamPlayer.new()
			player.bus = &"SFX"
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			tree.root.add_child(player)
			voices.append(player)
	for player: AudioStreamPlayer in voices:
		if not player.playing:
			player.stream = stream
			player.volume_db = gain_db
			player.play()
			return

static func click() -> void:
	play(CLICK)

static func hover() -> void:
	play(HOVER, -18.0)

## Cambio de foco con teclado o mando: láser corto.
static func move() -> void:
	play(MOVE, -6.0)

static func back() -> void:
	play(BACK, -10.0)

## Conecta los sonidos a un botón ya creado.
static func attach(button: BaseButton) -> void:
	if button == null:
		return
	button.mouse_entered.connect(hover)
	button.focus_entered.connect(move)
	button.pressed.connect(click)
