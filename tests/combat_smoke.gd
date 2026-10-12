extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	root.add_child(world)
	var player: Player = world.player
	player.attack_damage = 25
	var enemy: TrainingEnemy = TrainingEnemy.new()
	enemy.position = Vector2(150, 260)
	world.add_child(enemy)
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
	for index: int in range(3):
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
