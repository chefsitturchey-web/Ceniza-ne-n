class_name GameSound
extends Node
## Audio de sesión: voces acotadas y música sincronizada por capas.
const CUES: Dictionary = {
	"slash": preload("res://assets/audio/sfx/slash.ogg"),
	"shot": preload("res://assets/audio/sfx/shot.ogg"),
	"hit": preload("res://assets/audio/sfx/hit.ogg"),
	"dodge": preload("res://assets/audio/sfx/dodge.ogg"),
	"alarm": preload("res://assets/audio/sfx/alarm.ogg"),
	"upgrade": preload("res://assets/audio/sfx/upgrade.ogg"),
	"destroy": preload("res://assets/audio/sfx/destroy.ogg")
}
const MUSIC: Array[AudioStream] = [preload("res://assets/audio/music/ruinas.ogg"), preload("res://assets/audio/music/asedio.ogg")]
const VOICES: int = 12
var district: Node2D
var voices: Array[AudioStreamPlayer] = []
var music: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var elapsed: float = 0.0
var muted: bool:
	get: return GamePreferences.current().muted
var music_enabled: bool = true
var playback_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# El driver Dummy no consume las voces al cerrar pruebas sin ventana.
	playback_enabled = DisplayServer.get_name() != "headless"
	for index: int in range(VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		voices.append(voice)
	for stream: AudioStream in MUSIC:
		if not music_enabled:
			break
		var layer_player: AudioStreamPlayer = AudioStreamPlayer.new()
		layer_player.stream = stream
		layer_player.bus = &"Music"
		layer_player.volume_db = -60
		add_child(layer_player)
		music.append(layer_player)
	# Ambos stems empiezan en el mismo frame y tienen idéntica duración y tempo.
	for layer_player: AudioStreamPlayer in music:
		if playback_enabled:
			layer_player.play()
	if district == null:
		return
	district.player.state_changed.connect(_player_state)
	district.player.health_component.damaged.connect(func(_a: int, _b: int) -> void: play_cue("hit"))
	district.core.health_component.damaged.connect(func(_a: int, _b: int) -> void: play_cue("alarm"))
	district.defenses.shot_fired.connect(func(origin: Vector2) -> void: play_world("shot", origin))
	district.cycle.phase_changed.connect(func(phase: String, _day: int) -> void:
		if phase != "DÍA": play_cue("alarm"))
	district.director.spawned.connect(_enemy_spawned)
	district.neural.point_earned.connect(func() -> void: play_cue("upgrade"))
	district.overload.notice_requested.connect(func(message: String) -> void:
		if message == "Sobrecarga activa": play_cue("upgrade"))

func _player_state(state: Player.State) -> void:
	if state == Player.State.ATTACK:
		play_cue("slash")
	elif state == Player.State.DODGE:
		play_cue("dodge")

func _enemy_spawned(enemy: Node2D, _side: float) -> void:
	enemy.reward_requested.connect(func(_reward: int) -> void: play_world("destroy", enemy.position))

func play_world(id: String, origin: Vector2) -> void:
	if district == null:
		return
	var distance: float = absf(origin.x - district.player.position.x)
	if distance < 480:
		play_cue(id, -distance / 35.0)

func play_cue(id: String, gain_db: float = 0.0) -> void:
	if not playback_enabled or muted or not CUES.has(id) or elapsed < float(cooldowns.get(id, -1.0)):
		return
	cooldowns[id] = elapsed + (0.1 if id == "shot" else 0.06)
	for voice: AudioStreamPlayer in voices:
		if not voice.playing:
			voice.stream = CUES[id]
			voice.volume_db = -9.0 + gain_db
			voice.pitch_scale = 1.0 + sin(elapsed * 7.3) * 0.035
			voice.play()
			return

func _process(delta: float) -> void:
	elapsed += delta
	if music.size() != 2:
		return
	var intensity: float = 1.0
	if district != null:
		intensity = 1.0 if district.cycle.phase == "NOCHE" else (0.4 if district.cycle.phase == "AVISO" else 0.0)
	if district != null and district.expedition.active:
		intensity = 1.0
	var quiet: bool = get_tree().paused or (district != null and district.session.finished)
	var base_db: float = -24.0 if quiet else -12.0
	music[0].volume_db = move_toward(music[0].volume_db, -60.0 if muted else base_db, delta * 20.0)
	music[1].volume_db = move_toward(music[1].volume_db, -60.0 if muted or intensity == 0 else base_db - 5.0 + intensity * 5.0, delta * 20.0)
