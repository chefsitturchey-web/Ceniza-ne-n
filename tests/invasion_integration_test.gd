extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func create_world() -> District:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.experience.present_choices = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	return world

func run_checks() -> void:
	for zone: int in CampaignRoute.COUNT:
		var district: District = load(CampaignRoute.SCENES[zone]).instantiate() as District
		(district.get_node("Session") as SessionController).persistence_enabled = false
		root.add_child(district)
		for site: ConstructionSite in district.construction.sites:
			verify(district.interaction.target_at_x(site.x) == district.construction.sites.find(site), "Industrial loot cannot mask a foundation")
		for item: ScavengeProp in district.scavenge.props:
			verify(district.interaction.target_at_x(item.position.x) == district.scavenge.target_at(item.position.x), "Loot is reachable in every district")
		district.free()
	var world: District = create_world()
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = "user://invasion_integration_test.json"
	world.add_child(save)
	for prop: ScavengeProp in world.scavenge.props:
		verify(world.interaction.target_at_x(prop.position.x) == world.scavenge.target_at(prop.position.x), "Loot is reachable despite nearby buildings")
	var prop: ScavengeProp = world.scavenge.props[0]
	verify(world.interaction.required_hold(ScavengeSystem.TARGET_BASE) == prop.data.work_time, "Extraction uses the resource work duration")
	world.player.position.x = prop.position.x
	Input.action_press("interact")
	world.interaction.update_interaction(0)
	world.interaction.update_interaction(prop.data.work_time - 0.1)
	verify(world.bank.parts == 0, "Extraction cannot pay out early")
	world.interaction.update_interaction(0.1)
	Input.action_release("interact")
	verify(world.bank.parts == prop.data.parts_per_charge, "Holding E extracts parts")
	while not prop.depleted: world.scavenge.interact(ScavengeSystem.TARGET_BASE)
	world.bank.parts = 37
	world.workshop.shovel_ready = true
	world.cycle.day = 3
	var corpse: Corpse = world.corpse_system.spawn(Vector2(80, GameRules.FLOOR_Y), &"worker", 1)
	corpse.reported = true
	corpse.bury_progress = 1.25
	corpse.rat_timer = 11
	world.colony.workers[0].health_component.reset(23)
	world.trap_system.arm_trap()
	world.trap_system.traps[0].cooldown = 2
	var turret: ConstructionSite = world.construction.sites[1]
	turret.complete_work()
	turret.shorted = true
	turret.powered = false
	world.pest_system._on_rat_spawn(corpse)
	var rat: SewerRat = world.pest_system.rats[0]
	rat.state = SewerRat.State.FLEE
	rat.chew_time = 0.25
	world.pest_system._begin_flee(rat)
	verify(rat.exit_x != 0, "A rat at the origin has an exit")
	verify(save.save_game(), "New mechanics can be saved")
	var expected: Dictionary = save._snapshot()
	world.bank.parts = 0
	world.workshop.shovel_ready = false
	prop.charges_left = 999
	verify(save.load_game(), "New mechanics can be restored")
	verify(JSON.stringify(save._snapshot()) == JSON.stringify(expected), "Exact round trip includes loot, casualties, traps, rats and shorts")
	verify(world.bank.parts == 37 and prop.depleted and prop.charges_left == 0, "Reloading does not duplicate loot")
	verify(world.colony.workers[0].hp == 23 and turret.shorted and not turret.powered, "Injuries and short circuits persist")
	var invalid: Dictionary = expected.duplicate(true)
	invalid.invasion.parts = -1
	verify(not save._valid(invalid), "Negative parts are rejected")
	invalid = expected.duplicate(true)
	invalid.invasion.rats[0].target = 999
	verify(not save._valid(invalid), "Invalid rat references are rejected")
	invalid = expected.duplicate(true)
	invalid.invasion.props[0].charges = 999
	verify(not save._valid(invalid), "Invalid loot charges are rejected")
	world.player.position.x = 80
	world.corpse_system.tick(0)
	verify(world.player.poison_dps == 2 and world.player.combat_visual.modulate.g < 1.01 and world.player.combat_visual.modulate.r < 1, "Decay poisons the player and tints the visible sprite")
	var health: int = world.player.health
	world.player._apply_poison(1)
	verify(world.player.health == health - 2, "Poison causes real damage")
	world.colony.workers[0].x = 80
	world.colony.update_workers(2)
	world.corpse_system.tick(0)
	verify(world.corpse_system.corpses.is_empty() and world.player.poison_dps == 0, "Reported corpses are buried by a builder and clear the aura")
	world.bank.energy_capacity = 0
	verify(not world.construction.repair_short(turret) and turret.shorted, "Repair cannot overdraw energy")
	world.bank.energy_capacity = 100
	verify(world.construction.repair_short(turret) and turret.powered, "Repair restores a powered machine when capacity permits")
	rat = world.pest_system.rats[0]
	rat.position.x = -400
	rat.state = SewerRat.State.DART
	rat.target_site = turret
	world.trap_system.traps[0].cooldown = 0
	world.pest_system._update_rat(rat, 1.0)
	verify(rat.is_queued_for_deletion() and world.trap_system.traps[0].cooldown == TrapSystem.TRAP_COOLDOWN, "A trap catches a rat crossing its area during a long frame")
	await process_frame
	world.pest_system.tick(0)
	world.pest_system._on_rat_spawn(world.corpse_system.spawn(Vector2(0, GameRules.FLOOR_Y), &"worker", 3))
	rat = world.pest_system.rats[0]
	rat.state = SewerRat.State.HIDE
	rat.target_site = null
	world.pest_system._update_rat(rat, 0)
	verify(rat.state != SewerRat.State.HIDE, "A missing machine target is safely replaced")
	for remains: Corpse in world.corpse_system.corpses: remains.free()
	world.corpse_system.corpses.clear()
	var before: int = world.colony.workers.size()
	world.colony.workers[0].health_component.reset(0)
	world.colony.update_workers(0)
	verify(world.colony.workers.size() == before - 1 and world.corpse_system.corpses.size() == 1, "A dead worker leaves one corpse and leaves the population")
	for worker: ColonyWorker in world.colony.workers: worker.free()
	world.colony.workers.clear()
	verify(save.save_game() and save.load_game() and world.colony.workers.is_empty(), "A depleted colony is saved without resurrecting workers")
	var legacy: Dictionary = save._snapshot()
	legacy.erase("invasion")
	world.colony.add_worker(&"builder")
	world.colony.add_worker(&"collector")
	legacy.workers = save._snapshot().workers
	for entry: Dictionary in legacy.workers:
		for key: String in ["hp", "damage_accum", "wander_target", "wander_timer"]: entry.erase(key)
	for entry: Dictionary in legacy.structures: entry.erase("shorted")
	verify(save._valid(legacy), "Version 1 checkpoints without invasion state remain valid")
	var arena_player: TopdownPlayer = TopdownPlayer.new()
	root.add_child(arena_player)
	arena_player.set_physics_process(false)
	arena_player.copy_from(world.player)
	verify(arena_player.speed == 220 and Player.DODGE_COST == 30 and Player.COLONY_DODGE_COST == 20, "Arena speed and dodge cost remain independent from colony balancing")
	arena_player.free()
	save.delete_save()
	world.free()
	await process_frame
	print("Invasion: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
