extends SceneTree
## Trazado por campaña: cada semilla crea distritos distintos, accesibles y que se guardan igual.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func district(zone: int) -> District:
	var world: District = load(CampaignRoute.SCENES[zone]).instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	return world

func signature(world: District) -> String:
	var walls: Array = world.civic.walls.map(func(wall: ConstructionSite) -> float: return wall.x)
	return str(walls) + str(world.story.rescue_x) + str(world.story.convoy_x) + str(world.settlements.sites.map(func(site: Node2D) -> float: return site.position.x))

func run_checks() -> void:
	GamePreferences.current().briefing_requested = false
	for zone: int in CampaignRoute.COUNT:
		FrontierLayout.active_seed = 0
		var reference: District = district(zone)
		var base: String = signature(reference)
		reference.free()
		var seen: Array[String] = []
		for seed: int in [104729, 1299709]:
			FrontierLayout.active_seed = seed
			var world: District = district(zone)
			load("res://tests/game_fixture.gd").found_colony(world)
			var layout: String = signature(world)
			verify(layout != base and layout not in seen, "La semilla %d cambia el distrito %d" % [seed, zone])
			seen.append(layout)
			for site: ConstructionSite in world.construction.sites:
				verify(world.interaction.target_at_x(site.x) == world.construction.sites.find(site), "Cimiento accesible zona %d x=%d" % [zone, int(site.x)])
			for item: ScavengeProp in world.scavenge.props:
				verify(world.interaction.target_at_x(item.position.x) == world.scavenge.target_at(item.position.x), "Botín accesible zona %d" % zone)
			for operation: float in [world.story.rescue_x, world.story.relay_x, world.story.convoy_x]:
				verify(absf(operation) < GameRules.MAP_HALF_WIDTH - 300, "Operación dentro del mapa zona %d" % zone)
			verify(absf(world.story.convoy_x) > absf(world.story.rescue_x), "El transporte queda más lejos que el rescate")
			var save: SaveSystem = SaveSystem.new()
			save.session = world.session
			save.save_path = "user://seeded_world_test.json"
			world.add_child(save)
			verify(save.save_game(), "Guarda con semilla zona %d" % zone)
			verify(SaveSystem.checkpoint_info(save.save_path).get("seed") == seed, "El guardado conserva la semilla")
			verify(save.load_game() and signature(world) == layout, "Cargar mantiene el trazado")
			verify(CampaignRoute.handoff(mini(zone + 1, 4), world.neural.snapshot(), 50, world.colony.workers).layout_seed == seed, "El viaje conserva la semilla")
			save.delete_save()
			world.free()
			await process_frame
	FrontierLayout.active_seed = 0
	print("Trazado por campaña: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
