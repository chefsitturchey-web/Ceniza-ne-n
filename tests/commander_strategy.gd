extends RefCounted
## Estrategia de prueba con precios reales: suministros, energía, cuarteles y reclutas.
var tasks: Array[int] = [-200, -201, -202, -203, -204, -205, -102, -1, -100, -104, -322, -323, -322, -323, -300, -300, -301, -301]
var index: int = 0

func tick(world: District, delta: float) -> bool:
	if index >= tasks.size() or world.cycle.phase != "DÍA": return false
	var target: int = tasks[index]
	var x: float = 0
	if target == -1:
		if world.core.tier >= 2:
			index += 1
			return true
	elif target <= -300:
		x = (-1340 if target == -300 else 1340) if target in [-300, -301] else CivicSystem.RACK_X[-320 - target]
	elif target <= -200: x = ExpansionSystem.CACHE_X[-200 - target]
	else:
		var site: ExpansionOutpost = world.expansion.sites[-100 - target]
		if site.hp > 0:
			index += 1
			return true
		x = site.position.x
	world.player.position.x = move_toward(world.player.position.x, x, world.player.speed * Player.COLONY_MOVEMENT_FACTOR * delta)
	if absf(world.player.position.x - x) < 12:
		if target == -1:
			if not world.core.ordered: world.core.request_upgrade()
		elif target <= -300:
			if world.civic.interact(target): index += 1
		elif target <= -200:
			if world.expansion.interact(target): index += 1
		else:
			var site: ExpansionOutpost = world.expansion.sites[-100 - target]
			if not site.ordered: world.expansion.interact(target)
	return true
