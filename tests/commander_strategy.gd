extends RefCounted
## Jugador de prueba que sigue el mismo orden que el objetivo del HUD (StoryDirector.objective):
## fundación, murallas, generador, núcleo Nv.2, torretas, cuartel y soldados, operaciones y portales.
## Usa precios, distancias y tiempos de E reales; refuerza las defensas centrales como haría un jugador.
var hold: float = 0
var hold_target: int = GameRules.NO_TARGET

func walk(world: District, x: float, delta: float) -> bool:
	world.player.position.x = move_toward(world.player.position.x, x, world.player.speed * Player.COLONY_MOVEMENT_FACTOR * delta)
	return absf(world.player.position.x - x) < 12

## Mantener E: devuelve true cuando la interacción se ejecutó.
func press(world: District, target: int, delta: float) -> bool:
	if target != hold_target:
		hold_target = target
		hold = 0
	hold += delta
	if hold < world.interaction.required_hold(target): return false
	hold = 0
	return world.interaction.perform_interaction(target)

func parts(world: District) -> int: return world.bank.parts + world.bank.stored_parts

## Recoge piezas del objeto de botín más cercano; false si no queda ninguno alcanzable.
func gather(world: District, delta: float) -> bool:
	if world.bank.parts >= world.bank.parts_capacity:
		walk(world, 0, delta)
		return true
	var best: int = -1
	for prop_index: int in world.scavenge.props.size():
		var prop: ScavengeProp = world.scavenge.props[prop_index]
		if prop.depleted or not world.civic.safe_to_build(prop.position.x): continue
		if best < 0 or absf(prop.position.x - world.player.position.x) < absf(world.scavenge.props[best].position.x - world.player.position.x): best = prop_index
	if best < 0: return false
	if walk(world, world.scavenge.props[best].position.x, delta):
		press(world, ScavengeSystem.TARGET_BASE - best, delta)
	return true

## Fase previa: extraer las baterías y encargar el primer núcleo.
func found(world: District, delta: float) -> bool:
	if world.core.tier > 0: return false
	if world.core.ordered: return true
	if parts(world) < world.core.parts_cost():
		gather(world, delta)
	elif walk(world, 0, delta):
		world.core.request_upgrade()
	return true

func nearest_outpost(world: District, id: String) -> ExpansionOutpost:
	var best: ExpansionOutpost
	for site: ExpansionOutpost in world.expansion.sites:
		if site.spec.id == id and world.civic.safe_to_build(site.position.x) and (best == null or absf(site.position.x) < absf(best.position.x)): best = site
	return best

## Despeja, paga y deja que los constructores levanten la instalación.
func build_outpost(world: District, id: String, delta: float) -> void:
	var site: ExpansionOutpost = nearest_outpost(world, id)
	if site.ordered or site.hp > 0: return
	for index: int in world.frontier.plots.size():
		var plot: ClearanceSite = world.frontier.plots[index]
		if not plot.cleared and absf(plot.position.x - site.position.x) < 45:
			if not plot.ordered and walk(world, plot.position.x, delta): world.frontier.interact(FrontierSystem.CLEAR_BASE - index)
			return
	if walk(world, site.position.x, delta): world.expansion.interact(-100 - world.expansion.sites.find(site))

## Encarga una obra con E sobre su cimiento.
func order(world: District, site: ConstructionSite, delta: float) -> void:
	if walk(world, site.x, delta): press(world, world.construction.sites.find(site), delta)

func recruit(world: District, delta: float) -> void:
	var camp: int = 0 if world.civic.camp_stock[0] > 0 else 1
	if walk(world, -1340 if camp == 0 else 1340, delta): world.civic.interact(-300 - camp)

func buy_tool(world: District, role: int, delta: float) -> void:
	if walk(world, CivicSystem.RACK_X[role], delta): world.civic.interact(-320 - role)

