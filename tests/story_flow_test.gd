extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func close_novel(panel: NovelPanel) -> void:
	await create_timer(0.4, true).timeout
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_START
	event.pressed = true
	panel._input(event)
	await create_timer(0.3, true).timeout
	verify(not panel.opened and not paused, "Start omite y devuelve la pausa")

func run_checks() -> void:
	RecaudadorArena.practice_seen.clear()
	var world: District = load("res://levels/main.tscn").instantiate()
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.first_steps.enabled = true
	world.first_steps.step = 0
	await process_frame
	await process_frame
	verify(world.story.novel.opened and world.story.novel.scene_data.id == "0:opening", "Llegada automatica durante la guia inicial")
	await close_novel(world.story.novel)
	world.story.set_process(false)
	world.experience.present_choices = false
	var referenced: Array[String] = []
	for zone: int in range(CampaignRoute.COUNT):
		world.zone_index = zone
		world.story.seen_scenes.clear()
		world.story.dialogue_queue.clear()
		world.core.tier = 1
		world.frontier.plots[0].cleared = true
		world.story.completed.assign([true, true, true])
		world.story.queue_milestones()
		for scene: Dictionary in world.story.dialogue_queue: referenced.append(scene.id)
		var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.configure(world.player, zone)
		root.add_child(arena)
		verify(arena.novel.opened and paused, "Entrada automatica: %d" % zone)
		referenced.append(arena.novel.scene_data.id)
		if arena.spectacle != null:
			verify(not arena.spectacle.intro_started, "La novela precede a la camara")
		var before: Vector2 = arena.player.position
		await process_frame
		verify(arena.player.position == before, "Combate detenido durante la novela")
		await close_novel(arena.novel)
		verify("%d:encounter" % zone in world.story.seen_scenes, "Encuentro registrado en la partida")
		if arena.spectacle != null: verify(arena.spectacle.intro_started, "Camara tras el dialogo")
		arena.finish(true)
		arena._process(0.1)
		verify(not arena.novel.opened and not arena.emitted, "La muerte precede al desenlace")
		arena.ending_timer = 0
		arena._process(0)
		verify(arena.novel.opened and not arena.emitted and not arena.completed, "Desenlace antes del resultado")
		referenced.append(arena.novel.scene_data.id)
		await close_novel(arena.novel)
		arena._process(0)
		verify(arena.emitted, "Resultado tras cerrar el desenlace")
		arena.free()
		arena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.configure(world.player, zone)
		root.add_child(arena)
		verify(not arena.novel.opened and not paused, "Reintentar no repite el encuentro")
		arena.free()
		arena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.zone_index = zone
		arena.present_story = true
		arena.rush = true
		root.add_child(arena)
		verify(not arena.novel.opened, "Rush excluye la entrada aun con historia habilitada")
		arena.finish(true)
		arena.ending_timer = 0
		arena._process(0)
		verify(not arena.novel.opened and arena.emitted, "Rush excluye el desenlace")
		arena.free()
	for zone: int in range(CampaignRoute.COUNT):
		for section: String in VisualStory.SECTIONS:
			verify("%d:%s" % [zone, section] in referenced, "Disparador alcanzable: %d:%s" % [zone, section])
	var snapshot: Dictionary = world.story.snapshot()
	world.story.restore(snapshot)
	verify(world.story.seen_scenes == snapshot.seen_scenes, "Las escenas vistas sobreviven a restaurar")
	var handoff: Dictionary = CampaignRoute.handoff(1, world.neural.snapshot(), world.bank.scrap, world.colony.workers)
	verify(CampaignRoute.valid_handoff(handoff), "Traspaso antiguo sin historial sigue siendo valido")
	handoff["story_seen"] = ["0:encounter", "0:ending"]
	verify(CampaignRoute.valid_handoff(handoff), "Traspaso admite historial narrativo")
	var saver: SaveSystem = SaveSystem.new()
	saver.session = world.session
	saver.apply_handoff(handoff)
	verify(world.story.seen_scenes == ["0:encounter", "0:ending"], "El distrito siguiente recupera el historial")
	saver.free()
	handoff.story_seen.append("0:ending")
	verify(not CampaignRoute.valid_handoff(handoff), "Traspaso rechaza duplicados")
	handoff.story_seen = ["9:opening"]
	verify(not CampaignRoute.valid_handoff(handoff), "Traspaso rechaza escenas inexistentes")
	world.free()
	var standalone: RecaudadorArena = load("res://levels/expedition/mother_arena.tscn").instantiate()
	root.add_child(standalone)
	current_scene = standalone
	await process_frame
	await process_frame
	verify(standalone.novel.opened and standalone.novel.scene_data.id == "4:encounter", "Abrir la escena independiente inicia la novela")
	await close_novel(standalone.novel)
	standalone.free()
	RecaudadorArena.practice_seen.clear()
	await process_frame
	print("Flujo de historia: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
