class_name CivicSystem
extends Node2D
## Reclutar personas y ofrecer herramientas; las tropas ya no se crean del edificio.
const RACK_X: Array[float] = [-675.0, -645.0, -615.0, -585.0, -555.0, -525.0]
const ROLES: Array[String] = ["builder", "collector", "ranger", "guardian", "technician", "medic"]
const NAMES: Array[String] = ["Martillo", "Equipo recuperador", "Fusil", "Escudo", "Herramienta técnica", "Botiquín"]
const COSTS: Array[int] = [10, 10, 15, 20, 15, 20]
var district: Node2D
var tools: Array[int] = [0, 0, 0, 0, 0, 0]
var camp_stock: Array[int] = [2, 2]
var villagers: Array[Dictionary] = []
var walls: Array[ConstructionSite] = []
var gates: Array[EnemyRepeater] = []
var elapsed: float = 0
var camp_day: int = 1
var capacity: int = 8
var advance_side: int = 0
var retaliation: Array[Dictionary] = []

func setup(world: Node2D) -> void:
	district = world
	z_index = -1
	for side: float in [-1.0, 1.0]:
		for distance: float in [600.0, 980.0, 1320.0]:
			var data: StructureData = load("res://data/structures/wall.tres").duplicate() as StructureData
			data.offset = distance
			var site: ConstructionSite = data.scene.instantiate() as ConstructionSite
			site.data = data
			site.viewer = district.player
			site.position = Vector2(side * distance, GameRules.FLOOR_Y)
			walls.append(site)
			add_child(site)
		for index: int in range(district.zone_index):
			var gate: ConduitGate = ConduitGate.new()
			gate.position = Vector2(side * (1180 - index * 250), GameRules.FLOOR_Y)
			gates.append(gate)
			add_child(gate)
			gate.destroyed.connect(func() -> void:
				district.presenter.show_notice("Brecha cerrada: nueva franja de expansión")
				district.experience.gain(15)
				district.expedition._repeater_destroyed()
				retaliation.append({"side": signf(gate.position.x), "time": 3.0}))

func stabilized() -> bool:
	if district.cycle.day < 2: return false
	var walls_ready: int = 0
	for site: ConstructionSite in district.construction.sites:
		if site.hp > 0 and site.data.blocks_enemies: walls_ready += 1
	return walls_ready >= 2 and district.expansion.energy_bonus() > 0

func entrance(side: float) -> float:
	var closest: float = 1440
	for gate: EnemyRepeater in gates:
		if gate.health.current > 0 and signf(gate.position.x) == side: closest = minf(closest, absf(gate.position.x))
	return side * closest

func side_closed(side: float) -> bool:
	for gate: EnemyRepeater in gates:
		if gate.health.current > 0 and signf(gate.position.x) == side: return false
	for repeater: EnemyRepeater in district.expedition.repeaters:
		if signf(repeater.position.x) == side and repeater.health.current > 0: return false
	return true

func population() -> int:
	var result: int = district.colony.workers.size() + villagers.size()
	for site: ExpansionOutpost in district.expansion.sites:
		result += site.staff_count()
	return result

func frontier(side: float) -> float:
	var result: float = 0
	for site: ConstructionSite in district.construction.defensive_sites():
		if site.data.blocks_enemies and site.hp > 0 and signf(site.x) == side: result = maxf(result, absf(site.x))
	return result

func safe_to_build(x: float) -> bool:
	for gate: EnemyRepeater in gates:
		if gate.health.current > 0 and signf(gate.position.x) == signf(x) and absf(x) > absf(gate.position.x) - 80: return false
	return true

func target_at(x: float) -> int:
	for index: int in range(2):
		if absf(x - (-1340 if index == 0 else 1340)) < 28: return -300 - index
	for index: int in range(RACK_X.size()):
		if absf(x - RACK_X[index]) < 13: return -320 - index
	for index: int in range(walls.size()):
		if absf(x - walls[index].x) < 24: return -340 - index
	if absf(x - 80) < 15: return -360
	return GameRules.NO_TARGET

