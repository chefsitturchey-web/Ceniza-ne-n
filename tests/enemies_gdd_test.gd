extends SceneTree
## Blindado, Saltador y Ariete: reglas propias de cada arquetipo del GDD.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	if not condition:
		push_error("FAIL: " + description)
		failures += 1
	checks += 1

func left_wall(world: District) -> int:
	for index: int in range(world.construction.sites.size()):
		var site: ConstructionSite = world.construction.sites[index]
		if site.data.blocks_enemies and site.x < 0.0:
			return index
	return -1

func run_checks() -> void:
	var datas: Dictionary = {}
	for id: String in ["blindado", "saltador", "ariete"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id) as EnemyData
		datas[id] = data
		verify(data != null and data.scene != null, id + ": Resource y escena")
		var preview: Node = data.scene.instantiate()
		verify(preview is SiegeEnemy and preview.get_node_or_null("AnimatedSprite2D") != null, id + ": escena con sprite")
		preview.free()
	var night_2: WaveData = load("res://data/waves/night_2.tres")
	var night_3: WaveData = load("res://data/waves/night_3.tres")
	verify(night_2.enemies.has(datas.blindado) and night_2.enemies.has(datas.saltador), "Noche 2 trae Blindado y Saltador")
	verify(night_3.enemies.has(datas.ariete) and night_3.enemies.has(datas.blindado), "Noche 3 trae Ariete y Blindado")

	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)

	# Blindado: escudo frontal contra balas; la sobrecarga y el cuerpo a cuerpo lo atraviesan.
	var tank: Blindado = world.director.spawn_enemy(-1.0, datas.blindado) as Blindado
	tank.set_physics_process(false)
	tank.position.x = -300.0
	tank.face_toward(0.0)
	var before: int = tank.health
	tank.receive_shot(40, Vector2(-180, GameRules.FLOOR_Y - 42), false)
	verify(before - tank.health == 10, "Blindado recibe 25 % de una bala frontal")
	before = tank.health
	tank.receive_shot(40, Vector2(-450, GameRules.FLOOR_Y - 42), false)
	verify(before - tank.health == 40, "Blindado recibe daño completo por la espalda")
	before = tank.health
	tank.receive_shot(40, Vector2(-180, GameRules.FLOOR_Y - 42), true)
	verify(before - tank.health == 40, "La sobrecarga atraviesa el escudo")
	before = tank.health
	tank.hurtbox.receive(30)
	verify(before - tank.health == 30, "El cuerpo a cuerpo hace daño completo")

	# Ariete: triple a estructuras, normal al núcleo.
	var wall_index: int = left_wall(world)
	var wall: ConstructionSite = world.construction.sites[wall_index]
	wall.complete_work()
	var ram: Ariete = world.director.spawn_enemy(-1.0, datas.ariete) as Ariete
	ram.set_physics_process(false)
	ram.target_kind = "wall"
	ram.target_index = wall_index
	before = wall.hp
	ram.land_hit()
	verify(before - wall.hp == ram.damage * Ariete.STRUCTURE_MULTIPLIER, "Ariete hace daño triple a murallas")
	ram.target_kind = "core"
	before = world.core.health
	ram.land_hit()
	verify(before - world.core.health == ram.damage, "Ariete hace daño normal al núcleo")

	# Saltador: pasa la primera muralla una sola vez y aterriza detrás.
	wall.complete_work()
	var jumper: Saltador = world.director.spawn_enemy(-1.0, datas.saltador) as Saltador
	jumper.set_physics_process(false)
	jumper.position.x = wall.x - 20.0
	for step: int in range(40):
		jumper._physics_process(0.05)
	verify(jumper.jumped and jumper.jumps == 1, "Saltador salta una vez")
	verify(jumper.position.x > wall.x and is_equal_approx(jumper.position.y, GameRules.FLOOR_Y), "Saltador aterriza detrás de la muralla")
	verify(wall.hp == wall.max_hp, "El salto no daña la muralla")
	for step: int in range(40):
		jumper._physics_process(0.05)
	verify(jumper.jumps == 1, "No vuelve a saltar")

	world.free()
	print("Enemigos GDD: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
