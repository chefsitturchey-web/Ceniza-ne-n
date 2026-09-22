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
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	world.player.set_physics_process(false)
	verify(world.scrap == 90 and world.workers.size() == 2, "economía inicial")
	verify(world.perform_interaction(0), "encargar muralla")
	verify(world.scrap == 70, "pago único")
	verify(not world.perform_interaction(0) and world.scrap == 70, "evitar obra duplicada")
	for index in range(100):
		world.update_workers(0.1)
	verify(world.sites[0].hp == 240, "constructor completa obra")
	world.damage_site(0, 40)
	verify(world.perform_interaction(0), "reparación encargada")
	for index in range(100):
		world.update_workers(0.1)
	verify(world.sites[0].hp == 240, "reparación completada")
	world.scrap = 0
	verify(not world.perform_interaction(2), "no construir sin fondos")
	world.scrap = 100
	world.energy_capacity = 0
	verify(not world.perform_interaction(1), "límite de energía")
	world.energy_capacity = 4
	verify(world.perform_interaction(1), "encargar torreta")
	verify(world.energy_used() == 2, "reservar energía en obra")
	verify(world.perform_interaction(-1) and world.perform_interaction(-1), "reclutar hasta cuatro")
	verify(not world.perform_interaction(-1), "respetar capacidad de población")
	world.player.position.x = -100
	world.activate_overload()
	verify(world.overload_left == 6.0 and world.overload_right == 0.0, "sobrecarga por frente")
	world.overload_left = 2.0
	world.activate_overload()
	verify(world.overload_left == 2.0, "sobrecarga respeta enfriamiento")
	world.player.dodge()
	verify(world.player.stamina == 70.0, "coste de esquiva")
	world.player.take_damage(25)
	verify(world.player.health == 100, "invulnerabilidad durante esquiva")
	world.player.invulnerable = 0.0
	world.player.take_damage(100)
	verify(world.player.health == 0 and world.player.respawn_remaining == 4.0, "muerte y reenlace")
	world.player._physics_process(4.1)
	verify(world.player.health == 100 and world.player.position.x == 0.0, "reaparición en núcleo")
	var enemy = world.spawn_enemy(-1, false)
	enemy.set_physics_process(false)
	enemy.position.x = -263
	enemy._physics_process(0.1)
	verify(enemy.target_kind == "wall" and enemy.windup > 0, "enemigo avisa antes de golpear muralla")
	var hp: int = world.sites[0].hp
	enemy._physics_process(0.6)
	verify(world.sites[0].hp < hp, "enemigo daña muralla")
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
	world.phase = "DÍA"
	world.phase_remaining = 0
	world.update_phase(0)
	verify(world.phase == "AVISO", "día pasa a aviso")
	world.phase_remaining = 0
	world.update_phase(0)
	verify(world.phase == "NOCHE", "aviso pasa a noche")
	world.spawn_count = 12
	world.phase_remaining = 0
	world.update_phase(0)
	verify(world.day == 2 and world.phase == "DÍA", "amanecer tras limpiar asedio")
	world.phase = "NOCHE"
	world.day = 3
	world.spawn_count = 20
	world.phase_remaining = 0
	world.update_phase(0)
	verify(world.finished and world.won, "victoria tercera noche")
	world.queue_free()
	await process_frame
	var defeat = load("res://scenes/main.tscn").instantiate()
	root.add_child(defeat)
	defeat.core_health = 0
	defeat._process(0.1)
	verify(defeat.finished and not defeat.won, "derrota por núcleo destruido")
	print("Comprobaciones: %d; fallos: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)
