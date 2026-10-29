extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/depot/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/depot"))
	GamePreferences.current().briefing_requested = false
	GamePreferences.current().particles = true
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.get_node("Player/Camera2D").position_smoothing_enabled = false
	world.core.tier = 2
	world.bank.scrap = 1000
	var civic: CivicSystem = world.civic
	var home: ExpansionOutpost = world.expansion.sites[0]
	civic.tools[2] = 1
	civic.villagers.assign([{"x": -615.0, "side": -1.0}])
	civic.tick(0.1)
	verify(civic.tools[2] == 1 and civic.villagers.size() == 1, "Un fusil reservado no se pierde cuando falta cuartel")
	verify("cuartel" in civic.describe(-322).text.to_lower(), "El puesto explica la instalación necesaria")
	world.player.position.x = -615
	civic.sync_people(0)
	verify(civic.employment_hint.visible and "cuartel" in civic.employment_hint.text, "El taller muestra por qué no pueden recoger el arma")
	await picture("taller_sin_cuartel")
	home.hp = home.MAX_HEALTH
	civic.tick(0.1)
	verify(civic.tools[2] == 0 and civic.villagers.is_empty() and home.staff_count() == 1, "Al terminar el cuartel recogen el fusil sin pagar de nuevo")
	civic.tools[0] = 1
	civic.tools[1] = 1
	civic.villagers.assign([{"x": -650.0, "side": -1.0}, {"x": -650.0, "side": -1.0}])
	var workforce: int = world.colony.workers.size()
	for step: int in range(30): civic.tick(0.05)
	verify(world.colony.workers.size() == workforce + 2 and civic.villagers.is_empty(), "Dos personas recogen herramientas distintas sin perseguir la misma copia")
	verify(civic.tools[0] == 0 and civic.tools[1] == 0, "Cada herramienta se consume una sola vez")
	world.cycle.phase = "NOCHE"
	civic.tools[0] = 1
	civic.villagers.assign([{"x": -675.0, "side": -1.0}])
	civic.tick(0.05)
	verify(civic.tools[0] == 1 and "murallas" in civic.employment_block(0), "La recogida nocturna espera si el taller está desprotegido")
	civic.walls[1].complete_work()
	civic.villagers[0].x = -675.0
	civic.tick(0.05)
	verify(civic.tools[0] == 0 and civic.villagers.is_empty(), "El taller protegido entrega herramientas también de noche")
	world.cycle.phase = "DÍA"
	home.hire("ranger")
	home.hire("guardian")
	civic.tools[2] = 1
	civic.tools[3] = 1
	civic.villagers.assign([{"x": -615.0, "side": -1.0}, {"x": -585.0, "side": -1.0}])
	civic.tick(0.1)
	verify("lleno" in civic.employment_block(2).to_lower(), "Un cuartel lleno se distingue de uno ausente")
	verify(civic.tools[2] == 1 and civic.tools[3] == 1, "Las reservas se conservan cuando no hay plazas")
	home.squad[0].take_damage(10000)
	for step: int in range(60): civic.tick(0.05)
	verify(home.staff_count() == 3 and civic.tools[2] + civic.tools[3] == 1, "Tirador y guardián comparten la última plaza sin duplicarla")
	var visual: PersonVisual = PersonVisual.new()
	root.add_child(visual)
	visual.setup_person("ranger")
	visual.update_person(1.0 / 120, 5, false, 1)
	var gait: float = visual.gait_distance
	var frame: int = visual.sprite.frame
	for render: int in range(4): visual.update_person(1.0 / 240, 0, false, 1)
	verify(visual.current == &"caminar" and visual.sprite.frame == frame, "Renderizar entre ticks físicos mantiene el pie en vez de reiniciar el reposo")
	verify(visual.gait_distance == gait, "Un fotograma sin desplazamiento no inventa pasos")
	visual.update_person(0.01, 28, false, 1)
	verify(visual.sprite.frame == frame, "Veintiocho unidades completan una zancada sin deslizamiento acumulado")
	visual.update_person(0.15, 0, false, 1)
	verify(visual.current == &"reposo" and visual.sprite.is_playing(), "Detenerse vuelve a la respiración animada")
	visual.free()
	verify(world.view.district_background.resource_path.ends_with("periphery_alive_v2.png"), "La periferia usa el nuevo fondo industrial")
	var clock: float = world.view.time
	world.view._process(0.04)
	verify(world.view.time > clock and world.view.redraw_clock < 1.0 / 30, "El fondo solicita redibujado periódico para animar humo, agua y rotores")
	paused = true
	clock = world.view.time
	await create_timer(0.06, true).timeout
	verify(world.view.time == clock, "El ambiente respeta la pausa del mundo")
	paused = false
	world.player.position.x = 0
	world.view._process(0.05)
	await picture("colonia_viva")
	world.free()
	await process_frame
	for zone: int in range(5):
		var edge: PackedVector2Array = ArenaLayout.boundary(zone)
		verify(edge.size() >= 8 and Geometry2D.triangulate_polygon(edge).size() > 0, "Plataforma no rectangular válida: %d" % zone)
		verify(Geometry2D.is_point_in_polygon(Vector2(320, 130), edge) and Geometry2D.is_point_in_polygon(Vector2(320, 370), edge), "Apariciones dentro del suelo: %d" % zone)
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.player.set_physics_process(false)
	arena.boss.set_physics_process(false)
	arena.modules.set_physics_process(false)
	var boundaries: int = 0
	for node: Node in arena.world.get_children():
		if String(node.name).begins_with("Boundary"): boundaries += 1
	verify(boundaries == ArenaLayout.boundary(0).size(), "Cada borde visible tiene su pared física")
	verify(arena.boss.pieces.size() == 8 and arena.boss.turbine != null, "El Recaudador monta piezas detalladas y turbina independiente")
	var rotation: float = arena.boss.turbine.rotation
	arena.boss.update_puppet(0.2)
	verify(arena.boss.turbine.rotation != rotation, "La turbina gira durante el encuentro")
	await physics_frame
	arena.player.position = Vector2(320, 110)
	var collision: KinematicCollision2D = arena.player.move_and_collide(Vector2(0, -160))
	verify(collision != null and Geometry2D.is_point_in_polygon(arena.player.position, ArenaLayout.boundary(0)), "No se camina fuera de la nueva plataforma")
	arena.player.position = Vector2(320, 370)
	arena.boss.position = Vector2(320, 210)
	arena.boss.update_puppet(0.1)
	await picture("deposito_recaudador")
	arena.boss.change_state(Recaudador.State.CLAW, 0.18)
	arena.boss.update_puppet(0.1)
	verify(arena.boss.claws[0].position.y > 30, "El pistón acompaña la extensión real de la garra")
	arena.boss.receive_hit(arena.boss.position - arena.boss.facing * 60, 10000000)
	var fragments: int = 0
	for node: Node in arena.actors.get_children():
		if node is DebrisEmitter.Pixel and node.texture != null:
			fragments += 1
			verify(node.size.x <= 24 and node.size.y <= 40, "Los fragmentos respetan la escala del sprite ensamblado")
	verify(fragments > 0, "La destrucción usa fragmentos de las piezas reales")
	arena.free()
	await process_frame
	print("Depósito y vida del distrito: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
