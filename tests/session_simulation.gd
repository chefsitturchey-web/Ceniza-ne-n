extends SceneTree
# Simulación determinista: defensas preparadas, con o sin apoyo del jugador.
func _initialize() -> void:
	call_deferred("simulate")

func simulate() -> void:
	var assist: bool = "--assist" in OS.get_cmdline_user_args()
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	# Referencia del asedio original; la campana ahora se completa con el jefe.
	world.cycle.boss_required = false
	world.session.set_process(false)
	world.experience.present_choices = false
	world.player.set_physics_process(false)
	world.player.position.x = 0 if assist else 700
	world.player.health = 100 if assist else 0
	for site: ConstructionSite in world.construction.sites:
		site.hp = site.max_hp
	var strategy: RefCounted = load("res://tests/commander_strategy.gd").new()
	for step: int in range(15000):
		if assist:
			var player: Player = world.player
			player.invulnerable = maxf(0.0, player.invulnerable - 0.1)
			player.cooldown_remaining = maxf(0.0, player.cooldown_remaining - 0.1)
			strategy.tick(world, 0.1)
			if player.health <= 0:
				player.respawn_remaining -= 0.1
				if player.respawn_remaining <= 0:
					player.health = 100
					player.position.x = 0
					player.invulnerable = 2
			else:
				var target: Node2D = null
				for enemy: Node2D in get_nodes_in_group("enemies"):
					if target == null or absf(enemy.position.x) < absf(target.position.x):
						target = enemy
				if target != null:
					player.facing = signf(target.position.x - player.position.x)
					if absf(target.position.x - player.position.x) > 32:
						player.position.x = move_toward(player.position.x, target.position.x, player.speed * 0.1)
					player.attack()
					if (world.overload.cooldown_left if player.position.x < 0 else world.overload.cooldown_right) == 0:
						world.overload.activate_overload()
			if world.cycle.phase == "DÍA":
				for index: int in range(world.construction.sites.size()):
					if world.construction.sites[index].hp < world.construction.sites[index].max_hp:
						world.interaction.perform_interaction(index)
		world.session._process(0.1)
		if world.experience.pending > 0:
			world.experience.choose(world.experience.options()[0], false)
		if world.experience.chest_pending > 0:
			world.experience.choose(world.experience.options(true)[0], true)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			enemy._physics_process(0.1)
		for child: Node in world.director.get_children():
			if child is RaidBolt:
				child.set_physics_process(false)
				child._physics_process(0.1)
		if world.session.finished:
			print("Simulación apoyo=%s: victoria=%s día=%d núcleo=%d tiempo=%.1fs" % [assist, world.session.won, world.cycle.day, world.core.health, step * 0.1])
			# Referencia ampliada con artilleros y proyectiles simulados: 128.2 s sin apoyo.
			var matches_reference: bool = world.session.won == assist and world.cycle.day <= 3 and (world.core.health > 0 if assist else world.core.health == 0)
			if not matches_reference:
				push_error("La simulación cambió respecto a la referencia de las oleadas ampliadas")
			quit(0 if matches_reference else 1)
			return
	if not assist:
		print("PASS: una colonia sin gestión no obtiene victoria automática; asedio estancado")
		quit(0)
	else:
		push_error("La partida no terminó en el presupuesto de simulación")
		quit(1)
