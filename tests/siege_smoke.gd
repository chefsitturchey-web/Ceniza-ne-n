extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	if not condition:
		push_error("FAIL: " + description)
		failures += 1
	checks += 1

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	verify(world.bank.scrap == 90 and world.colony.workers.size() == 2, "economía inicial")
	verify(world.interaction.perform_interaction(0), "encargar muralla")
	verify(world.bank.scrap == 70, "pago único")
	verify(not world.interaction.perform_interaction(0) and world.bank.scrap == 70, "evitar obra duplicada")
	for index: int in range(100):
		world.colony.update_workers(0.1)
	verify(world.construction.sites[0].hp == 240, "constructor completa obra")
	world.construction.damage_site(0, 40)
	verify(world.interaction.perform_interaction(0), "reparación encargada")
	for index: int in range(100):
		world.colony.update_workers(0.1)
	verify(world.construction.sites[0].hp == 240, "reparación completada")
	world.bank.scrap = 0
	verify(not world.interaction.perform_interaction(2), "no construir sin fondos")
	world.bank.scrap = 100
	world.bank.energy_capacity = 0
	verify(not world.interaction.perform_interaction(1), "límite de energía")
	world.bank.energy_capacity = 4
	verify(world.interaction.perform_interaction(1), "encargar torreta")
	verify(world.bank.energy_used() == 2, "reservar energía en obra")
	verify(world.interaction.perform_interaction(-1) and world.interaction.perform_interaction(-1), "reclutar hasta cuatro")
	verify(not world.interaction.perform_interaction(-1), "respetar capacidad de población")
	world.player.position.x = -100
	world.overload.activate_overload()
	verify(world.overload.overload_left == 6.0 and world.overload.overload_right == 0.0, "sobrecarga por frente")
	world.overload.overload_left = 2.0
	world.overload.activate_overload()
	verify(world.overload.overload_left == 2.0, "sobrecarga respeta enfriamiento")
	world.player.dodge()
	verify(world.player.stamina == 70.0, "coste de esquiva")
	world.player.take_damage(25)
	verify(world.player.health == 100, "invulnerabilidad durante esquiva")
	world.player.invulnerable = 0.0
	world.player.take_damage(100)
	verify(world.player.health == 0 and world.player.respawn_remaining == 4.0, "muerte y reenlace")
	world.player._physics_process(4.1)
	verify(world.player.health == 100 and world.player.position.x == 0.0, "reaparición en núcleo")
	var enemy: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres") as EnemyData)
	enemy.set_physics_process(false)
	enemy.position.x = -263
	enemy._physics_process(0.1)
	verify(enemy.target_kind == "wall" and enemy.windup > 0, "enemigo avisa antes de golpear muralla")
	var hp: int = world.construction.sites[0].hp
	enemy._physics_process(0.6)
	verify(world.construction.sites[0].hp < hp, "enemigo daña muralla")
	enemy.position.x = -120
	world.player.position.x = -130
	enemy.cooldown = 0.0
	enemy._physics_process(0.1)
	verify(enemy.target_kind == "player", "enemigo detecta al jugador")
	world.player.position.x = 0
	enemy._physics_process(0.6)
	verify(world.player.health == 100, "salir del alcance evita golpe")
	enemy.take_damage(1000)
	verify(world.get_tree().get_nodes_in_group("enemies").is_empty(), "muerte elimina amenaza")
	world.cycle.phase = "DÍA"
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.cycle.phase == "AVISO", "día pasa a aviso")
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.cycle.phase == "NOCHE", "aviso pasa a noche")
	world.director.spawn_count = 12
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.cycle.day == 2 and world.cycle.phase == "DÍA", "amanecer tras limpiar asedio")
	world.cycle.phase = "NOCHE"
	world.cycle.day = 3
	world.director.start(3)
	world.director.spawn_count = 20
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.session.finished and world.session.won, "victoria tercera noche")
	world.queue_free()
	await process_frame
	var defeat: District = load("res://levels/main.tscn").instantiate() as District
	(defeat.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(defeat)
	defeat.core.health = 0
	defeat.session._process(0.1)
	verify(defeat.session.finished and not defeat.session.won, "derrota por núcleo destruido")
	print("Comprobaciones: %d; fallos: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)
