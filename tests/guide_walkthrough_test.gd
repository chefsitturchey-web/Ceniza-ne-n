extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_checks")
func verify(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run_checks() -> void:
	if "--seeded" in OS.get_cmdline_user_args(): FrontierLayout.active_seed = 7777
	SaveSystem.engagement_path = "user://guide_walk_test.cfg"
	SaveSystem.store_engagement({"guide": 0, "record": 0, "achievements": []})
	var world: District = load("res://levels/main.tscn").instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	current_scene = world
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.story.present_dialogue = false
	world.experience.present_choices = false
	world.cycle.debug_frozen = true
	world.first_steps.enabled = true
	world.first_steps.persist = true
	var checkpoint: SaveSystem = SaveSystem.new()
	checkpoint.session = world.session
	checkpoint.save_path = "user://guia_recorrido_test.json"
	world.session.add_child(checkpoint)
	world.session.save_system = checkpoint
	world.first_steps.restart()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/validation/latest/guia-inicio.png")
	# Seguir únicamente el marcador y mantener Operar: costes, viajes y obras reales.
	for frame: int in 9000:
		if world.first_steps.step >= 9: break
		world.player.position.x = move_toward(world.player.position.x, world.first_steps.target().x, 18)
		if world.first_steps.waiting(): Input.action_release("interact")
		else: Input.action_press("interact")
		world.session._process(0.1)
		if frame % 10 == 0: await process_frame
	Input.action_release("interact")
	verify(world.first_steps.step == 9, "Marcador permite llegar a la noche sin atajos; paso=%d, chatarra=%d, piezas=%d" % [world.first_steps.step, world.bank.scrap, world.bank.parts + world.bank.stored_parts])
	verify(world.core.tier == 2 and world.expansion.energy_bonus() > 0, "Ruta funda núcleo Nv.2 y generador con costes reales")
	world.cycle.debug_frozen = false
	world.director.spawned.connect(func(enemy: SiegeEnemy, _side: float) -> void: enemy.set_physics_process(false))
	for frame: int in 3000:
		if world.cycle.day >= 2 or world.session.finished: break
		world.player.position.x = move_toward(world.player.position.x, 0, 18)
		if world.first_steps.step == 9: Input.action_press("interact")
		else: Input.action_release("interact")
		world.session._process(0.1)
		for enemy: Node in get_nodes_in_group(GameRules.ENEMIES):
			if not enemy.is_queued_for_deletion(): enemy._physics_process(0.1)
		if frame % 10 == 0: await process_frame
	Input.action_release("interact")
	verify(world.cycle.day >= 2 and world.core.health > 0, "La defensa enseñada permite sobrevivir a la primera noche: día=%d fase=%s núcleo=%d paso=%d" % [world.cycle.day, world.cycle.phase, world.core.health, world.first_steps.step])
	verify(SaveSystem.engagement_profile().guide == FirstSteps.COUNT and checkpoint.has_save(), "Recorrido persiste guía y checkpoint: paso=%d perfil=%d guardado=%s" % [world.first_steps.step, SaveSystem.engagement_profile().guide, checkpoint.has_save()])
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(checkpoint.save_path))
	verify(int(saved.scrap) == world.bank.scrap, "El checkpoint incluye la última recompensa de la guía: guardado=%d actual=%d" % [int(saved.scrap), world.bank.scrap])
	if "--capture" in OS.get_cmdline_user_args():
		world.engagement.enabled = true
		world.rewards_hud.show_result({"victory": true, "dawn": true, "stars": 3, "kills": 12, "combo": 4, "scrap": 60, "record": 220, "goal": true})
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/validation/latest/ronda-resultado.png")
		world.rewards_hud.close_result()
	world.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guia_recorrido_test.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.engagement_path))
	print("PASS: guide_walkthrough; fallos: %d" % failures)
	quit(1 if failures else 0)
