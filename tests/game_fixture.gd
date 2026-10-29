extends RefCounted
## Preparación para pruebas centradas en expedición; la elegibilidad tiene suite propia.
static func stabilize(world: District) -> void:
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
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	world.expansion.sites[2].hp = 180
	for gate: EnemyRepeater in world.civic.gates: gate.restore(true)
