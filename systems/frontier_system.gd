class_name FrontierSystem
extends Node2D

const CLEAR_BASE: int = -10000
const DROP_BASE: int = -12000
const BREAK_CHANCE: float = 0.25
var district: District
var plots: Array[ClearanceSite] = []
var drops: Array[Dictionary] = []
var elapsed: float = 0
var parts_art: Texture2D = load("res://assets/world/salvage/parts.png")

func setup(world: District) -> void:
	district = world
	z_index = -1
	for site: ExpansionOutpost in world.expansion.sites: add_plot(site.position.x)
	for site: ConstructionSite in world.construction.sites:
		if absf(site.x) > 1000: add_plot(site.x)
	for wall: ConstructionSite in world.civic.walls:
		if absf(wall.x) > 1100: add_plot(wall.x)
	world.bank.parts_spilled.connect(spill)

func add_plot(x: float) -> void:
	var plot: ClearanceSite = ClearanceSite.new()
	plot.frontier = self
	plot.label = FrontierLayout.profile(district.zone_index).obstacle
	plot.variant = district.zone_index
	plot.duration = 18 + district.zone_index * 4 + absf(x) / 350
	plot.required_tier = 1 if absf(x) < 3000 else 2
	plot.position = Vector2(x, GameRules.FLOOR_Y)
	plots.append(plot)
	add_child(plot)

func blocked(x: float) -> bool:
	return plots.any(func(plot: ClearanceSite) -> bool: return not plot.cleared and absf(plot.position.x - x) < 45)

func target_at(x: float) -> int:
	for index: int in drops.size():
		if int(drops[index].amount) > 0 and absf(float(drops[index].x) - x) < 24: return DROP_BASE - index
	for index: int in plots.size():
		if not plots[index].cleared and absf(plots[index].position.x - x) < 38: return CLEAR_BASE - index
	return GameRules.NO_TARGET

func interact(target: int) -> bool:
	if target <= DROP_BASE:
		var index: int = DROP_BASE - target
		if index < 0 or index >= drops.size(): return false
		var amount: int = mini(int(drops[index].amount), district.bank.parts_capacity - district.bank.parts)
		if amount <= 0:
			district.presenter.show_notice("Mochila llena: vuelve al depósito del núcleo")
			return false
		drops[index].amount -= amount
		district.bank.add_parts(amount)
		queue_redraw()
		return true
	var index: int = CLEAR_BASE - target
	if index < 0 or index >= plots.size(): return false
	var plot: ClearanceSite = plots[index]
	if plot.cleared or plot.ordered: return false
	if district.core.tier < plot.required_tier:
		district.presenter.show_notice("Despeje avanzado: requiere núcleo Nv.%d" % plot.required_tier)
		return false
	if not district.civic.safe_to_build(plot.position.x):
		district.presenter.show_notice("Primero cierra el portal que controla esta franja")
		return false
	if not district.bank.spend(5):
		district.presenter.show_notice("Despejar cuesta 5 de chatarra")
		return false
	plot.ordered = true
	district.presenter.show_notice("Despeje encargado: un constructor debe llegar y trabajar")
	district.expansion.checkpoint()
	return true

func describe(target: int) -> Dictionary:
	if target <= DROP_BASE:
		return {"text": "Recoger piezas caídas · mochila %d/%d" % [district.bank.parts, district.bank.parts_capacity], "cost": -1, "progress": 0.0, "key": district.bank.parts < district.bank.parts_capacity}
	var plot: ClearanceSite = plots[CLEAR_BASE - target]
	var text: String = plot.label + " · despejar parcela"
	if plot.ordered: text = "Despejando · %d%%" % int(plot.progress / plot.duration * 100)
	elif district.core.tier < plot.required_tier: text += " · núcleo Nv.%d" % plot.required_tier
	elif not district.civic.safe_to_build(plot.position.x): text = "Parcela controlada por un portal: envía tropas con F"
	var available: bool = not plot.ordered and district.core.tier >= plot.required_tier and district.civic.safe_to_build(plot.position.x)
	return {"text": text, "cost": 5 if available else -1, "progress": plot.progress / plot.duration, "key": available}

