extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var world := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(world)
	var player = world.get_node("Player")
	player.attack_damage = 25
	var enemy = get_first_node_in_group("enemies")
	player.position = Vector2(0, 260)
	player.attack()
	assert(enemy.health == 100, "Un ataque fuera de alcance no debe causar daño")
	player.position = Vector2(115, 260)
	player.cooldown_remaining = 0.0
	player.facing = -1.0
	player.attack()
	assert(enemy.health == 100, "No se golpea detrás del personaje")
	player.cooldown_remaining = 0.0
	player.facing = 1.0
	player.attack()
	assert(enemy.health == 75, "Un golpe debe quitar 25 de vida")
	player.attack()
	assert(enemy.health == 75, "El tiempo de espera impide golpes consecutivos")
	for index in range(3):
		player.cooldown_remaining = 0.0
		player.attack()
	assert(enemy.health == 0, "Cuatro golpes derrotan al blanco")
	enemy.take_damage(25)
	assert(enemy.health == 0, "La vida no puede ser negativa")
	enemy._process(3.1)
	assert(enemy.health == 100, "El blanco debe reaparecer")
	player.position = Vector2(185, 260)
	player.facing = -1.0
	player.cooldown_remaining = 0.0
	player.attack()
	assert(enemy.health == 75, "También se puede atacar hacia la izquierda")
	print("PASS: alcance, orientación, daño, espera, muerte y reaparición")
	quit()
