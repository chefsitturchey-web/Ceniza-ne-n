extends RefCounted
## Preparación para pruebas centradas en expedición; la elegibilidad tiene suite propia.
static func stabilize(world: District) -> void:
	world.experience.present_choices = false
	if world.experience.panel.opened:
		world.experience.panel.select(world.experience.options(world.experience.panel.chest)[0])
	world.cycle.day = 2
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	world.expansion.sites[2].hp = 180
	for gate: EnemyRepeater in world.civic.gates: gate.restore(true)
