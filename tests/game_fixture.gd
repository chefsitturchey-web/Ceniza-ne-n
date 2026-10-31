extends RefCounted
## Preparación para pruebas centradas en expedición; la elegibilidad tiene suite propia.

## Las partidas nuevas empiezan sin núcleo (frontier_progression_test cubre la fundación).
## Las pruebas de sistemas posteriores parten de un núcleo Nv.1 ya encendido y parcelas
## despejadas (frontier_progression_test cubre los escombros).
static func found_colony(world: District) -> void:
	for plot: ClearanceSite in world.frontier.plots:
		plot.cleared = true
		plot.visible = false
	if world.core.tier > 0: return
	world.core.restore({"tier": 1, "ordered": false, "progress": 0})
	world.core.health = world.core.health_component.maximum
	world.clinic.visible = true

static func stabilize(world: District) -> void:
	found_colony(world)
	world.story.present_dialogue = false
	world.story.dialogue_queue.clear()
	world.experience.present_choices = false
	if world.experience.panel.opened:
		world.experience.panel.select(world.experience.options(world.experience.panel.chest)[0])
	world.cycle.day = 2
	if world.story != null:
		world.story.completed.assign([true, true, true])
		world.story.relay_ordered = true
		world.story.relay_progress = 6
		world.story.convoy_x = 0
	for site: ConstructionSite in world.construction.sites.slice(0, 4): site.complete_work()
	world.expansion.sites[2].hp = 180
	for gate: EnemyRepeater in world.civic.gates: gate.restore(true)
