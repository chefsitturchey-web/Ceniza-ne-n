extends SceneTree
## Relevo de música entre día, aviso y noche: nunca suenan dos temas a la vez.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

## Avanza el mezclador y devuelve si en algún momento hubo dos temas audibles.
func run_phase(sound: GameSound, world: District, phase: String, seconds: float) -> bool:
	world.cycle.phase = phase
	var overlap: bool = false
	var step: float = 1.0 / 30.0
	for frame: int in int(seconds / step):
		sound._process(step)
		if sound.music[0].volume_db > GameSound.HANDOFF_DB and sound.music[1].volume_db > GameSound.HANDOFF_DB:
			overlap = true
	return overlap

func run_checks() -> void:
	GamePreferences.current().briefing_requested = false
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var sound: GameSound = world.sound
	sound.set_process(false)
	verify(sound.music.size() == 2, "La colonia carga tema de día y de noche")
	verify(not run_phase(sound, world, "DÍA", 6.0), "De día solo suena un tema")
	verify(sound.music[0].volume_db > -20.0 and sound.music[1].volume_db <= -59.0, "De día suena el tema diurno")
	verify(not run_phase(sound, world, "AVISO", 8.0), "El aviso no mezcla día y noche")
	verify(sound.music[0].volume_db <= GameSound.HANDOFF_DB, "Al anochecer el tema de día se apaga")
	verify(not run_phase(sound, world, "NOCHE", 8.0), "La noche entra cuando el día ya se fue")
	verify(sound.music[1].volume_db > -20.0 and sound.music[0].volume_db <= -59.0, "De noche suena el tema nocturno")
	verify(not run_phase(sound, world, "DÍA", 8.0), "El amanecer tampoco solapa")
	verify(sound.music[0].volume_db > -20.0 and sound.music[1].volume_db <= -59.0, "Al amanecer vuelve el tema de día")
	world.free()
	await process_frame
	print("Relevo de música: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