func describe(target: int) -> Dictionary:
	if target == -360:
		return {"text": "Refugio: reasignar un trabajador", "cost": -1} if capacity >= 20 else {"text": "Refugio: ampliar población %d → %d" % [capacity, capacity + 4], "cost": 30}
	if target <= -340:
		var wall: ConstructionSite = walls[-340 - target]
		return {"text": "Muralla exterior · Nv.%d" % wall.tier, "cost": wall.cost if wall.hp <= 0 else (wall.tier * 25 if wall.hp == wall.max_hp else wall.data.repair_cost)}
	if target <= -320:
		var index: int = -320 - target
		return {"text": NAMES[index] + " · herramientas %d" % tools[index], "cost": COSTS[index]}
	return {"text": "Reclutar superviviente · %d disponibles" % camp_stock[-300 - target], "cost": 5}

func interact(target: int) -> bool:
	if district.cycle.phase != "DÍA":
		district.presenter.show_notice("Organiza la colonia durante el día")
		return false
	if target == -360:
		if capacity >= 20:
			if district.colony.workers.size() <= GameRules.INITIAL_POPULATION: return false
			var worker: ColonyWorker = district.colony.workers.pop_back()
			villagers.append({"x": 80.0, "side": worker.side})
			worker.free()
			district.presenter.show_notice("Habitante disponible: compra la nueva herramienta")
		else:
			if not district.bank.spend(30): return false
			capacity += 4
	elif target <= -340 and target > -346:
		var index: int = -340 - target
		if not safe_to_build(walls[index].x):
			district.presenter.show_notice("Destruye la brecha que bloquea esa franja")
			return false
		return district.construction.order_site(walls[index])
	elif target <= -320 and target > -326:
		var index: int = -320 - target
		if tools[index] >= 4 or not district.bank.spend(COSTS[index]): return false
		tools[index] += 1
	elif target in [-300, -301]:
		var index: int = -300 - target
		if camp_stock[index] <= 0 or population() >= capacity or not district.bank.spend(5): return false
		camp_stock[index] -= 1
		villagers.append({"x": -1340.0 if index == 0 else 1340.0, "side": -1.0 if index == 0 else 1.0})
	else: return false
	district.expansion.checkpoint()
	return true

func assign(index: int, role_index: int) -> bool:
	var role: String = ROLES[role_index]
	if role in ["builder", "collector"]:
		district.colony.add_worker(StringName(role))
		district.colony.workers.back().x = villagers[index].x
	else:
		var building: String = {"ranger": "barracks", "guardian": "barracks", "technician": "generator", "medic": "medical"}[role]
		var home: ExpansionOutpost
		for site: ExpansionOutpost in district.expansion.sites:
			if site.hp > 0 and site.spec.id == building and site.staff_count() < site.staff_capacity():
				if home == null or site.staff_count() < home.staff_count() or (site.staff_count() == home.staff_count() and absf(site.position.x - villagers[index].x) < absf(home.position.x - villagers[index].x)): home = site
		if home == null: return false
		home.hire(role)
	tools[role_index] -= 1
	villagers.remove_at(index)
	district.presenter.show_notice("Profesión: " + ["Constructor", "Recuperador", "Tirador", "Guardián", "Técnico", "Médico"][role_index])
	return true

