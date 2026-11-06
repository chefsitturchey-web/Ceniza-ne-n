class_name FirstSteps
extends Node
## Observa el estado real; no ejecuta interacciones ni altera el reloj.
## Tras los 11 pasos quedan consejos de una sola vez (TIPS): aparecen la primera vez
## que son útiles, con flecha al lugar, y se guardan en el perfil (clave "tips").
signal completed(step: int, reward: int)
signal tip_completed(id: String, reward: int)
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
## Consejos ya vistos o resueltos (persisten en el perfil) y el que está en pantalla.
var tips_done: Array = []
var tip: String = ""
var tip_time: float = 0
var tip_baseline: int = 0
## Paneles que pausan el juego: se anotan al abrirse porque tick() no corre en pausa.
var panels_seen: Dictionary = {}
## Orden de prioridad; cada consejo tiene relevancia, objetivo, texto y condición de hecho.
const TIPS: Array[String] = ["overload", "journal", "recruit", "arsenal", "refuge", "portal", "clinic"]
const TIP_REWARD: int = 4
## Un consejo ignorado tanto tiempo se da por visto y deja paso al siguiente.
const TIP_TIMEOUT: float = 45.0
const CAMP_X: Array[float] = [-1340.0, 1340.0]
const ARSENAL_X: float = -600.0
const TIP_KEYS: Dictionary = {"overload": "overload", "journal": "journal", "portal": "escort"}
const COUNT: int = 11
const LINES: Array[String] = ["Camina hacia la batería", "Recupera 12 piezas", "Funda el núcleo", "Levanta las dos murallas", "Despeja la parcela", "Construye el generador", "Recupera 10 piezas más", "Mejora el núcleo a nivel 2", "Levanta las dos torretas", "Prepara la noche", "Resiste hasta el amanecer"]

func setup(district: District) -> void:
	world = district
	persist = world.session.persistence_enabled and not world.session.debug_practice
	enabled = persist
	step = int(SaveSystem.engagement_profile().guide)
	tips_done = SaveSystem.engagement_profile().tips.duplicate()
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if world == null: return
	if world.equipment_shop != null and world.equipment_shop.opened: panels_seen.arsenal = true
	if world.story != null and world.story.journal.opened: panels_seen.journal = true
	if world.clinic_panel.opened: panels_seen.clinic = true

func restart() -> void:
	step = 0
	tip = ""
	tips_done.clear()
	panels_seen.clear()
	collected = 0
	origin = world.player.position.x
	idle = 0
	enabled = true
	if persist:
		var profile: Dictionary = SaveSystem.engagement_profile()
		profile.guide = 0
		profile.tips = []
		SaveSystem.store_engagement(profile)
	hint_changed.emit()

func write_progress() -> void:
	if not persist: return
	var profile: Dictionary = SaveSystem.engagement_profile()
	profile.guide = maxi(int(profile.guide), step)
	SaveSystem.store_engagement(profile)

func tick(delta: float) -> void:
	if not enabled or world.session.debug_practice: return
	tick_tips(delta)
	if step >= LINES.size(): return
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
	if showing_tip(): return false
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
	if showing_tip(): return tip_target(tip)
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

## Acción que el cartel muestra junto al texto; vacío si solo hay que esperar.
func key_action() -> String:
	if showing_tip(): return TIP_KEYS.get(tip, "interact")
	if waiting(): return ""
	return "move" if step == 0 else "interact"

func caption() -> String:
	if showing_tip(): return InputGlyphs.fill(tip_caption(tip))
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
	# La tecla o el botón va en el recuadro del cartel (key_action), delante del texto.
	return ("Mantén: " if step > 0 and step < 10 else "") + LINES[step]

# --- Consejos de una sola vez -------------------------------------------------

func showing_tip() -> bool:
	return not tip.is_empty()

## Hay un texto que mostrar: un paso pendiente o un consejo activo.
func active() -> bool:
	return step < COUNT or showing_tip()

func tick_tips(delta: float) -> void:
	if showing_tip():
		tip_time += delta
		if tip_done(tip):
			finish_tip(true)
		elif tip_time >= TIP_TIMEOUT:
			finish_tip(false)
		elif not tip_relevant(tip):
			# Deja de venir a cuento (p. ej. llega la noche): volverá cuando sea útil.
			tip = ""
			hint_changed.emit()
		return
	for id: String in TIPS:
		if id in tips_done or not tip_allowed(id) or not tip_relevant(id): continue
		tip = id
		tip_time = 0
		tip_baseline = tip_measure(id)
		hint_changed.emit()
		return

## Los consejos esperan a que acabe la guía; la sobrecarga ya sirve en la primera noche.
func tip_allowed(id: String) -> bool:
	return step >= COUNT or (id == "overload" and step == 10)

