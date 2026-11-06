extends SceneTree
## Ordenes nocturnas, riesgo real y regreso al comportamiento diurno.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func open_world() -> District:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	load("res://tests/game_fixture.gd").stabilize(world)
	world.core.restore({"tier": 2, "ordered": false, "progress": 0})
	world.bank.deposit(500)
	world.bank.stored_parts = 100
	return world

func run_checks() -> void:
	# Cada tipo de orden debe habilitar por si mismo el trabajo nocturno.
	for mode: String in ["construir", "reparar", "mejorar", "despejar", "instalacion", "restaurar", "nucleo"]:
		var world: District = open_world()
		await process_frame
		var colony: ColonySystem = world.colony
		world.cycle.phase = "NOCHE"
		world.cycle.phase_remaining = 100
		verify(not colony.night_active(), mode + ": la noche sola no habilita faenas")
		var notices: Array[String] = []
		colony.notice_requested.connect(func(message: String) -> void: notices.append(message))
		var target: Node2D
		var accepted: bool = false
		if mode in ["construir", "reparar", "mejorar"]:
			var site: ConstructionSite = world.construction.sites[0]
			site.hp = 0 if mode == "construir" else (site.max_hp - 20 if mode == "reparar" else site.max_hp)
			target = site
			accepted = world.construction.order_site(site)
		elif mode == "despejar":
			var plot: ClearanceSite = world.frontier.plots[0]
			plot.cleared = false
			target = plot
			accepted = world.frontier.interact(FrontierSystem.CLEAR_BASE)
		elif mode == "instalacion":
			var site: ExpansionOutpost = world.expansion.sites[0]
			site.hp = 0
			target = site
			accepted = world.expansion.interact(-100)
		elif mode == "restaurar":
			world.settlements.components[0] = 1
			target = world.settlements.sites[0]
			accepted = world.settlements.interact(SettlementSystem.TARGET_BASE)
		else:
			world.core.restore({"tier": 1, "ordered": false, "progress": 0})
			target = world.core
			accepted = world.core.request_upgrade()
		verify(accepted and colony.night_active(), mode + ": una sola orden valida habilita el trabajo")
		verify(notices == ["De noche: tu gente puede morir"] and world.presenter.notice == notices[0], mode + ": aviso visible al aceptar")
		# El constructor llega y trabaja, incluso cerca de un enemigo.
		var worker: ColonyWorker = colony.workers[0]
		worker.x = target.position.x - 35
		var enemy: Node2D = Node2D.new()
		enemy.position = target.position
		enemy.add_to_group(GameRules.ENEMIES)
		world.add_child(enemy)
		var previous_x: float = worker.x
		var previous_hp: int = worker.hp
		for step: int in 10: colony.update_workers(0.1)
		verify(worker.x > previous_x and target.progress > 0, mode + ": llega y avanza la obra de noche")
		verify(worker.hp < previous_hp and not colony.flee_at(worker.x), mode + ": trabajar cerca del enemigo tiene riesgo")
		colony.authorize_night_work()
		verify(notices.size() == 1, mode + ": el aviso no se repite esa noche")
		enemy.free()
		world.free()
		await process_frame

	var world: District = open_world()
	await process_frame
	var colony: ColonySystem = world.colony
	world.cycle.phase = "NOCHE"
	world.bank.scrap = 0
	var site: ConstructionSite = world.construction.sites[0]
	site.hp = 0
	verify(not world.construction.order_site(site) and not colony.night_active() and not colony.night_warned, "Una orden sin recursos no autoriza ni advierte")
	world.bank.deposit(500)
	verify(world.construction.order_site(site), "Se acepta al disponer de recursos")
	var worker: ColonyWorker = colony.workers[0]
	worker.x = -900
	worker.update_visual(worker.x, true)
	verify(worker.is_in_group(GameRules.NIGHT_WORKERS), "El trabajador nocturno es un objetivo enemigo")
	world.player.position.x = 900
	var enemy: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres"))
	enemy.set_physics_process(false)
	enemy.position.x = worker.x - 10
	enemy._physics_process(0.1)
	verify(enemy.target_kind == "ally" and enemy.ally_target == worker, "El enemigo selecciona al trabajador expuesto")
	var hp: int = worker.hp
	enemy.land_hit()
	verify(worker.hp < hp, "El ataque enemigo dana al trabajador")
	var artillery: Raider = world.director.spawn_enemy(-1, load("res://data/enemies/artillero.tres")) as Raider
	artillery.set_physics_process(false)
	artillery.position.x = worker.x - 45
	verify(artillery.choose_special_target(0.1) and artillery.special_target == worker, "El artillero apunta al trabajador nocturno")
	var bolt: RaidBolt = RaidBolt.new()
	bolt.session = world.session
	bolt.position = worker.position + Vector2(-30, -24)
	bolt.direction = 1
	world.add_child(bolt)
	bolt.set_physics_process(false)
	hp = worker.hp
	bolt._physics_process(0.1)
	verify(worker.hp < hp and bolt.spent, "El proyectil enemigo impacta en el trabajador")
	artillery.free()
	var population: int = world.civic.population()
	var corpses: int = world.corpse_system.get_child_count()
	worker.take_damage(GameRules.WORKER_HEALTH)
	colony.update_workers(0.1)
	verify(world.civic.population() == population - 1 and not colony.workers.has(worker), "La muerte reduce la poblacion por la ruta existente")
	verify(world.corpse_system.get_child_count() > corpses, "La muerte deja un cadaver")
	enemy.free()
	await process_frame
	world.cycle.phase = "DÍA"
	colony.update_workers(0.1)
	verify(not colony.night_authorized and not colony.night_warned, "El amanecer retira permiso y aviso")
	for survivor: ColonyWorker in colony.workers:
		verify(not survivor.is_in_group(GameRules.NIGHT_WORKERS), "De dia conserva sus objetivos originales")
	world.cycle.phase = "NOCHE"
	colony.authorize_night_work()
	verify(colony.night_warned, "La siguiente noche vuelve a advertir")
	world.free()
	await process_frame
	print("night_work_test: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
