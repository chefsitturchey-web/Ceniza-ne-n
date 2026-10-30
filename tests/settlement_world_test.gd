extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func step(world: District, seconds: float) -> void:
	for index: int in ceili(seconds * 10):
		world.colony.update_workers(0.1)
		world.frontier.tick(0.1)
		world.settlements.tick(0.1)
		world.expansion.tick(0.1)

func run_checks() -> void:
	for zone: int in 5:
		var world: District = load(CampaignRoute.SCENES[zone]).instantiate() as District
		(world.get_node("Session") as SessionController).persistence_enabled = false
		root.add_child(world)
		world.session.set_process(false)
		world.player.set_physics_process(false)
		world.story.present_dialogue = false
		world.story.dialogue_queue.clear()
		world.experience.present_choices = false
		var city: SettlementSystem = world.settlements
		verify(city.sites.size() == 3 and city.caches.size() == 6 and world.settlement_backdrop != null, "District has recoverable settlements and technology caches")
		for index: int in 3: verify(world.interaction.target_at_x(city.sites[index].position.x, true) == SettlementSystem.TARGET_BASE - index, "Support buildings remain selectable")
		for index: int in 6: verify(world.interaction.target_at_x(city.caches[index].position.x, true) == SettlementSystem.CACHE_BASE - index, "Technology caches remain selectable")
		for index: int in world.scavenge.props.size(): verify(world.interaction.target_at_x(world.scavenge.props[index].position.x, true) == ScavengeSystem.TARGET_BASE - index, "Settlements do not mask ordinary salvage")
		verify(not city.interact(SettlementSystem.CACHE_BASE), "Technology requires an established camp")
		world.core.restore({"tier": 2, "ordered": false, "progress": 0})
		world.bank.scrap = 1000
		world.bank.stored_parts = 200
		for gate: EnemyRepeater in world.civic.gates: gate.restore(true)
		verify(not city.interact(SettlementSystem.TARGET_BASE), "Restoration cannot spend ordinary materials without its special component")
		if "--capture" in OS.get_cmdline_user_args() and zone == 0: await capture(world, "ruins", city.sites[0].position.x)
		for index: int in 6:
			verify(city.interact(SettlementSystem.CACHE_BASE - index) and not city.interact(SettlementSystem.CACHE_BASE - index), "Each technology cache pays out once")
		for index: int in 3:
			verify(city.interact(SettlementSystem.TARGET_BASE - index) and city.sites[index].tier == 0, "A real restoration job is commissioned")
			step(world, 130)
			verify(city.sites[index].tier == 1, "Builders travel to and complete settlement restoration")
		verify(is_equal_approx(world.colony.work_factor, 1.25) and is_equal_approx(world.defenses.settlement_damage_factor, 1.15), "Restored facilities activate construction and defence bonuses")
		var wall: ConstructionSite = world.construction.sites[0]
		wall.ordered = true
		var builder: ColonyWorker = world.colony.workers[0]
		builder.position.x = wall.x
		builder.external_job = -1
		builder.job = 0
		world.colony.update_workers(1)
		verify(is_equal_approx(wall.progress, 1.25), "Workshop bonus accelerates real construction work")
		wall.ordered = false
		wall.progress = 0
		builder.job = -1
		world.player.position.x = city.sites[2].position.x
		world.player.health = 40
		city.tick(1)
		verify(world.player.health == 43, "The dispensary heals inside its local area")
		world.player.position.x += 400
		city.tick(1)
		verify(world.player.health == 43, "Dispensary healing does not extend across the whole map")
		var turret: ConstructionSite = world.construction.sites[1]
		turret.complete_work()
		var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/errante.tres"))
		enemy.set_physics_process(false)
		enemy.position.x = turret.x + 70
		var health: int = enemy.health
		world.defenses.update_defenses(0)
		verify(health - enemy.health == roundi(FortressRules.damage(turret) * 1.15), "Armory bonus changes actual turret damage")
		enemy.free()
		verify(not city.interact(SettlementSystem.TARGET_BASE), "Advanced support upgrades require core level three")
		world.core.restore({"tier": 3, "ordered": false, "progress": 0})
		verify(city.interact(SettlementSystem.TARGET_BASE), "A second servomotor funds the advanced workshop")
		step(world, 160)
		verify(city.sites[0].tier == 2 and is_equal_approx(world.colony.work_factor, 1.5), "Support upgrades improve the earned bonus without duplicate stacking")
		var save: SaveSystem = SaveSystem.new()
		save.session = world.session
		save.save_path = "user://settlement_world_test.json"
		world.add_child(save)
		verify(save.save_game(), "Settlement state can be saved")
		var before: String = JSON.stringify(save._snapshot())
		city.restore({})
		verify(save.load_game() and before == JSON.stringify(save._snapshot()), "Technology, jobs and bonuses survive an exact checkpoint round trip")
		var bad: Dictionary = save._snapshot()
		bad.settlements.components[0] = 2
		verify(not save._valid(bad), "Checkpoint validation rejects duplicated special components")
		if "--capture" in OS.get_cmdline_user_args() and zone == 0:
			await capture(world, "restored", city.sites[2].position.x)
			world.story.journal.open_panel()
			world.story.journal.settlement_button.pressed.emit()
			await capture(world, "journal", city.sites[2].position.x)
			world.story.journal.close_panel()
		var legacy: Dictionary = save._snapshot()
		legacy.erase("settlements")
		verify(save.write_document(legacy) and save.load_game() and world.colony.work_factor == 1 and world.defenses.settlement_damage_factor == 1, "Older checkpoints add dormant settlements without free buffs")
		for prop: ScavengeProp in world.scavenge.props: verify(world.interaction.target_at_x(prop.position.x, true) == world.scavenge.target_at(prop.position.x), "Legacy loot remains accessible when settlements are added")
		save.delete_save()
		world.free()
	await process_frame
	print("Poblados: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func capture(world: District, name: String, x: float) -> void:
	world.player.position.x = x
	var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	world.presenter.publish()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/validation/latest/settlement-%s.png" % name)