func tip_relevant(id: String) -> bool:
	var day: bool = world.cycle.phase == "DÍA"
	match id:
		"overload":
			var left: bool = world.player.position.x < 0
			return world.cycle.phase == "NOCHE" and world.bank.energy_used() > 0 and world.overload.overload_status(left) == "LISTA" and not world.get_tree().get_nodes_in_group(GameRules.ENEMIES).is_empty()
		"journal": return day
		"recruit": return day and world.core.tier > 0 and world.civic.population() < world.civic.capacity and open_camp() >= 0
		"arsenal": return day and world.core.tier > 0 and (not world.civic.villagers.is_empty() or absf(world.player.position.x - ARSENAL_X) < 220)
		"refuge": return day and world.core.tier > 0 and world.civic.population() >= world.civic.capacity and world.civic.capacity < FortressRules.CAPACITY[world.core.tier - 1]
		"portal": return day and world.story.soldiers() > 0 and world.civic.advance_side == 0 and nearest_portal() != null
		"clinic": return day and world.clinic.visible and world.neural.points() > 0
	return false

## Valor que el consejo espera ver cambiar (supervivientes en campamentos o plazas del refugio).
func tip_measure(id: String) -> int:
	if id == "recruit": return int(world.civic.camp_stock[0] + world.civic.camp_stock[1])
	if id == "refuge": return world.civic.capacity
	return 0

func tip_done(id: String) -> bool:
	match id:
		"overload": return world.overload.overload_left > 0 or world.overload.overload_right > 0
		"journal", "arsenal", "clinic": return panels_seen.get(id, false)
		"recruit": return tip_measure(id) < tip_baseline
		"refuge": return world.civic.capacity > tip_baseline
		"portal": return world.civic.advance_side != 0
	return false

func tip_caption(id: String) -> String:
	match id:
		"overload": return "Presiona {overload}: potencia las torretas de este lado"
		"journal": return "Presiona {journal}: diario, objetivos y colonia"
		"recruit": return "Mantén {interact} en el campamento: recluta habitantes"
		"arsenal":
			if not world.civic.villagers.is_empty(): return "Arsenal: mantén {interact}, compra herramientas y da oficio"
			return "Arsenal: mantén {interact}, compra armas y herramientas"
		"refuge": return "Refugio lleno. Mantén {interact}: amplía la población"
		"portal": return "Ve al lado del portal. {escort}: asalto; otra vez: retirada"
		"clinic": return "Mantén {interact} en la clínica: gasta tus puntos"
	return ""

func tip_target(id: String) -> Vector2:
	match id:
		"overload":
			for site: ConstructionSite in world.construction.sites:
				if site.kind == &"turret" and site.hp > 0 and site.powered and (site.x < 0) == (world.player.position.x < 0): return site.global_position
		"recruit":
			var camp: int = open_camp()
			if camp >= 0: return Vector2(CAMP_X[camp], GameRules.FLOOR_Y)
		"arsenal": return Vector2(ARSENAL_X, GameRules.FLOOR_Y)
		"refuge": return Vector2(CivicSystem.REFUGE_X, GameRules.FLOOR_Y)
		"portal":
			var portal: EnemyRepeater = nearest_portal()
			if portal != null: return portal.global_position
		"clinic": return world.clinic.global_position
	# Sin lugar concreto: la flecha se apaga junto al jugador.
	return world.player.position

## Campamento con supervivientes y camino libre más cercano al jugador; -1 si no hay.
func open_camp() -> int:
	var best: int = -1
	for index: int in CAMP_X.size():
		if world.civic.camp_stock[index] <= 0 or not world.civic.safe_to_build(CAMP_X[index]): continue
		if best < 0 or absf(CAMP_X[index] - world.player.position.x) < absf(CAMP_X[best] - world.player.position.x): best = index
	return best

func nearest_portal() -> EnemyRepeater:
	var best: EnemyRepeater
	for portal: EnemyRepeater in world.civic.gates + world.expedition.repeaters:
		if portal.health.current <= 0: continue
		if best == null or absf(portal.position.x - world.player.position.x) < absf(best.position.x - world.player.position.x): best = portal
	return best

func finish_tip(solved: bool) -> void:
	var id: String = tip
	tip = ""
	if id not in tips_done: tips_done.append(id)
	var reward: int = TIP_REWARD if solved else 0
	world.bank.deposit(reward)
	if persist:
		var profile: Dictionary = SaveSystem.engagement_profile()
		profile.tips = tips_done.duplicate()
		SaveSystem.store_engagement(profile)
	tip_completed.emit(id, reward)
	hint_changed.emit()
