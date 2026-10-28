extends SceneTree

var checks: int = 0
var failures: int = 0
var world: District
const PATH: String = "user://modules_test.json"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func spawn_at(x: float, kind: String = "errante") -> SiegeEnemy:
	var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/%s.tres" % kind))
	enemy.position.x = x
	enemy.set_physics_process(false)
	return enemy

func clear_enemies() -> void:
	for enemy: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES):
		enemy.take_damage(100000)

func run_checks() -> void:
	world = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	await process_frame
	var gear: ModuleSystem = world.modules
	var neural: NeuralSystem = world.neural
	verify(gear.levels.drone == 1 and gear.equipped == ["drone"] and gear.spent() == 0, "Dron inicial gratuito y sin cambiar balance base")
	verify(not neural.upgrade_module("tesla") and not neural.install_passive("battery"), "No desbloquear equipo sin puntos")
	neural.kills = 240
	verify(neural.upgrade_module("tesla") and gear.equipped == ["drone", "tesla"], "Desbloquear Tesla equipa la segunda ranura")
	verify(gear.equip("drone") and not gear.equip("tesla"), "Se permite cambiar equipo pero no dejar cero módulos")
	var shield: SiegeEnemy = spawn_at(60, "blindado")
	var hp: int = shield.health
	gear.update_lateral(0)
	verify(shield.health == hp - 14, "Tesla real atraviesa el escudo del Blindado")
	gear.update_lateral(0)
	verify(shield.health == hp - 14, "El temporizador impide repetir daño cada frame")
	verify(not gear.evolve("tesla"), "No evolucionar sin receta")
	for index: int in range(4):
		verify(neural.upgrade_module("tesla"), "Subir Tesla de nivel")
	verify(not neural.upgrade_module("tesla"), "Límite de cinco niveles")
	verify(not gear.evolve("tesla"), "Nivel cinco no basta sin pasiva y núcleo")
	verify(neural.install_passive("battery") and not neural.install_passive("battery"), "Pasiva cuesta un punto y no se compra dos veces")
	verify(not gear.evolve("tesla"), "La pasiva no reemplaza el núcleo")
	clear_enemies()
	world.director.start(1)
	world.director.spawn_count = world.director.wave.enemies.size() - 1
	world.director.tick(0)
	var carrier: SiegeEnemy = world.director.get_child(world.director.get_child_count() - 1) as SiegeEnemy
	verify(carrier.elite and carrier.max_health == carrier.data.health, "Última unidad porta núcleo sin inflar sus estadísticas")
	carrier.take_damage(100000)
	carrier.take_damage(100000)
	verify(gear.cores == 1, "El portador entrega un solo núcleo")
	verify(gear.evolve("tesla") and gear.cores == 0 and not gear.evolve("tesla"), "Tormenta consume exactamente un núcleo")
	var victims: Array[SiegeEnemy] = []
	for x: float in [60.0, 110.0, 165.0, 220.0]:
		victims.append(spawn_at(x))
	var remote: SiegeEnemy = spawn_at(500)
	gear.timers.tesla = 0
	gear.update_lateral(0)
	for enemy: SiegeEnemy in victims:
		verify(enemy.health < enemy.max_health, "Tormenta encadena a un objetivo cercano distinto")
	verify(remote.health == remote.max_health, "La cadena no alcanza un objetivo remoto")
	clear_enemies()
	verify(neural.upgrade_module("orbital"), "Desbloquear disco orbital")
	verify(not gear.equip("drone"), "No se permite una tercera ranura")
	verify(gear.equip("tesla"), "Retirar Tesla conserva orbital activo")
	victims.clear()
	for x: float in [10.0, 20.0, 30.0, 35.0]:
		victims.append(spawn_at(x))
	remote = spawn_at(100)
	gear.timers.orbital = 0
	gear.update_lateral(0)
	var damaged: int = 0
	for enemy: SiegeEnemy in victims:
		if enemy.health < enemy.max_health:
			damaged += 1
	verify(damaged == 3 and remote.health == remote.max_health, "Disco limita área y número de objetivos")
	clear_enemies()
	var saved: Dictionary = neural.snapshot()
	verify(NeuralSystem.valid(saved), "Equipo comprado produce guardado válido")
	for id: String in ["slots", "level", "cores", "budget"]:
		var invalid: Dictionary = saved.duplicate(true)
		match id:
			"slots": invalid.modules.equipped = ["drone", "tesla", "orbital"]
			"level": invalid.modules.levels.tesla = 6
			"cores": invalid.modules.cores = -1
			"budget": invalid.kills = 0
		verify(not NeuralSystem.valid(invalid), "Rechaza guardado inválido: " + id)
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = PATH
	world.session.add_child(save)
	verify(save.save_game(), "Guardar módulos y evolución")
	neural.restore({})
	verify(save.load_game() and neural.snapshot() == saved, "Restaurar presupuesto, pasivas, ranuras y evolución")
	save.delete_save()
	gear.equip("tesla")
	gear.equip("orbital")
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
	arena.configure(world.player)
	root.add_child(arena)
	arena.player.set_physics_process(false)
	arena.boss.set_physics_process(false)
	arena.modules.set_physics_process(false)
	await physics_frame
	await process_frame
	verify(arena.modules.evolved.tesla and arena.modules.equipped == ["tesla"], "La expedición hereda equipo y evolución")
	arena.player.position = Vector2(320, 220)
	arena.boss.position = Vector2(380, 220)
	arena.boss.stun()
	hp = arena.boss.health
	arena.modules.timers.tesla = 0
	arena.modules.update_arena(0)
	verify(arena.boss.health == hp - roundi(gear.damage_for("tesla") * 1.4) * 2, "Tormenta daña realmente el núcleo expuesto")
	arena.player.position = Vector2(155, 160)
	arena.boss.position = Vector2(205, 160)
	hp = arena.boss.health
	arena.modules.timers.tesla = 0
	arena.modules.update_arena(0)
	verify(arena.boss.health == hp, "La cobertura bloquea ataques automáticos en la arena")
	arena.player.position = Vector2(40, 40)
	arena.boss.position = Vector2(590, 420)
	arena.modules.update_arena(2)
	verify(arena.boss.health == hp, "El módulo respeta distancia en arena")
	arena.free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		world.player.position.x = -110
		world.clinic_panel.open_panel()
		world.clinic_panel.tabs.current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/equipo-clinica.png")
		world.clinic_panel.close_panel()
	world.free()
	await process_frame
	print("Módulos: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
