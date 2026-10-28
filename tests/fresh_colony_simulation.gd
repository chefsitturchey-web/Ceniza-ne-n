extends SceneTree
## Colonia desde cero: encargar obras mediante la interacción mantenida real.
## El jugador de apoyo usa las mismas estadísticas, costes y cadencias de la escena.

func _initialize() -> void:
	call_deferred("simulate")

func simulate() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.cycle.boss_required = false # Aquí se verifica el asedio; expedición tiene pruebas propias.
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var player: Player = world.player
	var next_order: int = 0
	var order_time: float = -1
	var all_built: bool = false
	for step: int in range(5000):
		player.invulnerable = maxf(0, player.invulnerable - 0.1)
		player.cooldown_remaining = maxf(0, player.cooldown_remaining - 0.1)
		Input.action_release("interact")
		if next_order < world.construction.sites.size():
			var site: ConstructionSite = world.construction.sites[next_order]
			if site.ordered or site.hp > 0:
				next_order += 1
				if next_order == world.construction.sites.size():
					order_time = step * 0.1
					if world.bank.scrap != 0:
						push_error("Las cuatro obras iniciales deben pagar su coste real de 90 chatarra")
						world.free()
						quit(1)
						return
			else:
				player.position.x = move_toward(player.position.x, site.x, player.speed * 0.1)
				if absf(player.position.x - site.x) < 22:
					Input.action_press("interact")
		elif player.health <= 0:
			player.respawn_remaining = maxf(0, player.respawn_remaining - 0.1)
			if player.respawn_remaining == 0:
				player.health = Player.MAX_HEALTH
				player.position.x = 0
				player.invulnerable = Player.RESPAWN_INVULNERABILITY
		else:
			var target: Node2D = null
			for enemy: Node2D in get_nodes_in_group(GameRules.ENEMIES):
				if target == null or absf(enemy.position.x) < absf(target.position.x):
					target = enemy
			if target != null:
				player.facing = signf(target.position.x - player.position.x)
				player.position.x = move_toward(player.position.x, target.position.x - player.facing * 30, player.speed * 0.1)
				player.attack()
				if (world.overload.cooldown_left if player.position.x < 0 else world.overload.cooldown_right) == 0:
					world.overload.activate_overload()
			elif world.cycle.phase == "DÍA":
				for index: int in range(world.construction.sites.size()):
					var site: ConstructionSite = world.construction.sites[index]
					if site.hp < site.max_hp and not site.ordered:
						player.position.x = move_toward(player.position.x, site.x, player.speed * 0.1)
						if absf(player.position.x - site.x) < 22:
							Input.action_press("interact")
						break
		world.session._process(0.1)
		var complete: int = 0
		for site: ConstructionSite in world.construction.sites:
			if site.hp > 0:
				complete += 1
		all_built = all_built or complete == world.construction.sites.size()
		for enemy: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES):
			enemy.set_physics_process(false)
			enemy._physics_process(0.1)
		if world.session.finished:
			Input.action_release("interact")
			var valid: bool = world.session.won and all_built and order_time > 0 and order_time < 10 and world.core.health > 0
			print("Colonia nueva: obras encargadas=%.1fs; cuatro defensas construidas=%s; victoria=%s; núcleo=%d; sesión=%.1fs" % [order_time, all_built, world.session.won, world.core.health, step * 0.1])
			world.free()
			await process_frame
			if valid:
				print("PASS: construcción desde cero, pago real, trabajadores y tres noches con apoyo")
			else:
				push_error("La colonia nueva no superó la prueba de preparación y asedio")
			quit(0 if valid else 1)
			return
		if step % 50 == 0:
			await process_frame
	Input.action_release("interact")
	world.free()
	push_error("La colonia nueva no terminó en el límite de simulación")
	quit(1)
