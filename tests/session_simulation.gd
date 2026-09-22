extends SceneTree
# Simulación determinista: defensas preparadas, con o sin apoyo del jugador.
func _initialize() -> void:
	call_deferred("simulate")

func simulate() -> void:
	var assist: bool = "--assist" in OS.get_cmdline_user_args()
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.position.x = 0 if assist else 700
	world.player.health = 100 if assist else 0
	for site in world.sites:
		site.hp = site.max_hp
	for step in range(7000):
		if assist:
			var player = world.player
			player.invulnerable = maxf(0.0, player.invulnerable - 0.1)
			player.cooldown_remaining = maxf(0.0, player.cooldown_remaining - 0.1)
			if player.health <= 0:
				player.respawn_remaining -= 0.1
				if player.respawn_remaining <= 0:
					player.health = 100
					player.position.x = 0
					player.invulnerable = 2
			else:
				var target: Node2D = null
				for enemy in get_nodes_in_group("enemies"):
					if target == null or absf(enemy.position.x) < absf(target.position.x):
						target = enemy
				if target != null:
					player.facing = signf(target.position.x - player.position.x)
					if absf(target.position.x - player.position.x) > 32:
						player.position.x = move_toward(player.position.x, target.position.x, player.speed * 0.1)
					player.attack()
					if (world.cooldown_left if player.position.x < 0 else world.cooldown_right) == 0:
						world.activate_overload()
			if world.phase == "DÍA":
				for index in range(world.sites.size()):
					world.perform_interaction(index)
		world._process(0.1)
		for enemy in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			enemy._physics_process(0.1)
		if world.finished:
			print("Simulación apoyo=%s: victoria=%s día=%d núcleo=%d tiempo=%.1fs" % [assist, world.won, world.day, world.core_health, step * 0.1])
			quit(0 if world.won == assist else 1)
			return
	push_error("La partida no terminó en el presupuesto de simulación")
	quit(1)
