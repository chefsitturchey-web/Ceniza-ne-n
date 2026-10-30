class_name ExpansionSystem
extends Node2D
## Módulos prefabricados: su dron de montaje no ocupa las obras de la colonia.
const SPECS: Array[Dictionary] = [
	{"id": "barracks", "title": "Cuartel", "x": 450.0, "cost": 50, "energy": 1},
	{"id": "medical", "title": "Puesto médico", "x": 820.0, "cost": 45, "energy": 1},
	{"id": "generator", "title": "Generador", "x": 360.0, "cost": 35, "energy": 0},
	{"id": "recycler", "title": "Recicladora", "x": 1230.0, "cost": 40, "energy": 0},
]
const CACHE_X: Array[float] = [-1500.0, -1140.0, -700.0, 700.0, 1140.0, 1500.0]
var district: Node2D
var sites: Array[ExpansionOutpost] = []
var looted: Array[bool] = [false, false, false, false, false, false]
var elapsed: float = 0.0

func setup(world: Node2D) -> void:
	district = world
	for sector: int in 2:
		for slot: int in 8:
			var spec: Dictionary = SPECS[slot % 4].duplicate()
			var site: ExpansionOutpost = ExpansionOutpost.new()
			site.z_index = -1
			site.spec = spec
			site.expansion = self
			site.position = Vector2(FrontierLayout.lot_x(world.zone_index, sector * 8 + slot), GameRules.FLOOR_Y)
			sites.append(site)
			add_child(site)

func target_at(x: float) -> int:
	for index: int in range(sites.size()):
		if absf(sites[index].position.x - x) < 37:
			return -100 - index
	for index: int in range(CACHE_X.size()):
		if not looted[index] and absf(CACHE_X[index] - x) < 30:
			return -200 - index
	return GameRules.NO_TARGET

func interact(target: int) -> bool:
	if target <= -200 and target > -200 - CACHE_X.size():
		var index: int = -200 - target
		if looted[index]: return false
		looted[index] = true
		district.bank.deposit(20)
		district.presenter.show_notice("Suministros recuperados: +20 chatarra")
		district.play("pickup")
		checkpoint()
		return true
	if target > -100 or target <= -100 - sites.size(): return false
	var site: ExpansionOutpost = sites[-100 - target]
	var required: int = FortressRules.BUILDINGS[site.spec.id]
	if district.core.tier < required:
		district.presenter.show_notice("%s necesita núcleo Nv.%d" % [site.spec.title, required])
		district.play("denied")
		return false
	if district.frontier != null and district.frontier.blocked(site.position.x):
		district.presenter.show_notice("Despeja primero los escombros de la parcela")
		return false
	if district.civic != null and not district.civic.safe_to_build(site.position.x):
		district.presenter.show_notice("Destruye primero la brecha de esa franja")
		district.play("denied")
		return false
	if site.ordered: return false
	if site.hp >= site.MAX_HEALTH:
		district.presenter.show_notice(site.spec.title + ": operativo")
		return false
	var cost: int = site.spec.cost if site.hp == 0 else 12
	if site.hp == 0 and int(site.spec.energy) > 0 and district.bank.energy_used() + site.spec.energy > district.bank.available_capacity():
		district.presenter.show_notice("Construye un generador: falta energía")
		district.play("denied")
		return false
	if not district.bank.spend(cost):
		district.presenter.show_notice("Necesitas %d chatarra" % cost)
		district.play("denied")
		return false
	site.ordered = true
	site.progress = 0
	district.presenter.show_notice("Obra pagada: los constructores acudirán")
	district.play("build_order")
	checkpoint()
	return true

func checkpoint() -> void:
	if district.session.save_system != null and district.cycle.phase == "DÍA":
		district.session.save_system.save_game()

func energy_bonus() -> int:
	var result: int = 0
	for site: ExpansionOutpost in sites:
		if site.spec.id == "generator" and site.hp > 0: result += 2 * maxi(1, district.core.tier)
	return result

func refresh_energy() -> void:
	district.bank.changed.emit(district.bank.scrap, district.bank.energy_used(), district.bank.available_capacity())

func energy_used() -> int:
	var result: int = 0
	for site: ExpansionOutpost in sites:
		if site.hp > 0 or site.ordered: result += int(site.spec.energy)
	return result

