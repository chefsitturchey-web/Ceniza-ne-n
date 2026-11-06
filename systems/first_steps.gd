class_name FirstSteps
extends Node
## Observa el estado real; no ejecuta interacciones ni altera el reloj.
signal completed(step: int, reward: int)
signal hint_changed
var world: District
var step: int = 0
var idle: float = 0
var origin: float = 0
var enabled: bool = true
var persist: bool = true
var collected: int = 0
var last_parts: int = 0
var useful_position: float = 0
var useful_progress: float = 0
const COUNT: int = 11
const LINES: Array[String] = ["Camina hacia la batería", "Recupera 12 piezas", "Funda el núcleo", "Levanta las dos murallas", "Despeja la parcela", "Construye el generador", "Recupera 10 piezas más", "Mejora el núcleo a nivel 2", "Levanta las dos torretas", "Prepara la noche", "Resiste hasta el amanecer"]

func setup(district: District) -> void:
	world = district
	persist = world.session.persistence_enabled and not world.session.debug_practice
	enabled = persist
	step = int(SaveSystem.engagement_profile().guide)
	# Un checkpoint anterior o una campaña nueva pueden carecer de obras ya enseñadas.
	# Volver a indicarlas no vuelve a pagar las recompensas del perfil.
	if step < COUNT and step > 1 and world.core.tier == 0: step = 1
	if step < COUNT and world.core.tier > 0:
		var walls: int = 0
		for site: ConstructionSite in world.construction.sites:
			if site.data.blocks_enemies and site.hp > 0: walls += 1
		if walls < 2: step = mini(step, 3)
		elif world.expansion.energy_bonus() == 0: step = mini(step, 4)
		elif world.core.tier < 2: step = mini(step, 6)
	origin = world.player.position.x
	useful_position = origin
	last_parts = world.bank.parts
	world.bank.parts_changed.connect(func(amount: int) -> void:
		if amount > last_parts: collected += amount - last_parts; idle = 0
		last_parts = amount)

func restart() -> void:
	step = 0
	collected = 0
	origin = world.player.position.x
	idle = 0
	enabled = true
	if persist:
		var profile: Dictionary = SaveSystem.engagement_profile()
		profile.guide = 0
		SaveSystem.store_engagement(profile)
	hint_changed.emit()

func write_progress() -> void:
	if not persist: return
	var profile: Dictionary = SaveSystem.engagement_profile()
	profile.guide = maxi(int(profile.guide), step)
	SaveSystem.store_engagement(profile)

func tick(delta: float) -> void:
	if not enabled or world.session.debug_practice or step >= LINES.size(): return
	idle += delta
	var progress: float = world.core.progress
	for site: ConstructionSite in world.construction.sites: progress += site.progress
	for plot: ClearanceSite in world.frontier.plots: progress += plot.progress
	for site: ExpansionOutpost in world.expansion.sites: progress += site.progress
	if absf(world.player.position.x - useful_position) > 8 or progress > useful_progress:
		idle = 0
		useful_position = world.player.position.x
	useful_progress = progress
	var walls: int = 0
	for site: ConstructionSite in world.construction.sites:
		if site.data.blocks_enemies and site.hp > 0: walls += 1
	var done: bool = false
	match step:
		0: done = absf(world.player.position.x - origin) >= 32
		1: done = collected >= 12 or world.bank.parts + world.bank.stored_parts >= 12 or world.core.ordered or world.core.tier > 0
		2: done = world.core.tier > 0
		3: done = walls >= 2
		4: done = not world.frontier.blocked(generator().position.x)
		5: done = world.expansion.energy_bonus() > 0
		6: done = world.bank.parts + world.bank.stored_parts >= 10 or world.core.tier >= 2 or world.core.ordered
		7: done = world.core.tier >= 2
		8:
			var turrets: int = 0
			for site: ConstructionSite in world.construction.sites:
				if not site.data.blocks_enemies and site.hp > 0: turrets += 1
			done = turrets >= 2
		9: done = world.cycle.phase != "DÍA" or world.cycle.day > 1
		10: done = world.cycle.day > 1
	if done:
		var finished_step: int = step
		step += 1
		idle = 0
		var reward: int = 8 if not persist or finished_step >= int(SaveSystem.engagement_profile().guide) else 0
		world.bank.deposit(reward)
		write_progress()
		if persist and world.cycle.phase == "DÍA" and world.session.save_system != null:
			world.session.save_system.save_game()
		completed.emit(finished_step, reward)
		hint_changed.emit()

func generator() -> ExpansionOutpost:
	return world.expansion.sites[2]

func waiting() -> bool:
	if step == 10: return true
	if step in [2, 7]: return world.core.ordered
	if step == 5: return generator().ordered
	if step == 4:
		for plot: ClearanceSite in world.frontier.plots:
			if absf(plot.position.x - generator().position.x) < 1: return plot.ordered
	if step in [3, 8]:
		for site: ConstructionSite in world.construction.sites:
			if site.ordered: return true
	return false

func target() -> Vector2:
	if step <= 1 or step == 6:
		var best: Vector2 = Vector2(75, GameRules.FLOOR_Y)
		var distance: float = INF
		for prop: ScavengeProp in world.scavenge.props:
			if not prop.depleted and absf(prop.position.x - world.player.position.x) < distance:
				distance = absf(prop.position.x - world.player.position.x)
				best = prop.global_position
		return best
	if step == 3:
		for site: ConstructionSite in world.construction.sites:
			if site.data.blocks_enemies and site.hp <= 0: return Vector2(site.x, GameRules.FLOOR_Y)
	if step in [4, 5]: return generator().global_position
	if step == 8:
		for site: ConstructionSite in world.construction.sites:
			if not site.data.blocks_enemies and site.hp <= 0: return Vector2(site.x, GameRules.FLOOR_Y)
	return world.core.global_position

func caption() -> String:
	if step >= LINES.size(): return ""
	if step in [2, 7] and world.core.ordered: return "Tu constructor enciende el núcleo"
	if step in [3, 8]:
		for site: ConstructionSite in world.construction.sites:
			if site.ordered: return "Obra en marcha. Protege al constructor"
	if step == 4:
		for plot: ClearanceSite in world.frontier.plots:
			if absf(plot.position.x - generator().position.x) < 1 and plot.ordered: return "Tu constructor despeja la parcela"
	if step == 5 and generator().ordered: return "Tu constructor monta el generador"
	if step == 9: return "En el núcleo: mantén para anochecer"
	return ("Mantén: " if step > 0 and step < 10 else "") + LINES[step]