func tick(delta: float) -> void:
	elapsed += delta
	for index: int in range(retaliation.size() - 1, -1, -1):
		retaliation[index].time -= delta
		if retaliation[index].time <= 0:
			var side: float = retaliation[index].side
			if not side_closed(side):
				for id: String in ["corredor", "errante", "saboteador"]:
					district.director.spawn_enemy(side, load("res://data/enemies/" + id + ".tres"), district.cycle.day)
			retaliation.remove_at(index)
	if district.cycle.day != camp_day:
		camp_day = district.cycle.day
		for index: int in range(2): camp_stock[index] = mini(2, camp_stock[index] + 1)
	for index: int in range(villagers.size() - 1, -1, -1):
		var citizen: Dictionary = villagers[index]
		var destination: float = citizen.side * maxf(40, frontier(citizen.side) - 60) if district.cycle.phase != "DÍA" else 0
		var role_index: int = -1
		if district.cycle.phase == "DÍA":
			for candidate: int in range(tools.size()):
				if tools[candidate] > 0 and role_ready(candidate):
					role_index = candidate
					destination = RACK_X[candidate]
					break
		citizen.x = move_toward(citizen.x, destination, delta * 65)
		if role_index >= 0 and absf(citizen.x - destination) < 12: assign(index, role_index)
	queue_redraw()

func role_ready(index: int) -> bool:
	if index < 2: return true
	var id: String = ["barracks", "barracks", "generator", "medical"][index - 2]
	for site: ExpansionOutpost in district.expansion.sites:
		if site.spec.id == id and site.hp > 0 and site.staff_count() < site.staff_capacity(): return true
	return false

func jobs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for wall: ConstructionSite in walls: result.append(wall)
	for site: ExpansionOutpost in district.expansion.sites: result.append(site)
	return result

func snapshot() -> Dictionary:
	var fortifications: Array = []
	for wall: ConstructionSite in walls: fortifications.append({"hp": wall.hp, "ordered": wall.ordered, "progress": wall.progress, "tier": wall.tier, "upgrade": wall.upgrade_pending})
	var breaches: Array[bool] = []
	for gate: EnemyRepeater in gates: breaches.append(gate.health.current <= 0)
	return {"tools": tools.duplicate(), "camps": camp_stock.duplicate(), "villagers": villagers.duplicate(true), "walls": fortifications, "gates": breaches, "capacity": capacity, "day": camp_day, "retaliation": retaliation.duplicate(true), "advance": advance_side}

func restore(data: Dictionary) -> void:
	tools.assign(data.get("tools", [0, 0, 0, 0, 0, 0]))
	camp_stock.assign(data.get("camps", [2, 2]))
	villagers.assign(data.get("villagers", []))
	capacity = int(data.get("capacity", 8))
	camp_day = int(data.get("day", 1))
	retaliation.assign(data.get("retaliation", []))
	advance_side = int(data.get("advance", 0))
	var saved: Array = data.get("walls", [])
	for index: int in range(walls.size()):
		var state: Dictionary = saved[index] if not saved.is_empty() else {}
		walls[index].tier = int(state.get("tier", 1))
		walls[index].health_component.maximum = walls[index].data.health * walls[index].tier
		walls[index].hp = int(state.get("hp", 0))
		walls[index].ordered = state.get("ordered", false)
		walls[index].progress = float(state.get("progress", 0))
		walls[index].upgrade_pending = state.get("upgrade", false)
	var saved_gates: Array = data.get("gates", [])
	for index: int in range(gates.size()): gates[index].restore(saved_gates[index] if not saved_gates.is_empty() else false)

static func valid(data: Variant, gate_count: int) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not ExpansionSystem.number(data.get("advance", 0), -1, 1, true) or not data.get("retaliation", []) is Array or data.get("retaliation", []).size() > 4: return false
	for counter: Variant in data.get("retaliation", []):
		if not counter is Dictionary or not ExpansionSystem.number(counter.get("side"), -1, 1, true) or absf(float(counter.side)) != 1 or not ExpansionSystem.number(counter.get("time"), 0, 3): return false
	if not data.get("tools") is Array or data.tools.size() != 6 or not data.get("camps") is Array or data.camps.size() != 2: return false
	for value: Variant in data.tools + data.camps:
		if not ExpansionSystem.number(value, 0, 4, true): return false
	if not ExpansionSystem.number(data.get("capacity"), 8, 20, true) or not ExpansionSystem.number(data.get("day"), 1, 3, true): return false
	if not data.get("villagers") is Array or data.villagers.size() > data.capacity: return false
	for citizen: Variant in data.villagers:
		if not citizen is Dictionary or not ExpansionSystem.number(citizen.get("x"), -1600, 1600) or not ExpansionSystem.number(citizen.get("side"), -1, 1, true) or absf(float(citizen.side)) != 1: return false
	if not data.get("gates") is Array or data.gates.size() != gate_count: return false
	for flag: Variant in data.gates:
		if not flag is bool: return false
	if not data.get("walls") is Array or data.walls.size() != 6: return false
	for wall: Variant in data.walls:
		if not wall is Dictionary or not ExpansionSystem.number(wall.get("tier"), 1, 3, true): return false
		if not ExpansionSystem.number(wall.get("hp"), 0, 240 * wall.tier, true) or not ExpansionSystem.number(wall.get("progress"), 0, 4) or not wall.get("ordered") is bool or not wall.get("upgrade") is bool: return false
	return true

