extends SceneTree

const PATH: String = "user://expansion_test.json"
var checks: int = 0
var failures: int = 0
var world: District
var capture: bool = false

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func picture(name: String, x: float) -> void:
	if not capture: return
	world.player.position.x = x
	var camera: Camera2D = world.get_node("Player/Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	world.presenter.publish()
	world.view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/expansion/" + name + ".png")

func deploy(index: int) -> void:
	world.player.position.x = world.expansion.sites[index].position.x
	Input.action_press("interact")
	world.interaction.update_interaction(0)
	world.interaction.update_interaction(0.81)
	Input.action_release("interact")
	world.interaction.update_interaction(0)

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/expansion"))
	GamePreferences.current().briefing_requested = false
	world = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.modules.set_physics_process(false)
	var expansion: ExpansionSystem = world.expansion
	verify(world.get_node("Floor/Shape").shape.size.x == 3200 and world.get_node("LeftEdge").position.x == -1608, "Suelo y bordes físicos amplían el mapa")
	verify(world.get_node("Player/Camera2D").limit_right == 1600 and absf(world.get_node("RightRepeater").position.x) == 1440, "Cámara y objetivos llegan a los nuevos extremos")
	verify(expansion.sites.size() == 8 and world.construction.sites.size() == 4, "Ocho módulos opcionales conservan las cuatro defensas iniciales")
	var before: int = world.bank.scrap
	world.player.position.x = -700
	verify(world.interaction.interaction_target() == -202, "Exploración descubre caja de suministros")
	verify(world.interaction.perform_interaction(-202) and world.bank.scrap == before + 20, "Suministros entregan veinte de chatarra")
	verify(not expansion.interact(-202) and world.bank.scrap == before + 20, "Caja no permite recursos infinitos")
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	world.bank.scrap = 1000 # Presupuesto explícito de prueba; se comprueba cada cobro.
	verify(not expansion.interact(-100), "Cuartel requiere energía libre")
	deploy(2)
	var generator: ExpansionOutpost = expansion.sites[2]
	verify(generator.ordered and world.bank.scrap == 965 and world.bank.available_capacity() == 4, "Interacción mantenida paga generador sin anticipar energía")
	expansion.tick(5.9)
	verify(generator.hp == 0 and generator.ordered, "Despliegue tarda seis segundos")
	await picture("montaje", -1040)
	expansion.tick(0.11)
	verify(generator.hp == 180 and world.bank.available_capacity() == 6, "Generador terminado aporta dos de energía")
	deploy(0)
	expansion.tick(6.01)
	var ranger: FieldAlly = expansion.sites[0].ally
	verify(ranger != null and ranger.role == "ranger" and world.bank.energy_used() == 5, "Cuartel despliega fusilero y consume una de energía")
	deploy(1)
	expansion.tick(6.01)
	var medic: FieldAlly = expansion.sites[1].ally
	verify(medic != null and medic.role == "medic" and world.bank.energy_used() == 6, "Puesto médico despliega dron sanitario")
	verify(not expansion.interact(-104), "No permite exceder capacidad al desplegar otro cuartel")
	deploy(3)
	expansion.tick(6.01)
	before = world.bank.scrap
	expansion.tick(11.9)
	verify(world.bank.scrap == before, "Recicladora no produce antes de doce segundos operativos")
	expansion.tick(0.11)
	verify(world.bank.scrap == before + 5, "Recicladora genera cinco de chatarra")
	world.cycle.phase = "NOCHE"
	expansion.tick(24)
	verify(world.bank.scrap == before + 5 and not expansion.interact(-106), "Recicladora y despliegues descansan de noche")
	world.cycle.phase = "DÍA"
	world.player.position = medic.position
	world.player.health = 60
	medic.cooldown = 0
	medic.tick(0.01)
	verify(world.player.health == 68, "Dron sana al jugador herido")
	medic.tick(0.01)
	verify(world.player.health == 68, "Curación respeta su cadencia")
	world.player.health = 0
	medic.cooldown = 0
	medic.tick(0.01)
	verify(world.player.health == 0, "Dron no resucita al jugador")
	world.player.health = 100
	var enemy: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres"))
	enemy.set_physics_process(false)
	enemy.position.x = ranger.position.x - 100
	var hp: int = enemy.health
	ranger.cooldown = 0
	ranger.tick(0.01)
	verify(enemy.health == hp - 16, "Fusilero aplica daño a enemigo cercano")
	ranger.tick(0.01)
	verify(enemy.health == hp - 16, "Fusilero no dispara cada fotograma")
	world.player.position.x = 0
	enemy.position.x = ranger.position.x - 10
	enemy.cooldown = 0
	enemy._physics_process(0.01)
	verify(enemy.target_kind == "ally", "Enemigos detectan aliados próximos")
	enemy._physics_process(enemy.data.windup + 0.01)
	verify(ranger.hp == 90 - enemy.damage, "Enemigo daña al aliado y no al núcleo")
	enemy.free()
	ranger.take_damage(100)
	verify(not ranger.is_in_group(GameRules.ALLIES) and ranger.respawn == 18, "Aliado caído sale del combate")
	ranger.tick(17.9)
	verify(ranger.hp == 0, "Relevo no aparece antes de dieciocho segundos")
	ranger.tick(0.11)
	verify(ranger.hp == 90 and ranger.is_in_group(GameRules.ALLIES), "Cuartel operativo envía relevo")
	generator.take_damage(180)
	verify(world.bank.available_capacity() == 4 and not expansion.powered(expansion.sites[0]), "Perder generador suspende apoyo sin energía")
	world.player.position = medic.position
	world.player.health = 60
	medic.cooldown = 0
	medic.tick(4)
	verify(world.player.health == 60, "Dron no cura cuando el puesto carece de energía")
	deploy(2)
	expansion.tick(6.01)
	verify(expansion.powered(expansion.sites[0]), "Reconstruir generador restablece apoyo")
	await picture("puestos", -850)
	var saboteur: Raider = world.director.spawn_enemy(-1, load("res://data/enemies/saboteador.tres")) as Raider
	saboteur.set_physics_process(false)
	saboteur.position.x = generator.position.x - 10
	saboteur._physics_process(0.01)
	verify(saboteur.special_target == generator and saboteur.state == SiegeEnemy.State.WINDUP, "Saboteador elige instalación y avisa")
	saboteur._physics_process(0.66)
	verify(generator.hp == 156, "Saboteador inflige daño doble a la instalación elegida")
	var reinforcement: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres"))
	reinforcement.set_physics_process(false)
	verify(reinforcement.position.x == -1410 and absf(reinforcement.position.x) < GameRules.MAP_HALF_WIDTH, "Apariciones avanzan fuera del frente ampliado y permanecen dentro del mapa")
	var gunner: Raider = world.director.spawn_enemy(1, load("res://data/enemies/artillero.tres")) as Raider
	gunner.set_physics_process(false)
	gunner.position.x = 430
	world.player.position.x = 0
	gunner._physics_process(0.01)
	verify(gunner.state == SiegeEnemy.State.WINDUP, "Artillero se detiene y avisa a distancia")
	var wall: ConstructionSite = world.construction.sites[2]
	hp = wall.hp
	gunner._physics_process(0.5)
	verify(wall.hp == hp, "Aviso de artillero no daña")
	gunner._physics_process(0.41)
	var bolt: RaidBolt
	for child: Node in world.director.get_children():
		if child is RaidBolt: bolt = child
	verify(bolt != null, "Artillero crea proyectil visible después del aviso")
	if bolt != null:
		bolt.set_physics_process(false)
		bolt._physics_process(1)
	verify(wall.hp == hp - 14 and world.player.health == 60, "Muralla intercepta proyectil incluso con delta grande")
	if bolt != null: bolt._physics_process(1)
	verify(wall.hp == hp - 14, "Proyectil consumido no puede impactar dos veces")
	gunner.visual.walking = true
	for child: Node in gunner.get_children():
		if child is FieldUnitVisual:
			var phase: float = child.stride
			gunner.position.x += 12
			child._process(0.1)
			verify(child.stride > phase, "Animación de pasos responde al desplazamiento")
	await picture("nuevas_unidades", 400)
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = PATH
	world.session.add_child(save)
	verify(save.save_game(), "Guardado acepta ampliación y unidades")
	var snapshot: Dictionary = expansion.snapshot()
	expansion.restore({})
	verify(expansion.sites[0].hp == 0 and not expansion.looted[2], "Restauración anterior sin ampliación crea puestos vacíos")
	verify(save.load_game() and expansion.snapshot() == snapshot, "Guardado restaura edificios cajas y aliados sin duplicarlos")
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid.sites[0].ally.hp = 999
	verify(not ExpansionSystem.valid(invalid), "Rechaza vida de aliado fuera de rango")
	invalid = snapshot.duplicate(true)
	invalid.sites[0].id = "generator"
	verify(not ExpansionSystem.valid(invalid), "Rechaza edificios fuera de su emplazamiento")
	var malformed: Dictionary = save._snapshot()
	malformed.expansion = invalid
	verify(save.write_document(malformed) and not save.load_game() and expansion.snapshot() == snapshot, "Guardado inválido no aplica una ampliación parcial")
	var legacy: Dictionary = save._snapshot()
	legacy.erase("expansion")
	verify(save.write_document(legacy) and save.load_game() and expansion.sites[0].hp == 0 and world.bank.available_capacity() == 4, "Partida anterior carga sin generar edificios ni energía extra")
	world.player.position = Vector2(1580, GameRules.FLOOR_Y)
	Input.action_press("move_right")
	world.player._physics_process(0.2)
	Input.action_release("move_right")
	verify(world.player.position.x >= 1580 and world.player.position.x <= 1593, "Nuevo borde físico impide abandonar el mapa")
	save.delete_save()
	world.free()
	await process_frame
	var practice: District = load("res://levels/zones/expansion_playground.tscn").instantiate() as District
	root.add_child(practice)
	practice.get_node("Practice").prepare()
	practice.session.set_process(false)
	verify(not practice.session.persistence_enabled and practice.session.save_system == null and practice.bank.scrap == 260, "Escena de práctica mantiene su presupuesto separado del guardado")
	verify(practice.cycle.phase_remaining == 90 and practice.construction.sites[0].hp > 0, "Práctica prepara defensas y tiempo para explorar")
	practice.get_node("Practice")._process(20)
	verify(get_nodes_in_group(GameRules.ENEMIES).size() == 2, "Práctica presenta los dos enemigos nuevos")
	practice.free()
	await process_frame
	print("Expansión: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
