extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func create_world(zone: int) -> District:
	var world: District = load(CampaignRoute.SCENES[zone]).instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.story.present_dialogue = false
	world.story.dialogue_queue.clear()
	world.experience.present_choices = false
	return world

func step(world: District, seconds: float) -> void:
	for index: int in ceili(seconds * 10):
		world.colony.update_workers(0.1)
		world.frontier.tick(0.1)
		world.expansion.tick(0.1)

func run_checks() -> void:
	var signatures: Array[String] = []
	for zone: int in 5:
		var world: District = create_world(zone)
		var save: SaveSystem = SaveSystem.new()
		save.session = world.session
		save.save_path = "user://frontier_progression_test.json"
		world.add_child(save)
		verify(save.save_game() and save.load_game() and world.core.tier == 0, "The unbuilt starting camp is a valid checkpoint")
		if "--capture" in OS.get_cmdline_user_args() and zone == 0: await capture(world, "arrival")
		verify(world.core.tier == 0 and not world.core.ordered, "New districts begin without a core")
		verify((world.get_node("Floor/Shape").shape as RectangleShape2D).size.x == 14400, "Floor is 4.5 times wider")
		verify((world.player.get_node("Camera2D") as Camera2D).limit_right == 7200, "Camera reaches the new edge")
		verify(world.expansion.sites.size() == 16 and world.civic.walls.size() == 12 and world.construction.sites.size() >= 14, "Extended buildable perimeter")
		for plot: ClearanceSite in world.frontier.plots: plot.cleared = true
		for index: int in world.expansion.sites.size():
			verify(world.interaction.target_at_x(world.expansion.sites[index].position.x, true) == -100 - index, "A building lot cannot be hidden behind another interaction")
		verify(world.interaction.target_at_x(MobilitySystem.PAD_X, true) == InteractionSystem.MOBILITY_TARGET, "Transport stays accessible in every district")
		for plot: ClearanceSite in world.frontier.plots: plot.cleared = false
		var signature: String = str(FrontierLayout.wall_positions(zone))
		verify(signature not in signatures, "Each district has its own construction plan")
		signatures.append(signature)
		world.bank.scrap = 500
		verify(not world.construction.order(1) and not world.core.request_upgrade(), "Cannot build a turret or a core without its requirements")
		var starter: int = world.scavenge.props.size() - 2
		for index: int in [starter, starter, starter + 1]: world.scavenge.interact(ScavengeSystem.TARGET_BASE - index)
		verify(world.bank.parts == 12, "Starter salvage supplies the real core cost")
		verify(world.core.request_upgrade() and world.core.tier == 0, "Core is commissioned rather than instantly appearing")
		step(world, 25)
		verify(world.core.tier == 1 and world.bank.parts == 0, "A real builder finishes the first core")
		verify(not world.construction.order(1), "Turrets remain locked at core level one")
		verify(world.construction.order(0) and world.construction.order(2), "Level one permits central walls")
		step(world, 55)
		var generator: ExpansionOutpost = world.expansion.sites[2]
		verify(not world.expansion.interact(-102), "Blocked lots reject construction")
		var plot: ClearanceSite
		for candidate: ClearanceSite in world.frontier.plots:
			if absf(candidate.position.x - generator.position.x) < 1: plot = candidate
		verify(plot != null and world.frontier.interact(FrontierSystem.CLEAR_BASE - world.frontier.plots.find(plot)), "Clearing is assigned to workers")
		step(world, 90)
		verify(plot.cleared and not world.frontier.blocked(generator.position.x), "Workers travel and clear a real lot")
		verify(world.expansion.interact(-102), "Cleared generator can be commissioned")
		step(world, 75)
		world.bank.add_parts(20)
		world.player.position.x = 0
		world.frontier.tick(0)
		verify(world.bank.parts == 0 and world.bank.stored_parts >= 20, "Returning to the core unloads the backpack")
		verify(world.core.request_upgrade(), "Walls plus generator unlock level two without requiring turrets")
		step(world, 75)
		verify(world.core.tier == 2 and world.construction.order(1), "Level two unlocks turrets")
		if "--capture" in OS.get_cmdline_user_args() and zone == 0: await capture(world, "settlement")
		for salvage: ScavengeProp in world.scavenge.props:
			verify(world.interaction.target_at_x(salvage.position.x) == world.scavenge.target_at(salvage.position.x), "Salvage remains reachable after buildings unlock")
		world.player.position.x = 6000
		world.bank.add_parts(40)
		verify(world.bank.parts == 24 and not world.frontier.drops.is_empty(), "Excess pieces fall instead of exceeding bag capacity")
		verify(save.save_game(), "Expanded colony state can be saved")
		var before: Dictionary = save._snapshot()
		world.bank.parts = 0
		world.bank.stored_parts = 0
		plot.cleared = false
		verify(save.load_game() and world.bank.parts == 24 and plot.cleared, "Loading restores backpack, depot and clearing progress")
		if JSON.stringify(save._snapshot()) != JSON.stringify(before):
			FileAccess.open("res://build/validation/latest/frontier-before.json", FileAccess.WRITE).store_string(JSON.stringify(before))
			FileAccess.open("res://build/validation/latest/frontier-after.json", FileAccess.WRITE).store_string(JSON.stringify(save._snapshot()))
		verify(JSON.stringify(save._snapshot()) == JSON.stringify(before), "Checkpoint round trip preserves the whole expanded colony")
		var legacy: Dictionary = before.duplicate(true)
		legacy.erase("frontier")
		legacy.structures.resize(4)
		legacy.civic.walls.resize(6)
		legacy.expansion.sites.resize(8)
		legacy.invasion.props.resize(world.zone.prop_spots.size())
		legacy.invasion.parts = 37
		verify(save._valid(legacy) and save.write_document(legacy) and save.load_game(), "Legacy colonies migrate into the extended map")
		verify(world.bank.parts == 24 and world.bank.stored_parts == int(before.stored_parts) + 13, "Legacy excess inventory is preserved in the depot")
		if zone == 0:
			var transfer: Dictionary = CampaignRoute.handoff(1, world.neural.snapshot(), world.bank.scrap, world.colony.workers, world.mobility.snapshot())
			transfer["carried_parts"] = world.bank.parts
			var destination: District = create_world(1)
			var importer: SaveSystem = SaveSystem.new()
			importer.session = destination.session
			destination.add_child(importer)
			verify(CampaignRoute.valid_handoff(transfer), "The train accepts a bounded backpack inventory")
			importer.apply_handoff(transfer)
			verify(destination.bank.parts == 24 and destination.core.tier == 0, "The train carries the backpack into a new unbuilt district")
			destination.free()
		for section: String in ["opening", "foundation", "expansion", "ending"]:
			var scene: Dictionary = VisualStory.scene(zone, section)
			verify(VisualStory.valid_key(scene.id) and scene.lines.size() >= 2, "Playable story includes beginning, settlement and ending")
		var arena_player: TopdownPlayer = TopdownPlayer.new()
		root.add_child(arena_player)
		arena_player.set_physics_process(false)
		arena_player.copy_from(world.player)
		verify(arena_player.speed == 220 and Player.DODGE_COST == 30, "Boss movement and dodge remain unchanged")
		arena_player.free()
		save.delete_save()
		world.free()
	await process_frame
	print("Frontera: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func capture(world: District, name: String) -> void:
	var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	world.player.position.x = 0
	camera.force_update_scroll()
	world.presenter.publish()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/validation/latest/frontier-%s.png" % name)
