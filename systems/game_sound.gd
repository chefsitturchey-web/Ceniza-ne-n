class_name GameSound
extends Node
## Audio de sesión: voces acotadas y música sincronizada por capas.
const CUES: Dictionary = {
	"slash": preload("res://assets/audio/sfx/8bit/combate/slash.wav"),
	"shot": preload("res://assets/audio/sfx/8bit/combate/shot.wav"),
	"hit": preload("res://assets/audio/sfx/8bit/combate/hit.wav"),
	"step": preload("res://assets/audio/sfx/8bit/combate/step.wav"),
	"dodge": preload("res://assets/audio/sfx/8bit/combate/dodge.wav"),
	"alarm": preload("res://assets/audio/sfx/8bit/combate/alarm.wav"),
	"upgrade": preload("res://assets/audio/sfx/8bit/combate/upgrade.wav"),
	"destroy": preload("res://assets/audio/sfx/8bit/combate/destroy.wav"),
	"dash": preload("res://assets/audio/sfx/8bit/combate/dash.wav"),
	"dash_caldera": preload("res://assets/audio/sfx/8bit/combate/dash_caldera.wav"),
	"denied": preload("res://assets/audio/sfx/8bit/economia/denied.wav"),
	"pickup": preload("res://assets/audio/sfx/8bit/economia/pickup.wav"),
	"build_order": preload("res://assets/audio/sfx/8bit/economia/build_order.wav"),
	"build_done": preload("res://assets/audio/sfx/8bit/economia/build_done.wav"),
	"repair": preload("res://assets/audio/sfx/8bit/economia/repair.wav"),
	"overload": preload("res://assets/audio/sfx/8bit/hitos/overload.wav"),
	"portal_destroyed": preload("res://assets/audio/sfx/8bit/hitos/portal_destroyed.wav"),
	"boss_phase": preload("res://assets/audio/sfx/8bit/hitos/boss_phase.wav"),
	"player_death": preload("res://assets/audio/sfx/8bit/hitos/player_death.wav"),
	"respawn": preload("res://assets/audio/sfx/8bit/hitos/respawn.wav"),
	"ui_click": preload("res://assets/audio/sfx/8bit/interfaz/ui_click.wav"),
	"ui_hover": preload("res://assets/audio/sfx/8bit/interfaz/ui_hover.wav"),
	"ui_move": preload("res://assets/audio/sfx/8bit/interfaz/ui_move.wav"),
	"ui_back": preload("res://assets/audio/sfx/8bit/interfaz/ui_back.wav"),
	"dialogue": preload("res://assets/audio/sfx/8bit/voz/dialogue.wav")
}
const VOICES: int = 12
var district: Node2D
var voices: Array[AudioStreamPlayer] = []
var music: Array[AudioStreamPlayer] = []
var warning_player: AudioStreamPlayer = AudioStreamPlayer.new()
var outcome: AudioStreamPlayer = AudioStreamPlayer.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var band: int = -1
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
	rng.seed = get_instance_id() * 2654435761 + Time.get_ticks_usec()
	for player: AudioStreamPlayer in [warning_player, outcome]:
		player.bus = &"Music"
		player.volume_db = -60.0
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
	if music_enabled:
		# Sin distrito no hay colonia: el audio corresponde a una arena de jefe.
		_add_music_player(MusicLibrary.boss_for(rng) if district == null else MusicLibrary.day_for(district.zone.id, rng))
		if district != null:
			_add_music_player(MusicLibrary.NIGHT)
		for track: AudioStreamPlayer in music:
			if playback_enabled:
				track.play()
	if district == null:
		return
	district.player.state_changed.connect(_player_state)
	district.player.stepped.connect(func(origin: Vector2) -> void: play_world("step", origin, -18))
	district.player.hitbox.hit.connect(func(target: HurtboxComponent, _amount: int) -> void: play_world("hit", target.actor.global_position, -6))
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

func play_world(id: String, origin: Vector2, gain_db: float = 0.0) -> void:
	if district == null:
		return
	var distance: float = absf(origin.x - district.player.position.x)
	if distance < 480:
		play_cue(id, -distance / 35.0 + gain_db)

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

func _add_music_player(stream: AudioStream) -> void:
	var layer: AudioStreamPlayer = AudioStreamPlayer.new()
	layer.stream = stream
	layer.bus = &"Music"
	layer.volume_db = -60.0
	add_child(layer)
	music.append(layer)

func play_warning() -> void:
	if not playback_enabled or muted or warning_player.playing:
		return
	warning_player.stream = MusicLibrary.WARNING
	warning_player.volume_db = -10.0
	warning_player.play()

func play_outcome(victory: bool) -> void:
	for player: AudioStreamPlayer in music:
		player.stop()
		player.volume_db = -60.0
	if not playback_enabled or muted:
		return
	outcome.stream = MusicLibrary.VICTORY if victory else MusicLibrary.DEFEAT
	outcome.volume_db = -8.0
	outcome.play()

func _process(delta: float) -> void:
	elapsed += delta
	if music.size() == 1:
		# Arena de jefe: un solo tema, sin mezcla por fases.
		var single_db: float = -18.0 if get_tree().paused else -12.0
		music[0].volume_db = move_toward(music[0].volume_db, -60.0 if muted else single_db, delta * 12.0)
		return
	if music.size() != 2:
		return
	var intensity: float = 1.0
	if district != null:
		intensity = 1.0 if district.cycle.phase == "NOCHE" else (0.4 if district.cycle.phase == "AVISO" else 0.0)
	if district != null and district.expedition.active:
		intensity = 1.0
	var quiet: bool = get_tree().paused or (district != null and district.session.finished)
	var base_db: float = -24.0 if quiet else -12.0
	# Cruce por fase: un tema audible a la vez, sin exigir duraciones iguales.
	var day_db: float = -60.0
	var night_db: float = -60.0
	if intensity < 0.05:
		day_db = base_db
	elif intensity < 0.95:
		day_db = -18.0
		night_db = -17.0
	else:
		night_db = base_db
	var current_band: int = 0 if intensity < 0.05 else (1 if intensity < 0.95 else 2)
	if current_band == 1 and band == 0:
		play_warning()
	band = current_band
	music[0].volume_db = move_toward(music[0].volume_db, -60.0 if muted else day_db, delta * 20.0)
	music[1].volume_db = move_toward(music[1].volume_db, -60.0 if muted else night_db, delta * 20.0)