func powered(site: ExpansionOutpost) -> bool:
	# Las defensas originales tienen prioridad al perder un generador.
	var used: int = 0
	for base: ConstructionSite in district.construction.sites:
		if (base.hp > 0 and base.powered) or base.ordered: used += base.data.energy
	for candidate: ExpansionOutpost in sites:
		if candidate.hp > 0 or candidate.ordered:
			used += int(candidate.spec.energy)
		if candidate == site:
			return used <= district.bank.available_capacity() or int(site.spec.energy) == 0
	return false

func frontier(side: float) -> float:
	var edge: float = 0
	for site: ExpansionOutpost in sites:
		if signf(site.position.x) == side and (site.hp > 0 or site.ordered):
			edge = maxf(edge, absf(site.position.x))
	return edge

func tick(delta: float) -> void:
	elapsed += delta
	# Supply caches are loose salvage: walking over one cannot be masked by a wall.
	for index: int in CACHE_X.size():
		if not looted[index] and absf(district.player.position.x - CACHE_X[index]) < 18:
			looted[index] = true
			district.bank.deposit(20)
			district.presenter.show_notice("Suministros recuperados: +20 chatarra")
			checkpoint()
	for site: ExpansionOutpost in sites: site.tick(delta)
	queue_redraw()

func snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for site: ExpansionOutpost in sites: entries.append(site.snapshot())
	return {"sites": entries, "looted": looted.duplicate()}

func restore(data: Dictionary) -> void:
	looted.assign(data.get("looted", [false, false, false, false, false, false]))
	var entries: Array = data.get("sites", [])
	for index: int in range(sites.size()): sites[index].restore(entries[index] if index < entries.size() else {})
	queue_redraw()

static func number(value: Variant, low: float, high: float, integer: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and (not integer or value == floorf(value))

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	var entries: Variant = data.get("sites")
	var caches: Variant = data.get("looted")
	if not entries is Array or entries.size() not in [8, 16] or not caches is Array or caches.size() != 6: return false
	for flag: Variant in caches:
		if not flag is bool: return false
	for index: int in range(entries.size()):
		var entry: Variant = entries[index]
		if not entry is Dictionary or entry.get("id") != SPECS[index % 4].id or not entry.get("ordered") is bool: return false
		if entry.has("staffed") and (not entry.staffed is bool or entry.get("role", "") not in ["", "ranger", "guardian", "technician", "medic"]): return false
		if not number(entry.get("hp"), 0, 180, true) or not number(entry.get("progress"), 0, ExpansionOutpost.BUILD_TIME) or not number(entry.get("income"), 0, 12): return false
		var ally: Variant = entry.get("ally", {})
		if not ally is Dictionary: return false
		if not ally.is_empty():
			if index % 4 == 3: return false
			if not number(ally.get("hp"), 0, 90, true) or not number(ally.get("x"), -GameRules.MAP_HALF_WIDTH, GameRules.MAP_HALF_WIDTH) or not number(ally.get("respawn"), 0, 18) or not number(ally.get("cooldown"), 0, 3): return false
		if entry.has("crew"):
			if not entry.crew is Array or entry.crew.size() > (3 if index % 4 == 0 else 1): return false
			if entry.staffed != (not entry.crew.is_empty()): return false
			for member: Variant in entry.crew:
				if member is Dictionary and member.has("duty_side") and not number(member.duty_side, -1, 1, true): return false
				if not member is Dictionary or member.get("role") not in (["ranger", "guardian"] if index % 4 == 0 else (["medic"] if index % 4 == 1 else ["technician"])): return false
				if not number(member.get("hp"), 1, 90, true) or not number(member.get("x"), -GameRules.MAP_HALF_WIDTH, GameRules.MAP_HALF_WIDTH) or not number(member.get("respawn"), 0, 18) or not number(member.get("cooldown"), 0, 3): return false
	return true

func _draw() -> void:
	for index: int in range(CACHE_X.size()):
		var x: float = CACHE_X[index]
		var y: float = GameRules.FLOOR_Y
		draw_rect(Rect2(x - 14, y - 17, 28, 17), Color("182639"))
		draw_rect(Rect2(x - 12, y - 16, 24, 3), Color("8299a8"))
		for rib: int in [-9, 7]: draw_rect(Rect2(x + rib, y - 13, 2, 12), Color("304356"))
		if not looted[index]:
			draw_rect(Rect2(x - 3, y - 10, 6, 4), Color("ffce75"))
		else:
			draw_line(Vector2(x - 12, y - 4), Vector2(x + 12, y - 4), Color("304356"), 2)