## Devuelve false cuando no queda nada que hacer en este momento.
func tick(world: District, delta: float) -> bool:
	if world.player.health <= 0: return false
	if found(world, delta): return true
	if world.cycle.phase != "DÍA":
		walk(world, 0, delta)
		return false
	var story: StoryDirector = world.story
	var central: Array[ConstructionSite] = world.construction.sites.slice(0, 4)
	if not world.colony.workers.any(func(worker: ColonyWorker) -> bool: return worker.role == &"builder"):
		if world.civic.tools[0] == 0: buy_tool(world, 0, delta)
		elif world.civic.villagers.is_empty(): recruit(world, delta)
		else: walk(world, -600, delta)
		return true
	for index: int in ExpansionSystem.CACHE_X.size():
		if not world.expansion.looted[index]:
			if walk(world, ExpansionSystem.CACHE_X[index], delta): world.expansion.interact(-200 - index)
			return true
	for site: ConstructionSite in central:
		if site.data.blocks_enemies and site.hp <= 0 and not site.ordered:
			if world.bank.scrap >= site.cost: order(world, site, delta)
			return true
	if world.expansion.energy_bonus() == 0:
		build_outpost(world, "generator", delta)
		return true
	if world.core.tier < 2:
		if world.core.ordered: return false
		if parts(world) < world.core.parts_cost():
			gather(world, delta)
		elif world.bank.scrap >= world.core.upgrade_cost() and walk(world, 0, delta):
			world.core.request_upgrade()
		return true
	for site: ConstructionSite in central:
		if site.kind == &"turret" and site.hp <= 0 and not site.ordered:
			if world.bank.scrap >= site.cost: order(world, site, delta)
			return true
	# Reparar y reforzar antes de seguir con la historia: la segunda noche trae blindados.
	if world.bank.scrap >= 60:
		for site: ConstructionSite in central:
			if site.hp > 0 and not site.ordered and (site.hp < site.max_hp or site.tier < world.core.tier):
				order(world, site, delta)
				return true
	if story.soldiers() < 2:
		if nearest_outpost(world, "barracks").hp <= 0:
			build_outpost(world, "barracks", delta)
			return true
		var pending: int = world.civic.tools[2] + world.civic.tools[3]
		if story.soldiers() + pending < 2: buy_tool(world, 2, delta)
		elif world.civic.villagers.size() < pending: recruit(world, delta)
		else: walk(world, -600, delta)
		return true
	if world.core.tier == 2 and not world.core.ordered and world.core.upgrade_blocker().is_empty():
		if parts(world) < world.core.parts_cost():
			if gather(world, delta): return true
		elif world.bank.scrap >= world.core.upgrade_cost():
			if walk(world, 0, delta): world.core.request_upgrade()
			return true
	if world.core.tier == 2 and world.cycle.day >= 2 and nearest_outpost(world, "barracks").hp > 0 and world.expansion.sites.filter(func(site: ExpansionOutpost) -> bool: return site.hp > 0).size() < 2:
		build_outpost(world, "medical", delta)
		return true
	var guard: Dictionary = story.protection_target()
	if not guard.is_empty():
		var wall: ConstructionSite = guard.wall
		if world.bank.scrap >= wall.cost and walk(world, wall.x, delta): world.civic.interact(-340 - world.civic.walls.find(wall))
		return true
	if not story.completed[0]:
		if walk(world, story.rescue_x, delta): story.interact(-400)
		return true
	if not story.completed[1]:
		if not story.relay_ordered:
			if world.bank.scrap >= 30 and walk(world, story.relay_x, delta): story.interact(-401)
			return true
		var technician: bool = false
		for ally: Node in world.get_tree().get_nodes_in_group(GameRules.ALLIES):
			if ally is FieldAlly and ally.role == "technician" and ally.hp > 0: technician = true
		if technician: return false
		if world.civic.tools[4] == 0: buy_tool(world, 4, delta)
		elif world.civic.villagers.is_empty(): recruit(world, delta)
		else: walk(world, -600, delta)
		return true
	if not story.completed[2]:
		if story.convoy_health <= 0:
			if world.bank.scrap >= 25 and walk(world, story.convoy_x, delta): story.interact(-402)
		elif not story.convoy_active:
			if walk(world, story.convoy_x, delta): story.interact(-402)
		else:
			walk(world, story.convoy_x, delta)
		return true
	for portal: EnemyRepeater in world.civic.gates + world.expedition.repeaters:
		if portal.health.current > 0:
			world.civic.advance_side = int(signf(portal.position.x))
			walk(world, 0, delta)
			return true
	return false