func _draw() -> void:
	var cell: Vector2 = ExpansionOutpost.ART.get_size() * 0.5
	draw_texture_rect_region(ExpansionOutpost.ART, Rect2(-706, 118, 202, 142), Rect2(Vector2.ZERO, cell), Color("a5b4ba"))
	for side: int in [-1, 1]:
		var x: float = side * 1340
		draw_rect(Rect2(x - 25, GameRules.FLOOR_Y - 31, 50, 31), Color("182639"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 30, 229), Vector2(x, 209), Vector2(x + 30, 229)]), Color("704c43"))
		draw_circle(Vector2(x + 17, 255), 5, Color("ffce75"))
	for index: int in range(RACK_X.size()):
		var x: float = RACK_X[index]
		draw_rect(Rect2(x - 10, 230, 20, 30), Color("304356"))
		draw_rect(Rect2(x - 11, 229, 22, 3), Color("8299a8"))
		for item: int in range(tools[index]): draw_line(Vector2(x - 7 + item * 4, 236), Vector2(x - 7 + item * 4, 252), Color("ffce75"), 2)
		draw_rect(Rect2(x - 3, 224, 6, 3), Color("47dacb") if index < 2 else Color("ffce75"))
		var tint: Color = Color("ffce75") if tools[index] > 0 else Color("8299a8")
		match index:
			0:
				draw_rect(Rect2(x - 1, 236, 2, 14), tint)
				draw_rect(Rect2(x - 5, 236, 10, 4), tint)
			1:
				draw_rect(Rect2(x - 5, 239, 10, 10), tint)
				draw_rect(Rect2(x - 3, 236, 6, 3), tint)
			2:
				draw_line(Vector2(x - 3, 236), Vector2(x + 3, 251), tint, 2)
			3:
				draw_colored_polygon(PackedVector2Array([Vector2(x - 5, 236), Vector2(x + 5, 236), Vector2(x + 5, 245), Vector2(x, 251), Vector2(x - 5, 245)]), tint)
			4:
				draw_line(Vector2(x, 238), Vector2(x, 251), tint, 2)
				draw_arc(Vector2(x, 238), 4, 0, PI, 8, tint, 2)
			5:
				draw_rect(Rect2(x - 1, 236, 3, 14), tint)
				draw_rect(Rect2(x - 5, 241, 11, 4), tint)
	draw_rect(Rect2(60, 220, 40, 40), Color("182639"))
	draw_colored_polygon(PackedVector2Array([Vector2(56, 221), Vector2(80, 205), Vector2(104, 221)]), Color("704c43"))
	for citizen: Dictionary in villagers:
		var x: float = citizen.x
		var sway: float = roundf(sin(elapsed * 8 + x) * 2)
		draw_line(Vector2(x - 3, 247), Vector2(x - 4 - sway, 259), Color("8299a8"), 3)
		draw_line(Vector2(x + 3, 247), Vector2(x + 4 + sway, 259), Color("8299a8"), 3)
		draw_rect(Rect2(x - 5, 232, 10, 17), Color("704c43"))
		draw_rect(Rect2(x - 4, 224, 8, 9), Color("8299a8"))
