extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_checks")
func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index: int in count: await process_frame

func picture(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/preview_ambiente/" + filename + ".png")

func run_checks() -> void:
	var prefs: GamePreferences = GamePreferences.current()
	var old: Dictionary = prefs.values.duplicate()
	prefs.values.particles = true
	prefs.values.reduced_flashes = false
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/preview_ambiente"))
	var world: District = load("res://levels/main.tscn").instantiate()
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.first_steps.enabled = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	var camera: Camera2D = world.player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	if capture: world.impact.camera_rest = Vector2(0, -35)
	world.player.position.x = -330
	camera.reset_smoothing()
	var atmosphere: WorldAtmosphere = world.view.get_node("WorldAtmosphere")
	verify(atmosphere.chimneys.size() == 15 and atmosphere.vents.size() == 3, "Pool de emisores acotado")
	atmosphere._process(0.1)
	var count: int = 0
	for emitter: Node2D in atmosphere.chimneys:
		if emitter.visible: count += 1
		verify(emitter.get("texture") != null, "Textura propia de humo")
		verify(emitter.get("amount") == 18, "Presupuesto normal por chimenea")
		if RenderingServer.get_current_rendering_method() == "gl_compatibility": verify(emitter is CPUParticles2D, "Fallback CPU Compatibility")
	var anchor_emitter: Node2D = atmosphere.chimneys[5]
	var x_before: float = anchor_emitter.position.x
	world.player.position.x += 100
	camera.force_update_scroll()
	atmosphere._process(0)
	verify(absf(anchor_emitter.position.x - x_before - 100 * (1 - DistrictDepth.ARCHITECTURE_SCROLL)) <= 2, "Humo comparte desplazamiento de arquitectura")
	world.player.position.x -= 100
	camera.force_update_scroll()
	atmosphere._process(0)
	verify(world.settlement_backdrop.steam_pool.size() == 3, "Poblados reutilizan tres salidas de vapor")
	var time_before: float = atmosphere.clock
	var portal_time_before: float = world.expedition.repeaters[0].portal_effect.clock
	paused = true
	await create_timer(0.03, true).timeout
	verify(atmosphere.clock == time_before, "La pausa detiene el ambiente")
	verify(world.expedition.repeaters[0].portal_effect.clock == portal_time_before, "La pausa detiene tambien el remolino del portal")
	paused = false
	verify(count > 0, "Chimeneas ancladas al fondo visibles")
	prefs.values.reduced_flashes = true
	atmosphere._process(0.1)
	for emitter: Node2D in atmosphere.chimneys: verify(emitter.get("amount") <= 6, "Modo reducido limita particulas vivas")
	world.impact.sparks.emit_pixels(world.player.global_position, 200, Color.WHITE)
	verify(DebrisEmitter.live_count <= 40, "Escombros comparten limite reducido de 40")
	for node: Node in world.get_children():
		if node is DebrisEmitter.Pixel: node.free()
	world.impact.active = false
	world.impact.hit(world.player.global_position, 1)
	verify(DebrisEmitter.live_count == 0, "Feedback inactivo no crea chispas")
	world.impact.active = true
	prefs.values.particles = false
	atmosphere._process(0.1)
	for emitter: Node2D in atmosphere.chimneys + atmosphere.vents: verify(not emitter.visible and not emitter.get("emitting"), "Desactivar particulas oculta y detiene emisores")
	prefs.values.particles = true
	prefs.values.reduced_flashes = false
	var portal: EnemyRepeater = world.expedition.repeaters[0]
	verify(portal.portal_effect.shader_material.shader != null, "Shader asignado al portal real")
	verify(portal.portal_effect.shader_material.shader.get_shader_uniform_list().size() >= 3, "Shader de portal compilado con sus uniformes")
	portal.portal_effect.trigger()
	verify(portal.portal_effect.pulse == 1, "Activacion anima el portal")
	verify(portal.portal_effect.lamp.texture != null and portal.portal_effect.hum.stream != null, "Portal tiene luz y zumbido espacial")
	portal.restore(true)
	verify(not portal.portal_effect.active, "Portal destruido apaga efectos")
	portal.restore(false)
	verify(portal.portal_effect.active, "Restaurar portal reactiva efectos")
	if capture:
		world.cycle.phase = "DÍA"
		world.view.light = DistrictView.LIGHTING["DÍA"].duplicate()
		await frames(100)
		await picture("01_dia")
		world.cycle.phase = "NOCHE"
		world.view.light = DistrictView.LIGHTING["NOCHE"].duplicate()
		await frames(100)
		await picture("02_noche")
		world.player.position.x = portal.position.x - 55
		camera.reset_smoothing()
		await frames(65)
		portal.portal_effect.trigger()
		await frames(5)
		await picture("03_portal")
	world.free()
	await process_frame
	var arena: RecaudadorArena = load("res://levels/expedition/caldera_arena.tscn").instantiate()
	root.add_child(arena)
	var found: bool = false
	for node: Node in arena.world.get_child(0).get_children():
		if node is WorldAtmosphere:
			found = node.arena_mode and node.vents.size() == 3
	verify(arena.impact.sparks.planar, "Chispas de arena no rebotan en el suelo lateral")
	verify(found, "Arena comparte vapor y bruma con colonia")
	if capture:
		arena.player.health = Player.MAX_HEALTH
		arena.player.set_physics_process(false)
		await frames(90)
		await picture("04_arena")
	arena.free()
	await process_frame
	prefs.values = old
	print("PASS: world_atmosphere; fallos: %d" % failures)
	quit(1 if failures else 0)