func spill(amount: int) -> void:
	var surviving: int = 0
	for index: int in amount:
		if randf() >= BREAK_CHANCE: surviving += 1
	if surviving > 0:
		# Merge nearby piles to keep the world and checkpoint bounded.
		var found: bool = false
		for drop: Dictionary in drops:
			if absf(float(drop.x) - district.player.position.x) < 30:
				drop.amount += surviving
				found = true
				break
		if not found and drops.size() < 512: drops.append({"x": clampf(district.player.position.x + 15, -GameRules.MAP_HALF_WIDTH + 20, GameRules.MAP_HALF_WIDTH - 20), "amount": surviving})
	district.presenter.show_notice("Mochila llena: caen %d piezas; %d se rompen" % [surviving, amount - surviving])
	queue_redraw()

func tick(delta: float) -> void:
	elapsed += delta
	district.clinic.visible = district.core.tier > 0
	if district.core.tier > 0 and absf(district.player.position.x) < 60 and district.bank.parts > 0:
		district.bank.stored_parts += district.bank.parts
		district.bank.parts = 0
		district.bank.parts_changed.emit(0)
		district.presenter.show_notice("Piezas guardadas en el depósito del núcleo")
	for plot: ClearanceSite in plots:
		if plot.ordered and plot.progress >= plot.duration: plot._process(0)
	queue_redraw()

func snapshot() -> Dictionary:
	var entries: Array = []
	for plot: ClearanceSite in plots: entries.append({"cleared": plot.cleared, "ordered": plot.ordered, "progress": plot.progress})
	return {"version": 1, "plots": entries, "drops": drops.duplicate(true)}

func restore(data: Dictionary) -> void:
	var saved: Array = data.get("plots", [])
	for index: int in plots.size():
		var entry: Dictionary = saved[index] if index < saved.size() else {}
		plots[index].cleared = entry.get("cleared", false)
		plots[index].ordered = entry.get("ordered", false)
		plots[index].progress = float(entry.get("progress", 0))
		plots[index].visible = not plots[index].cleared
	drops.assign(data.get("drops", []))
	for drop: Dictionary in drops:
		drop.amount = int(drop.amount)
		drop.x = float(drop.x)
	# Existing buildings from old saves must never be buried by new obstacles.
	for plot: ClearanceSite in plots:
		for site: ExpansionOutpost in district.expansion.sites:
			if site.hp > 0 and absf(site.position.x - plot.position.x) < 45: plot.cleared = true; plot.ordered = false
		for site: ConstructionSite in district.construction.defensive_sites():
			if site.hp > 0 and absf(site.x - plot.position.x) < 45: plot.cleared = true; plot.ordered = false
	queue_redraw()

func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.get("version") != 1 or not value.get("plots") is Array or value.plots.size() != plots.size() or not value.get("drops") is Array or value.drops.size() > 512: return false
	for index: int in plots.size():
		var entry: Variant = value.plots[index]
		if not entry is Dictionary or not entry.get("cleared") is bool or not entry.get("ordered") is bool: return false
		if not ExpansionSystem.number(entry.get("progress"), 0, plots[index].duration + 2): return false
		if entry.cleared and entry.ordered: return false
	for entry: Variant in value.drops:
		if not entry is Dictionary or not ExpansionSystem.number(entry.get("x"), -GameRules.MAP_HALF_WIDTH, GameRules.MAP_HALF_WIDTH) or not ExpansionSystem.number(entry.get("amount"), 0, 1000000, true): return false
	return true

func _draw() -> void:
	for drop: Dictionary in drops:
		if int(drop.amount) <= 0: continue
		var x: float = float(drop.x)
		draw_circle(Vector2(x, GameRules.FLOOR_Y - 4), 12, Color(0.2, 0.8, 0.75, 0.12 + sin(elapsed * 3) * 0.04))
		for index: int in mini(3, int(drop.amount)):
			draw_texture(parts_art, Vector2(x - 13 + index * 6, GameRules.FLOOR_Y - 15 - index % 2 * 2))
