extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	await process_frame
	var manager: ExpeditionManager = world.expedition
	load("res://tests/game_fixture.gd").stabilize(world)
	var station: RailwayStation = manager.station
	verify(not manager.can_travel() and not manager.start(), "No viajar sin tren")
	verify(world.defenses.nearest_enemy(-880, 50) == null, "Defensas ignoran repetidores")
	for repeater: EnemyRepeater in manager.repeaters:
		verify(not repeater.is_in_group(GameRules.ENEMIES), "Repetidores fuera de oleadas")
		repeater.hurtbox.receive(50)
		verify(repeater.health.current == 250, "Asalto de tropas golpea torre")
		repeater.hurtbox.receive(250)
		verify(repeater.health.current == 0, "Destruir torre")
		if repeater == manager.repeaters[0]:
			verify(not station.unlocked, "Una torre no activa tren")
	verify(station.unlocked and not station.train_arrived, "Ambas torres activan llegada")
	verify(not manager.can_travel(), "No viajar mientras llega")
	for step: int in range(200):
		station._process(0.1)
	verify(station.train_arrived and station.train_x == 0, "Tren frena en estacion")
	for phase: String in ["AVISO", "NOCHE"]:
		world.cycle.phase = phase
		verify(not manager.start(), "No viajar durante " + phase)
	world.cycle.phase = "DÍA"
	world.cycle.phase_remaining = 7.25
	world.player.position.x = 560
	world.player.health = 73
	world.player.stamina = 41
	var timer: float = world.cycle.phase_remaining
	var cargo: float = world.colony.workers[1].gather
	var hud_time: float = world.get_node("HUD").elapsed
	verify(manager.start(), "Iniciar expedicion de dia")
	verify(manager.arena.player.health == 73 and manager.arena.player.stamina == 41, "Arena hereda vida y resistencia")
	verify(manager.arena.player.attack_damage == world.player.attack_damage, "Arena hereda dano de la hoja")
	verify(not manager.start(), "Evitar expediciones duplicadas")
	verify(not world.get_node("HUD").visible and not world.session.can_process(), "Ocultar HUD y suspender sesion ALWAYS")
	verify(not world.player.can_process() and not station.can_process(), "Suspender actores y tren")
	await process_frame
	await physics_frame
	world.session._process(2)
	verify(world.cycle.phase_remaining == timer and world.colony.workers[1].gather == cargo, "Colonia conserva tiempo y trabajo")
	verify(world.get_node("HUD").elapsed == hud_time, "HUD congelado")
	manager.resolve(false)
	verify(not manager.active and world.visible and world.get_node("HUD").visible, "Derrota reanuda misma colonia")
	verify(world.cycle.phase_remaining == timer and world.session.process_mode == Node.PROCESS_MODE_ALWAYS, "Restaurar tiempo y modo original")
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = "user://expedition_test.json"
	world.session.add_child(save)
	verify(save.save_game(), "Guardar objetivos")
	manager.restore({})
	verify(not station.unlocked, "Restablecer objetivos")
	verify(save.load_game() and manager.all_destroyed() and station.train_arrived, "Cargar torres y tren")
	var legacy: Dictionary = save._snapshot()
	legacy.erase("expedition")
	var file: FileAccess = FileAccess.open(save.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	verify(save.load_game() and not manager.all_destroyed() and not station.unlocked, "Version 1 sin campos nuevos")
	verify(not ExpeditionManager.valid({"destroyed": [false, false], "train_arrived": true}), "Rechazar tren sin objetivos")
	manager.restore({"destroyed": [true, true], "train_arrived": false})
	verify(save.save_game(), "Guardar tren en camino")
	manager.restore({})
	verify(save.load_game() and station.unlocked and not station.train_arrived, "Reanudar llegada pendiente")
	station.restore(true, true)
	verify(manager.start(), "Segunda expedicion")
	manager.resolve(true)
	verify(manager.active and manager.arena.completed and not world.session.can_process(), "Victoria muestra distrito completado")
	manager.resolve(false)
	save.delete_save()
	world.free()
	await process_frame
	print("Expedicion: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
