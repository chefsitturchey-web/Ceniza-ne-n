extends SceneTree

const TEST_PATH: String = "user://partida_test.json"
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func create_world() -> District:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	var session: SessionController = world.get_node("Session") as SessionController
	session.save_system = SaveSystem.new()
	session.save_system.save_path = TEST_PATH
	session.add_child(session.save_system)
	root.add_child(world)
	session.set_process(false)
	world.player.set_physics_process(false)
	return world

func write_file(contents: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(contents)
	file.close()

func run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var world: District = create_world()
	var save: SaveSystem = world.session.save_system
	verify(save.has_save(), "El primer día se guarda automáticamente")
	world.cycle.day = 2
	world.bank.scrap = 123
	world.bank.energy_capacity = 9
	world.core.health = 210
	world.player.health = 63
	world.player.position.x = -110
	world.player.stamina = 48
	world.colony.add_worker(&"builder")
	world.colony.add_worker(&"collector")
	world.colony.workers[1].cargo = 8
	world.colony.workers[1].x = -150
	world.colony.workers[3].gather = 1.5
	world.construction.sites[0].hp = 71
	world.construction.sites[0].ordered = true
	world.construction.sites[0].progress = 1.25
	world.colony.workers[0].job = 0
	world.construction.sites[1].hp = 42
	world.construction.sites[3].ordered = true
	world.overload.cooldown_left = 5
	verify(save.save_game(), "Guardar estado con obras y habitantes")
	var expected: String = JSON.stringify(save._snapshot())
	world.bank.scrap = 0
	world.player.health = 1
	world.core.health = 1
	world.cycle.day = 3
	world.construction.sites[0].complete_work()
	world.colony.workers[1].cargo = 0
	world.overload.cooldown_left = 0
	verify(save.load_game(), "Cargar instantánea válida")
	verify(JSON.stringify(save._snapshot()) == expected, "Ida y vuelta conserva todo el estado")
	verify(world.bank.energy_used() == 4, "Energía usada se deriva de torretas y reservas")
	world.free()
	world = create_world()
	save = world.session.save_system
	verify(JSON.stringify(save._snapshot()) == expected, "Reabrir restaura sin duplicar habitantes ni premios")
	verify(world.cycle.phase_remaining == world.cycle.config.day_duration, "Reanudar al inicio del día conservando duración de pruebas")
	for corrupt: String in ["{roto", "[]", '{"version":99}', '{"version":1}']:
		write_file(corrupt)
		verify(not save.load_game(), "Rechazar JSON corrupto, incompleto o versión desconocida")
		verify(JSON.stringify(save._snapshot()) == expected, "Un fallo no modifica parcialmente el estado")
	var invalid: Dictionary = save._snapshot()
	invalid.workers[0].job = 999
	write_file(JSON.stringify(invalid))
	verify(not save.load_game(), "Rechazar referencias de obra fuera de rango")
	invalid = save._snapshot()
	invalid.version = 2
	write_file(JSON.stringify(invalid))
	verify(not save.load_game(), "Rechazar versión desconocida con datos completos")
	world.free()
	world = create_world()
	save = world.session.save_system
	verify(world.cycle.day == 1 and world.bank.scrap == GameRules.INITIAL_SCRAP, "Archivo inválido inicia partida nueva")
	world.cycle.day = 1
	world.cycle.phase = "NOCHE"
	world.cycle.phase_remaining = 0
	world.director.start(1)
	world.director.spawn_count = world.director.wave.enemies.size()
	var scrap: int = world.bank.scrap
	world.cycle.update_phase(0)
	verify(world.cycle.day == 2 and world.presenter.notice == "Partida guardada", "Autoguardado y aviso al amanecer")
	world.bank.scrap = 0
	verify(save.load_game() and world.bank.scrap == scrap + world.cycle.config.dawn_scrap, "Guardar después de recompensas del amanecer")
	world.session.finish(false)
	verify(not save.has_save(), "Derrota elimina guardado")
	world.session.finished = false
	verify(save.save_game(), "Preparar guardado para victoria")
	world.session.win()
	verify(not save.has_save(), "Victoria elimina guardado")
	save.delete_save()
	verify(not save.load_game(), "Archivo ausente se ignora")
	world.free()
	print("Guardado: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
