extends SceneTree

var checks: int = 0
var failures: int = 0
var spawned: Array[SiegeEnemy] = []
var sides: Array[float] = []

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func on_spawned(enemy: SiegeEnemy, side: float) -> void:
	enemy.set_physics_process(false)
	spawned.append(enemy)
	sides.append(side)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.director.spawned.connect(on_spawned)
	for night: int in range(1, 4):
		world.director.start(night)
		var wave: WaveData = world.director.wave
		world.director.tick(0.0)
		verify(spawned.size() == 1, "Primera aparición inmediata")
		world.director.tick(wave.cadence * 0.5)
		verify(spawned.size() == 1, "Sin aparición antes de la cadencia")
		world.director.tick(wave.cadence * 0.5)
		verify(spawned.size() == 2, "Aparición al completar cadencia")
		for index: int in range(2, wave.enemies.size()):
			world.director.tick(wave.cadence)
		verify(spawned.size() == 8 + night * 4, "Cantidad de enemigos por noche")
		for index: int in range(spawned.size()):
			var enemy: SiegeEnemy = spawned[index]
			verify(enemy.data == wave.enemies[index] and sides[index] == wave.sides[index], "Tipo y lado desde WaveData")
			verify(enemy.position == Vector2(sides[index] * 650.0, 260.0) and enemy.health == wave.enemies[index].health + (night - 1) * 20, "Posición y escalado exactos")
		world.director.tick(100.0)
		verify(spawned.size() == wave.enemies.size() and not world.director.is_cleared(), "No sobregenerar ni finalizar con amenazas")
		for enemy: SiegeEnemy in spawned:
			enemy.take_damage(10000)
		verify(world.director.is_cleared(), "Cadáveres animados no prolongan la noche")
		spawned.clear()
		sides.clear()
	# Un tipo nuevo se configura mediante Resources, sin condicionales en el director.
	var custom: EnemyData = (load("res://data/enemies/errante.tres") as EnemyData).duplicate() as EnemyData
	custom.id = &"prueba_nuevo_tipo"
	custom.health = 77
	custom.speed = 41.0
	custom.damage = 9
	custom.reward = 7
	var custom_wave: WaveData = WaveData.new()
	custom_wave.enemies = [custom]
	custom_wave.sides = [1.0]
	world.director.waves.append(custom_wave)
	world.director.start(4)
	world.director.tick(0.0)
	verify(spawned.size() == 1 and spawned[0].health == 137 and spawned[0].speed == 41.0 and spawned[0].damage == 9, "Extensión de catálogo sin tocar sistemas")
	var scrap: int = world.bank.scrap
	spawned[0].take_damage(10000)
	spawned[0].take_damage(10000)
	verify(world.bank.scrap == scrap + 7, "Recompensa configurable y única")
	world.free()
	print("Director: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
