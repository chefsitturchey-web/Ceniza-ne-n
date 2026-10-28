extends SceneTree

const PATH: String = "user://campaign_test.json"
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func screenshot(name: String) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/campaign/" + name + ".png")

func arena_for(index: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
	arena.zone_index = index
	root.add_child(arena)
	arena.boss.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.set_process(false)
	return arena

func freeze(world: District) -> void:
	if world.briefing != null:
		world.briefing.close_panel()
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.modules.set_physics_process(false)
	world.director.set_process(false)

func ready_train(world: District) -> void:
	load("res://tests/game_fixture.gd").stabilize(world)
	world.expedition.restore({"destroyed": [true, true], "train_arrived": true})
	world.cycle.phase = "DÍA"
	world.player.health = 100
	verify(world.expedition.start(), "Viaje al jefe del distrito %d" % world.zone_index)
	world.expedition.arena.boss.set_physics_process(false)
	world.expedition.arena.modules.set_physics_process(false)

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/campaign"))
	GamePreferences.current().briefing_requested = false
	CampaignRoute.pending.clear()
	for index: int in range(3):
		verify(CampaignRoute.valid_state(CampaignRoute.initial_state(index)), "Ruta válida %d" % index)
	verify(not CampaignRoute.valid_state({"zone": 1, "cleared": [false, false, false]}), "Rechaza progreso incoherente")
	verify(not CampaignRoute.valid_state({"zone": 3, "cleared": [true, true, true]}), "Rechaza distrito desconocido")
	verify(not CampaignRoute.valid_state({"zone": 1.5, "cleared": [true, false, false]}), "Rechaza índice fraccionario")

	var arena: RecaudadorArena = arena_for(1)
	var boiler: SantaCaldera = arena.boss as SantaCaldera
	await physics_frame
	verify(boiler != null and boiler.max_health == 8500, "Fundición crea Santa Caldera")
	verify(boiler.receive_hit(Vector2.ZERO, 100) == 35, "Armadura reduce daño al 35 por ciento")
	boiler.prepare_heat()
	verify(boiler.heat_areas.size() == 3 and boiler.timer == 1.2, "Tres franjas con aviso de 1.2 segundos")
	arena.player.position = boiler.heat_areas[0].get_center()
	boiler._physics_process(1.0)
	verify(arena.player.health == 100, "Aviso de rejillas no causa daño")
	await screenshot("caldera_aviso")
	boiler._physics_process(0.21)
	boiler._physics_process(0.01)
	verify(arena.player.health == 82, "Rejilla activa causa daño")
	arena.player.invulnerable = 0
	arena.player.dodge()
	boiler._physics_process(0.4)
	verify(arena.player.health == 82, "Esquiva protege del calor")
	boiler._physics_process(2.3)
	verify(boiler.core_exposed and boiler.heat_areas.is_empty(), "Purga abre núcleo y elimina las franjas")
	verify(boiler.receive_hit(Vector2.ZERO, 50) == 100, "Caldera expuesta recibe daño doble")
	boiler.phase = 2
	boiler.prepare_heat()
	verify(boiler.timer == 0.95 and boiler.heat_areas[0].size.y == 65, "Segunda fase alterna franjas y conserva aviso")
	boiler.change_state(Recaudador.State.RECOVER, 0)
	boiler._physics_process(0.01)
	verify(boiler.state == Recaudador.State.VOLLEY_WINDUP, "Abanico también avisa antes de disparar")
	var fired: Array[Vector2] = []
	boiler.fired.connect(func(_origin: Vector2, direction: Vector2) -> void: fired.append(direction))
	boiler._physics_process(0.81)
	for step: int in range(20):
		boiler._physics_process(0.1)
	verify(fired.size() == 21, "Tres abanicos de siete proyectiles en segunda fase")
	boiler.change_state(Recaudador.State.RECOVER, 4)
	boiler.machine._process(0.1)
	verify(boiler.machine.opening > 0 and boiler.machine.opening < 1, "Compuertas abren progresivamente")
	boiler.prepare_heat()
	boiler.change_state(Recaudador.State.RECOVER, 4)
	boiler.receive_hit(Vector2.ZERO, boiler.max_health)
	verify(boiler.health == 0 and boiler.heat_areas.is_empty() and arena.ending and not arena.modules.is_physics_processing(), "Muerte de Caldera limpia calor y detiene módulos")
	arena.free()
	await process_frame

	arena = arena_for(2)
	var choir: CoroSumergido = arena.boss as CoroSumergido
	await physics_frame
	verify(choir != null and choir.active_links() == 3, "Coro instala tres antenas")
	verify(choir.receive_hit(Vector2.ZERO, 1000) == 0, "Enlaces bloquean daño al cuerpo")
	var relay: ChoirRelay = choir.relays[2]
	arena.strike(relay.position + Vector2.DOWN * 40, Vector2.DOWN, 180, 42)
	verify(relay.health == 180, "Antenas respetan dirección de ataque")
	arena.strike(relay.position + Vector2.DOWN * 100, Vector2.UP, 180, 42)
	verify(relay.health == 180, "Antenas respetan alcance")
	arena.strike(relay.position + Vector2.DOWN * 40, Vector2.UP, 180, 42)
	verify(relay.health == 0 and choir.active_links() == 2, "Golpe manual rompe enlace cercano")
	choir.pulse_timer = 100
	choir.mark_timer = 100
	choir.add_marks()
	choir._physics_process(0.8)
	verify(arena.player.health == 100, "Marcas avisan antes de impactar")
	await screenshot("coro_marcas")
	choir._physics_process(0.11)
	verify(arena.player.health == 78, "Marca inmóvil impacta tras el aviso")
	choir._physics_process(0.1)
	verify(arena.player.health == 78, "Cada marca impacta una sola vez")
	choir.marks.clear()
	arena.player.invulnerable = 0
	arena.player.position = choir.position + Vector2.DOWN * 120
	choir.waves.append({"radius": 90.0, "hit": false})
	choir._physics_process(0.4)
	verify(arena.player.health == 62, "Pulso detecta cruce del radio incluso con delta grande")
	choir.waves.clear()
	arena.player.invulnerable = 0
	arena.player.dodge_remaining = 0
	arena.player.stamina = 100
	arena.player.dodge()
	choir.waves.append({"radius": 90.0, "hit": false})
	choir._physics_process(0.4)
	verify(arena.player.health == 62, "Esquiva protege del pulso")
	for link: ChoirRelay in choir.relays:
		if link.health > 0:
			arena.strike(link.position + Vector2.DOWN * 35, Vector2.UP, 180, 42)
	verify(choir.core_exposed and choir.exposure_left == 6.0, "Romper tres enlaces abre ventana de seis segundos")
	verify(choir.marks.is_empty() and choir.waves.is_empty(), "Ventana elimina peligros anteriores")
	verify(choir.receive_hit(Vector2.ZERO, 50) == 100, "Coro abierto recibe daño doble")
	choir.phase = 2
	choir._physics_process(6.01)
	verify(choir.active_links() == 3 and choir.relays[0].health == 150 and not choir.core_exposed, "Rearma enlaces más débiles en segunda fase")
	arena.player.health = 100
	arena.player.invulnerable = 100
	for step: int in range(2000):
		choir._physics_process(0.1)
	verify(choir.waves.size() <= 6 and choir.marks.size() <= 10, "Peligros se eliminan y no crecen indefinidamente")
	choir.exposure_left = 1
	choir.receive_hit(Vector2.ZERO, choir.max_health)
	verify(choir.health == 0 and choir.waves.is_empty() and choir.marks.is_empty() and choir.active_links() == 0, "Muerte del Coro limpia pulsos marcas y antenas")
	arena._process(2.3)
	verify(arena.completed, "Escena independiente muestra victoria sin colonia")
	current_scene = arena
	for child: Node in arena.get_children():
		if child is Button and child.text == "Volver al menú":
			child.pressed.emit()
	await process_frame
	await process_frame
	verify(current_scene is MainMenu, "Botón de victoria independiente vuelve al menú")
	current_scene.free()
	current_scene = null
	await process_frame

	var world: District = load(CampaignRoute.SCENES[0]).instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	current_scene = world
	freeze(world)
	verify(world.player.speed == 220 and world.player.attack_damage == 50 and world.cycle.config.day_duration == 180, "Conserva personaje y ofrece preparación de colonia")
	world.neural.kills = 60
	verify(world.neural.install("blade") and world.neural.upgrade_module("tesla"), "Prepara mejoras para traslado")
	world.colony.add_worker(&"collector")
	var portable: Dictionary = CampaignRoute.handoff(1, world.neural.snapshot(), 999, world.colony.workers)
	verify(CampaignRoute.valid_handoff(portable) and portable.scrap == 130, "Traslado válido limita excedente a cuarenta")
	var invalid: Dictionary = portable.duplicate(true)
	invalid.scrap = 131
	verify(not CampaignRoute.valid_handoff(invalid), "Rechaza presupuesto de traslado manipulado")
	invalid = portable.duplicate(true)
	invalid.crew = ["builder", "builder"]
	verify(not CampaignRoute.valid_handoff(invalid), "Rechaza traslado sin recuperador")
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = PATH
	world.session.add_child(save)
	world.session.save_system = save
	world.session.persistence_enabled = true
	var legacy: Dictionary = save._snapshot()
	legacy.erase("campaign")
	verify(save.write_document(legacy) and save.load_game(), "Guardado anterior sin campaña sigue funcionando")
	verify(not save.save_handoff(CampaignRoute.handoff(2, world.neural.snapshot(), 0, world.colony.workers)), "Impide saltar directamente al tercer distrito")
	ready_train(world)
	world.expedition.resolve(true)
	verify(SaveSystem.checkpoint_info(PATH).get("zone") == 1, "Victoria guarda llegada a Fundición antes de pulsar viajar")
	var first: String = FileAccess.get_file_as_string(PATH)
	world.expedition.resolve(true)
	verify(FileAccess.get_file_as_string(PATH) == first, "Resolver victoria dos veces no repite el avance")
	world.expedition.continue_district()
	await process_frame
	await process_frame
	await process_frame
	world = current_scene as District
	verify(world != null and world.zone_index == 1, "Botón viajar cambia a escena real de Fundición")
	freeze(world)
	verify(world.bank.scrap >= 90 and world.bank.scrap <= 130 and world.colony.workers.size() == 3, "Nueva colonia conserva habitantes y presupuesto")
	verify(world.neural.ranks.blade == 1 and world.modules.levels.tesla == 1 and world.player.neural_damage == 10, "Mejoras y módulos sobreviven al viaje")
	verify(world.cycle.config.day_duration == 180 and world.construction.sites[0].data.offset in [300.0, 220.0], "Fundición usa preparación y geometría propias")
	verify(world.session.save_system.save_path == PATH and not CampaignRoute.pending.has("campaign"), "Consume traslado y conserva ruta del guardado")
	verify(world.session.save_system.save_game() and world.session.save_system.load_game(), "Guardado completo de segunda zona admite ida y vuelta")
	var protected_save: String = FileAccess.get_file_as_string(PATH)
	var preview: District = load(CampaignRoute.SCENES[0]).instantiate() as District
	var preview_session: SessionController = preview.get_node("Session") as SessionController
	var preview_save: SaveSystem = SaveSystem.new()
	preview_save.save_path = PATH
	preview_session.add_child(preview_save)
	preview_session.save_system = preview_save
	root.add_child(preview)
	preview.session.on_phase_changed("DÍA", 1)
	verify(preview.session.save_system == null and not preview.session.persistence_enabled and FileAccess.get_file_as_string(PATH) == protected_save, "Abrir otra zona con F6 conserva checkpoint incluso en viajes posteriores")
	preview.free()
	world.get_node("Player/Camera2D").make_current()
	world.cycle.phase = "NOCHE"
	world.player.position = Vector2(400, GameRules.FLOOR_Y)
	world.player.invulnerable = 0
	world.session.terrain.tick(0.5)
	verify(world.player.health == 100 and world.session.terrain.heat_stage() == 1, "Primera rejilla nocturna siempre comienza con aviso")
	world.session.terrain.tick(0.8)
	verify(world.player.health == 82, "Rejillas laterales activas causan daño")
	world.cycle.phase = "DÍA"
	world.session.terrain.tick(0.01)
	verify(world.session.terrain.heat_stage() == 0, "Rejillas descansan durante el día")
	await screenshot("fundicion")
	world.session.finish(false)
	verify(FileAccess.file_exists(PATH), "Derrota posterior conserva último amanecer")
	world.session.restart()
	await process_frame
	await process_frame
	world = current_scene as District
	freeze(world)
	verify(world.zone_index == 1 and not world.session.finished and world.neural.ranks.blade == 1, "Reintentar segunda zona restaura su guardado")
	ready_train(world)
	verify(world.expedition.arena.boss is SantaCaldera, "Tren de Fundición conduce a su jefe")
	world.expedition.resolve(true)
	world.expedition.leave_to_menu()
	await process_frame
	await process_frame
	var menu: MainMenu = current_scene as MainMenu
	menu.checkpoint_path = PATH
	menu.refresh_checkpoint()
	verify(not menu.continue_button.disabled and "Barrio inundado" in menu.status.text, "Menú reconoce checkpoint de llegada al tercer distrito")
	menu.continue_button.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	world = current_scene as District
	freeze(world)
	verify(world.zone_index == 2 and world.cycle.config.day_duration == 180, "Segunda victoria conduce al Barrio inundado")
	world.player.set_physics_process(true)
	world.player.position = Vector2(400, GameRules.FLOOR_Y)
	await physics_frame
	await physics_frame
	await process_frame
	world.player._physics_process(0.016)
	world.session.terrain.tick(0.01)
	verify(is_equal_approx(world.player.terrain_speed_factor, 0.82), "Charcos frenan pasos sobre el suelo")
	world.player.position.x = 0
	world.session.terrain.tick(0.01)
	verify(world.player.terrain_speed_factor == 1.0, "Salir del agua restaura velocidad")
	world.player.set_physics_process(false)
	await screenshot("barrio_inundado")
	ready_train(world)
	verify(world.expedition.arena.boss is CoroSumergido, "Tren del Barrio conduce al Coro")
	world.expedition.resolve(true)
	verify(not FileAccess.file_exists(PATH) and world.expedition.arena.completed, "Última victoria termina los tres distritos y retira checkpoint")
	world.expedition.leave_to_menu()
	await process_frame
	await process_frame
	verify(current_scene is MainMenu, "Campaña completada permite volver al menú")
	current_scene.free()
	current_scene = null
	await process_frame
	print("Campaña y jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
