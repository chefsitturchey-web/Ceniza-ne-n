extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/errante.tres"))
	enemy.set_physics_process(false)
	enemy.position.x = 26
	world.player.position.x = 0
	world.player.attack()
	world.player.hitbox.strike(enemy.hurtbox.world_rect(), 999)
	world.defenses.update_defenses(1)
	world.modules.update_lateral(1)
	verify(enemy.health == enemy.max_health and world.player.slash_remaining == 0, "Ni entrada, ni hitbox, ni módulos personales dañan en colonia")
	var portal: EnemyRepeater = world.expedition.repeaters[1]
	world.player.hitbox.strike(portal.hurtbox.world_rect(), 999)
	verify(portal.health.current == 300, "El jugador no puede cerrar un portal")
	portal.receive_assault(15)
	verify(portal.defense_warning > 0 and portal.defense_pending == 1, "El primer impacto anuncia refuerzos")
	var before: int = get_nodes_in_group(GameRules.ENEMIES).size()
	portal._process(0.81)
	verify(get_nodes_in_group(GameRules.ENEMIES).size() == before + 2, "Dos defensores nacen de la puerta atacada")
	for defender: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES):
		defender.set_physics_process(false)
		if defender != enemy:
			verify(defender.data.reward == 0 and absf(defender.position.x - portal.position.x) == 20, "Defensores sin botín nacen en la boca correcta")
	portal.receive_assault(15)
	verify(portal.defense_pending == 0, "Los impactos no crean enemigos en cada fotograma")
	portal.receive_assault(90)
	verify(portal.defense_pending == 1, "Nueva respuesta al cruzar el siguiente umbral")
	portal.receive_assault(999)
	portal._process(1)
	verify(portal.defense_pending == 0, "El portal muerto cancela sus refuerzos pendientes")
	verify(world.civic.safe_to_build(world.expansion.sites[2].position.x), "La generación inicial no queda detrás de una puerta")
	var home: ExpansionOutpost = world.expansion.sites[4]
	home.hp = 180
	home.hire("ranger")
	var ranger: FieldAlly = home.squad[0]
	# El asalto debe defenderse lejos del cuartel, sin regresar por el ancla de patrulla.
	world.civic.advance_side = 1
	ranger.position.x = 1300
	enemy.position.x = 1330
	ranger.tick(0.1)
	verify(enemy.health < enemy.max_health, "La escuadra combate al defender su asalto lejos del cuartel")
	verify(GameArt.icon("optic").region != GameArt.icon("battery").region, "Cada mejora tiene un icono propio")
	verify(world.modules.command_damage() > 0, "El equipo enlaza bonificaciones con las tropas")
	for remaining: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES): remaining.free()
	portal.restore(false)
	var arrivals: Array[SiegeEnemy] = []
	world.director.spawned.connect(func(defender: SiegeEnemy, _side: float) -> void:
		arrivals.append(defender)
		defender.set_physics_process(false))
	home.hire("guardian")
	home.hire("ranger")
	for ally: FieldAlly in home.squad: ally.position.x = home.position.x
	for step: int in range(2200):
		for ally: FieldAlly in home.squad: ally.tick(0.1)
		portal._process(0.1)
		for defender: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES): defender._physics_process(0.1)
		if portal.health.current == 0: break
		if step % 20 == 0: await process_frame
	verify(portal.health.current == 0, "Una escuadra completa atraviesa la defensa y cierra una entrada sin el Portador")
	verify(arrivals.size() > 0 and arrivals.size() <= 6, "El asalto completo genera refuerzos acotados")
	world.free()
	await process_frame
	print("Comandante: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
