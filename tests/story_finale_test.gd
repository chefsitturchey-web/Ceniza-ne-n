extends SceneTree
var failures: int = 0
var checks: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/story/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/story"))
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	world.bank.scrap = 500
	var story: StoryDirector = world.story
	verify("defensas" in story.objective() and not story.ready_to_travel(), "La historia empieza con una tarea concreta")
	verify(CampaignRoute.COUNT == 5 and CampaignStory.CHAPTERS.size() == 5, "Cinco capítulos con principio y final")
	verify(CampaignRoute.valid_state({"zone": 2, "cleared": [true, true, false]}), "Migra las rutas anteriores de tres distritos")
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	verify("generador" in story.objective(), "Las prioridades siguen la infraestructura real")
	verify(not story.interact(-401), "El relé necesita generación eléctrica")
	verify(story.interact(-400) and story.completed[0], "Rescatar desbloquea la conversación una sola vez")
	var scrap: int = world.bank.scrap
	verify(not story.interact(-400) and world.bank.scrap == scrap, "El rescate no duplica recompensas")
	world.expansion.sites[2].hp = 180
	verify(story.interact(-401) and world.bank.scrap == scrap - 30, "Encargar el relé paga 30 chatarra")
	story.tick(10)
	verify(story.relay_progress == 0, "El relé no se monta sin técnico")
	world.expansion.sites[2].hire("technician")
	var technician: FieldAlly = world.expansion.sites[2].squad[0]
	technician.tick(0.1)
	verify(story.relay_progress == 0 and technician.position.x > -360, "El técnico recorre la distancia física")
	for step: int in range(300): technician.tick(0.1)
	verify(story.completed[1] and story.relay_progress == 6, "El técnico llega y termina la reparación")
	world.player.position.x = story.convoy_x
	verify(story.interact(-402) and story.convoy_active, "El transporte parte después del rescate y el relé")
	var initial_x: float = story.convoy_x
	story.tick(1)
	verify(story.convoy_x == initial_x, "El transporte espera una escolta de soldados")
	var home: ExpansionOutpost = world.expansion.sites[0]
	home.hp = 180
	home.hire("guardian")
	home.hire("ranger")
	for enemy: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES): enemy.set_physics_process(false)
	for step: int in range(900):
		world.player.position.x = story.convoy_x
		for ally: FieldAlly in home.squad: ally.tick(0.1)
		for enemy: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES): enemy._physics_process(0.1)
		story.tick(0.1)
		if story.completed[2]: break
		if step % 40 == 0: await process_frame
	verify(story.completed[2] and story.convoy_health > 0, "La escuadra defiende y escolta el transporte hasta el núcleo")
	verify(story.ready_to_travel(), "Las tres operaciones abren la elegibilidad narrativa del tren")
	var parser: JSON = JSON.new()
	parser.parse(JSON.stringify(story.snapshot()))
	verify(StoryDirector.valid(parser.data), "Operaciones sobreviven al formato JSON")
	var invalid: Dictionary = parser.data.duplicate(true)
	invalid.relay_progress = 8
	verify(not StoryDirector.valid(invalid), "Rechaza progreso de reparación fuera de rango")
	story.restore(parser.data)
	verify(story.ready_to_travel(), "Restaurar no repite operaciones ni pierde el estado")
	story.journal.open_panel()
	verify(paused and story.journal.opened and story.journal.next.disabled, "El diario pausa y evita spoilers de capítulos futuros")
	await picture("diario")
	story.journal.close_panel()
	verify(not paused, "Cerrar el diario devuelve el control")
	world.cycle.day = 3
	world.cycle.phase = "NOCHE"
	world.cycle.phase_remaining = 0
	world.director.start(3)
	world.director.spawn_count = world.director.wave.enemies.size()
	for enemy: SiegeEnemy in get_nodes_in_group(GameRules.ENEMIES): enemy.take_damage(100000)
	world.cycle.update_phase(0)
	world.civic.tick(0)
	verify(world.cycle.day == 4 and world.civic.camp_day == 4, "La campaña sigue después del tercer día y repone reclutas")
	var veteran: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/errante.tres"), 50)
	veteran.set_physics_process(false)
	verify(veteran.night == 3, "Esperar más días no aumenta indefinidamente la vida enemiga")
	veteran.free()
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = "user://story_finale_test.json"
	world.add_child(save)
	verify(save.save_game(), "Guardado completo acepta las operaciones")
	story.completed[0] = false
	verify(save.load_game() and story.completed[0], "El guardado restaura la historia real")
	save.delete_save()
	world.free()
	await process_frame
	for index: int in [3, 4]:
		var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
		arena.zone_index = index
		root.add_child(arena)
		arena.set_process(false)
		arena.player.set_physics_process(false)
		arena.modules.set_physics_process(false)
		arena.boss.set_physics_process(false)
		await physics_frame
		var initial: Vector2 = arena.boss.position
		for step: int in range(20): arena.boss._physics_process(0.1)
		verify(arena.boss.position.distance_to(initial) > 10, "El jefe final %d se desplaza físicamente" % index)
		if index == 3:
			var prefect: ElPrefecto = arena.boss as ElPrefecto
			prefect.facing = Vector2.DOWN
			prefect.change_state(Recaudador.State.APPROACH, 2)
			verify(prefect.receive_hit(prefect.position + Vector2(0, 40), 100) == 0, "El escudo del Prefecto bloquea el frente")
			verify(prefect.receive_hit(prefect.position - Vector2(0, 40), 100) == 40, "El flanco tiene respuesta distinta")
			prefect.change_state(Recaudador.State.RECOVER, 3)
			verify(prefect.receive_hit(prefect.position, 100) == 200, "La recuperación abre una ventana de castigo")
			prefect.health = prefect.max_health / 2 + 10
			prefect.receive_hit(prefect.position, 100)
			prefect.change_state(Recaudador.State.CHARGE_WINDUP, 0)
			prefect._physics_process(0.01)
			verify(prefect.phase == 2 and prefect.charges_left == 2, "Segunda fase encadena dos estocadas")
			prefect.change_state(Recaudador.State.CHARGE_WINDUP, 1)
			await picture("prefecto")
		else:
			var mother: MadreCero = arena.boss as MadreCero
			verify(mother.relays.size() == 3 and mother.active_relays() == 3, "MADRE CERO conecta tres relés aliados")
			verify(mother.receive_hit(mother.position, 100) == 0, "No se atraviesa el escudo sin sostener el enlace")
			mother.charge = 17.9
			mother._physics_process(0.2)
			verify(mother.core_exposed and mother.receive_hit(mother.position, 100) == 200, "Dos relés sostenidos abren el núcleo")
			mother.exposure = 0
			mother.charge = 0
			for relay: NetworkRelay in mother.relays: relay.health = 0
			mother._physics_process(0.5)
			verify(mother.charge == 0, "Sin infraestructura se detiene la apertura")
			arena.player.position = mother.relays[0].position
			arena.player.stamina = 100
			verify(mother.repair_nearest() and mother.relays[0].health == 45 and arena.player.stamina == 75, "Reparar cuesta resistencia y recupera un relé caído")
			arena.player.position = mother.relays[1].position
			mother.repair_nearest()
			mother._physics_process(0.5)
			verify(mother.charge > 0, "Reconectar dos relés evita una partida bloqueada")
			arena.player.stamina = 100
			verify(mother.overload_relays() and not mother.overload_relays(), "Sobrecarga con coste y enfriamiento")
			var hp: int = mother.relays[0].health
			mother.marks.append({"position": mother.relays[0].position, "time": 0.1, "relay": 0})
			mother._physics_process(0.2)
			verify(mother.relays[0].health == hp, "La sobrecarga protege un pulso sobre el relé")
			mother.marks.append({"position": mother.relays[0].position, "time": 1.2, "relay": 0})
			await picture("madre_cero")
		arena.free()
		await process_frame
	print("Historia y final: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
