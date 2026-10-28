extends SceneTree

var checks: int = 0
var failures: int = 0
var world: District

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	world = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	await process_frame
	var neural: NeuralSystem = world.neural
	verify(neural.points() == 0 and not neural.install("blade"), "No se compran mejoras sin datos")
	var data: EnemyData = load("res://data/enemies/errante.tres")
	for index: int in range(6):
		var enemy: SiegeEnemy = world.director.spawn_enemy(-1, data)
		enemy.take_damage(10000)
		enemy.take_damage(10000)
	verify(neural.kills == 6 and neural.points() == 1, "Las muertes reales dan datos una sola vez")
	verify(not neural.install("inexistente") and neural.points() == 1, "Una mejora desconocida no consume puntos")
	verify(neural.install("blade") and world.player.neural_damage == 10, "Filo instalado")
	verify(world.player.attack_damage == 50 and world.player.speed == 220, "Se conservan ajustes del Inspector")
	var target: TrainingEnemy = TrainingEnemy.new()
	target.position = world.player.position + Vector2(24, 0)
	world.add_child(target)
	world.player.facing = 1
	world.player.attack()
	verify(target.health == 40, "El golpe real suma 10 al daño base de 50")
	target.free()
	var arena_player: TopdownPlayer = TopdownPlayer.new()
	arena_player.copy_from(world.player)
	verify(arena_player.attack_damage == 60, "La arena hereda el filo")
	root.add_child(arena_player)
	arena_player.free()
	for index: int in range(48):
		neural.recover_data(3)
	for id: String in NeuralSystem.IDS:
		while neural.ranks[id] < 3:
			verify(neural.install(id), "Instalar rango disponible: " + id)
	verify(neural.points() == 0 and not neural.install("blade"), "Límite de tres rangos y sin saldo negativo")
	verify(world.defenses.drone_rank == 3 and world.player.neural_regen == 15, "Dron y capacitor aplicados")
	var drone_target: SiegeEnemy = world.director.spawn_enemy(1, data)
	drone_target.position = world.player.position + Vector2(80, 0)
	world.defenses.drone_timer = 0
	world.defenses.update_defenses(0)
	verify(drone_target.health == 100 - GameRules.DRONE_DAMAGE - 12, "El disparo real del dron suma el daño instalado")
	verify(is_equal_approx(world.defenses.drone_timer, GameRules.DRONE_INTERVAL * 0.7), "La mejora reduce el intervalo del dron")
	drone_target.take_damage(10000)
	var capacitor_player: TopdownPlayer = TopdownPlayer.new()
	capacitor_player.copy_from(world.player)
	root.add_child(capacitor_player)
	capacitor_player.set_physics_process(false)
	capacitor_player.stamina = 20
	InputSetup.add_action("arena_up", KEY_W, JOY_BUTTON_DPAD_UP)
	InputSetup.add_action("arena_down", KEY_S, JOY_BUTTON_DPAD_DOWN)
	capacitor_player._physics_process(0.1)
	verify(is_equal_approx(capacitor_player.stamina, 23.7), "Regeneración real del capacitor en la arena")
	capacitor_player.free()
	var saved: Dictionary = neural.snapshot()
	verify(NeuralSystem.valid(saved), "Estado neuronal válido")
	for invalid: Variant in [null, [], {"kills": -1, "ranks": {}}, {"kills": 0, "ranks": {"blade": 1, "drone": 0, "capacitor": 0}}, {"kills": 100, "ranks": {"blade": 4, "drone": 0, "capacitor": 0}}]:
		verify(not NeuralSystem.valid(invalid), "Rechazo de datos neuronales corruptos")
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = "user://neural_test.json"
	world.session.add_child(save)
	verify(save.save_game(), "Guardar mejoras")
	neural.restore({})
	verify(save.load_game() and neural.snapshot() == saved, "Restaurar mejoras y datos")
	var old: Dictionary = save._snapshot()
	old.erase("neural")
	var file: FileAccess = FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	verify(save.load_game() and neural.kills == 0 and world.player.neural_damage == 0, "Guardados anteriores cargan sin mejoras inventadas")
	save.delete_save()
	world.player.position.x = -110
	verify(world.interaction.interaction_target() == InteractionSystem.CLINIC_TARGET, "La clínica no solapa la interacción del núcleo")
	verify(world.interaction.perform_interaction(InteractionSystem.CLINIC_TARGET) and paused, "Abrir clínica pausa el mundo")
	verify(world.clinic_panel.buttons.size() == 3, "Tres elecciones accesibles")
	Input.action_press("pause")
	var escape: InputEventAction = InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	world.clinic_panel._input(escape)
	world.session._process(0)
	Input.action_release("pause")
	verify(not paused and not world.clinic_panel.opened, "Cerrar devuelve el control")
	world.cycle.phase = "NOCHE"
	verify(not world.clinic_panel.open_panel() and not paused, "No se abre durante el asedio")
	verify(world.sound.voices.size() == GameSound.VOICES, "Pool de sonido acotado")
	verify(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "Buses de mezcla separados")
	for cue: AudioStream in GameSound.CUES.values():
		verify(cue.get_length() > 0 and cue.get_length() < 1.2, "Efecto breve y decodificable, sin colas largas")
	verify(absf(GameSound.MUSIC[0].get_length() - GameSound.MUSIC[1].get_length()) < 0.01, "Stems de igual duración")
	verify((GameSound.MUSIC[0] as AudioStreamOggVorbis).loop and (GameSound.MUSIC[1] as AudioStreamOggVorbis).loop, "Música en bucle")
	if "--capture" in OS.get_cmdline_user_args():
		world.cycle.phase = "NOCHE"
		world.view.light = DistrictView.LIGHTING["NOCHE"].duplicate()
		world.view.daylight.color = world.view.light.world
		world.player.position.x = -110
		world.view.queue_redraw()
		world.presenter.publish()
		for index: int in range(5):
			await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/neural-night.png")
		world.cycle.phase = "DÍA"
		world.clinic_panel.open_panel()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/neural-clinic.png")
		world.clinic_panel.close_panel()
	world.free()
	await process_frame
	print("Neural y audio: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
