class_name CivicSystem
extends Node2D
## Reclutar personas y ofrecer herramientas; las tropas ya no se crean del edificio.
const REFUGE_X: float = 112.0
const RACK_X: Array[float] = [-675.0, -645.0, -615.0, -585.0, -555.0, -525.0]
const ROLES: Array[String] = ["builder", "collector", "ranger", "guardian", "technician", "medic"]
const NAMES: Array[String] = ["Martillo", "Equipo recuperador", "Fusil", "Escudo", "Herramienta técnica", "Botiquín"]
const COSTS: Array[int] = [10, 10, 15, 20, 15, 20]
var district: Node2D
var tools: Array[int] = [0, 0, 0, 0, 0, 0]
var camp_stock: Array[int] = [2, 2]
var villagers: Array[Dictionary] = []
var people: Array[PersonVisual] = []
var employment_hint: Label
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
			site.core = district.core
			site.position = Vector2(side * distance, GameRules.FLOOR_Y)
			walls.append(site)
			add_child(site)
		for index: int in range(mini(3, district.zone_index)):
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

func defend_portal(portal: EnemyRepeater) -> void:
	if portal.health.current <= 0 or district.session.finished: return
	# Refuerzos sin botín: no se puede cultivar experiencia provocando una puerta.
	if get_tree().get_nodes_in_group(GameRules.ENEMIES).size() >= 24: return
	district.presenter.show_notice("El portal se defiende: protege a tus tiradores")
	district.sound.play_cue("alarm")
	for id: String in ["errante", "corredor"]:
		var data: EnemyData = load("res://data/enemies/" + id + ".tres").duplicate() as EnemyData
		data.reward = 0
		var enemy: SiegeEnemy = district.director.spawn_enemy(signf(portal.position.x), data, district.cycle.day)
		enemy.position.x = portal.position.x - signf(portal.position.x) * 20

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
	if absf(x - REFUGE_X) < 24: return -360
	return GameRules.NO_TARGET

func describe(target: int) -> Dictionary:
	if target == -360:
		if capacity < 20 and capacity >= FortressRules.CAPACITY[district.core.tier - 1]:
			return {"text": "Refugio: requiere núcleo Nv.%d" % (district.core.tier + 1), "cost": -1, "locked": true}
		return {"text": "Refugio: reasignar un trabajador", "cost": -1} if capacity >= 20 else {"text": "Refugio: ampliar población %d → %d" % [capacity, capacity + 4], "cost": 30}
	if target <= -340:
		var wall: ConstructionSite = walls[-340 - target]
		if wall.hp == wall.max_hp and wall.tier < 3 and wall.tier >= district.core.tier:
			return {"text": "Muralla: requiere núcleo Nv.%d" % (wall.tier + 1), "cost": -1, "locked": true}
		return {"text": "Muralla exterior · Nv.%d" % wall.tier, "cost": wall.cost if wall.hp <= 0 else (wall.tier * 25 if wall.hp == wall.max_hp else wall.data.repair_cost)}
	if target <= -320:
		var index: int = -320 - target
		if district.core.tier < int(FortressRules.ROLES[ROLES[index]]):
			return {"text": NAMES[index] + ": requiere núcleo Nv.%d" % int(FortressRules.ROLES[ROLES[index]]), "cost": -1, "locked": true}
		var waiting: String = employment_block(index)
		return {"text": NAMES[index] + " · disponibles %d" % tools[index] + (" · " + waiting if not waiting.is_empty() else ""), "cost": COSTS[index]}
	return {"text": "Reclutar superviviente · %d disponibles" % camp_stock[-300 - target], "cost": 5}

func interact(target: int) -> bool:
	if district.cycle.phase != "DÍA" and not (target <= -320 and target > -326):
		district.presenter.show_notice("Organiza la colonia durante el día")
		return false
	if target == -360:
		if capacity >= 20:
			if district.colony.workers.size() <= GameRules.INITIAL_POPULATION: return false
			var worker: ColonyWorker = district.colony.workers.pop_back()
			villagers.append({"x": REFUGE_X, "side": worker.side})
			worker.free()
			district.presenter.show_notice("Habitante disponible: compra la nueva herramienta")
		else:
			if capacity >= FortressRules.CAPACITY[district.core.tier - 1]:
				district.presenter.show_notice("Mejora el núcleo para ampliar el refugio")
				return false
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
		if district.core.tier < int(FortressRules.ROLES[ROLES[index]]):
			district.presenter.show_notice("Herramienta bloqueada: mejora el núcleo a Nv.%d" % int(FortressRules.ROLES[ROLES[index]]))
			return false
		if tools[index] >= 4 or not district.bank.spend(COSTS[index]): return false
		tools[index] += 1
		var blocked: String = employment_block(index)
		district.presenter.show_notice(NAMES[index] + (": " + blocked if not blocked.is_empty() else " preparado: un superviviente irá a recogerlo"))
	elif target in [-300, -301]:
		var index: int = -300 - target
		if camp_stock[index] <= 0 or population() >= capacity or not district.bank.spend(5): return false
		camp_stock[index] -= 1
		villagers.append({"x": -1340.0 if index == 0 else 1340.0, "side": -1.0 if index == 0 else 1.0})
	else: return false
	district.expansion.checkpoint()
	return true

func assign(index: int, role_index: int) -> bool:
	if index < 0 or index >= villagers.size() or role_index < 0 or role_index >= tools.size(): return false
	if tools[role_index] <= 0 or not role_ready(role_index): return false
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
	var reserved: Array[int] = [0, 0, 0, 0, 0, 0]
	var reserved_posts: Dictionary = {}
	for index: int in range(villagers.size() - 1, -1, -1):
		var citizen: Dictionary = villagers[index]
		var recovery: float = float(citizen.get("recover", 0))
		if recovery > 0:
			citizen.recover = maxf(0, recovery - delta)
			if citizen.recover == 0: citizen.rise = 0.56
			continue
		if float(citizen.get("rise", 0)) > 0:
			citizen.rise = maxf(0, float(citizen.rise) - delta)
			continue
		var destination: float = -600 + (index % 5 - 2) * 15
		var role_index: int = -1
		var nearest: float = INF
		for candidate: int in range(tools.size()):
			if tools[candidate] <= reserved[candidate] or not role_ready(candidate): continue
			if district.cycle.phase != "DÍA" and (absf(RACK_X[candidate]) > frontier(-1) or district.colony.unsafe_at(RACK_X[candidate])): continue
			var post: String = post_for(candidate)
			if not post.is_empty() and free_posts(candidate) <= int(reserved_posts.get(post, 0)): continue
			var distance: float = absf(float(citizen.x) - RACK_X[candidate])
			if distance < nearest:
				nearest = distance
				role_index = candidate
		if role_index >= 0:
			destination = RACK_X[role_index]
			reserved[role_index] += 1
			var post: String = post_for(role_index)
			if not post.is_empty(): reserved_posts[post] = int(reserved_posts.get(post, 0)) + 1
		elif district.cycle.phase != "DÍA": destination = citizen.side * maxf(40, frontier(citizen.side) - 60) + (index % 3 - 1) * 12
		citizen.x = move_toward(citizen.x, destination, delta * 65)
		if role_index >= 0 and absf(citizen.x - destination) < 12:
			if assign(index, role_index):
				reserved[role_index] -= 1
				var post: String = post_for(role_index)
				if not post.is_empty(): reserved_posts[post] = int(reserved_posts[post]) - 1
	sync_people(delta)
	queue_redraw()

func sync_people(delta: float) -> void:
	while people.size() > villagers.size(): people.pop_back().queue_free()
	while people.size() < villagers.size():
		var person: PersonVisual = PersonVisual.new()
		add_child(person)
		person.setup_person("civilian")
		person.position = Vector2(villagers[people.size()].x, GameRules.FLOOR_Y)
		people.append(person)
	for index: int in range(villagers.size()):
		var person: PersonVisual = people[index]
		var citizen: Dictionary = villagers[index]
		var displacement: float = float(citizen.x) - person.position.x
		person.position = Vector2(citizen.x, GameRules.FLOOR_Y)
		person.visible = float(citizen.get("recover", 0)) <= 0
		if float(citizen.get("rise", 0)) > 0:
			person.choose(&"levantarse")
		else:
			var direction: float = signf(displacement) if absf(displacement) > 0.01 else (-1 if person.sprite.flip_h else 1)
			person.update_person(delta, absf(displacement), false, direction, false, false, false, district.cycle.phase != "DÍA")
	update_employment_hint()

func update_employment_hint() -> void:
	if employment_hint == null:
		employment_hint = Label.new()
		employment_hint.position = Vector2(-710, GameRules.FLOOR_Y - 118)
		employment_hint.z_index = 5
		employment_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		employment_hint.add_theme_font_override("font", ThemeDB.fallback_font)
		employment_hint.add_theme_font_size_override("font_size", 12)
		employment_hint.add_theme_color_override("font_color", Color("ffce75"))
		employment_hint.add_theme_color_override("font_outline_color", Color("0b1322"))
		employment_hint.add_theme_constant_override("outline_size", 4)
		add_child(employment_hint)
	employment_hint.visible = absf(district.player.position.x + 600) < 170 and tools.any(func(stock: int) -> bool: return stock > 0)
	if not employment_hint.visible: return
	if villagers.is_empty():
		employment_hint.text = "Recluta supervivientes en los campamentos"
		return
	for index: int in range(tools.size()):
		if tools[index] > 0:
			var blocked: String = employment_block(index)
			if not blocked.is_empty():
				employment_hint.text = NAMES[index] + ": " + blocked
				return
	employment_hint.text = "Recogiendo herramientas · %d sin profesión" % villagers.size()

func role_ready(index: int) -> bool:
	return district.core.tier >= int(FortressRules.ROLES[ROLES[index]]) and (index < 2 or free_posts(index) > 0)

func post_for(index: int) -> String:
	return "" if index < 2 else ["barracks", "barracks", "generator", "medical"][index - 2]

func free_posts(index: int) -> int:
	var result: int = 0
	for site: ExpansionOutpost in district.expansion.sites:
		if site.spec.id == post_for(index) and site.hp > 0: result += maxi(0, site.staff_capacity() - site.staff_count())
	return result

func employment_block(index: int) -> String:
	if district.core.tier < int(FortressRules.ROLES[ROLES[index]]): return "Mejora el núcleo a Nv.%d" % int(FortressRules.ROLES[ROLES[index]])
	if district.cycle.phase != "DÍA" and absf(RACK_X[index]) > frontier(-1): return "Amplía las murallas hasta el taller"
	if index < 2: return ""
	if free_posts(index) > 0: return ""
	var built: bool = false
	for site: ExpansionOutpost in district.expansion.sites:
		if site.spec.id == post_for(index) and site.hp > 0: built = true
	var title: String = {"barracks": "cuartel", "generator": "generador", "medical": "puesto médico"}[post_for(index)]
	return title.capitalize() + " lleno" if built else "Construye un " + title

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
	if not ExpansionSystem.number(data.get("capacity"), 8, 20, true) or not ExpansionSystem.number(data.get("day"), 1, 1000000, true): return false
	if not data.get("villagers") is Array or data.villagers.size() > data.capacity: return false
	for citizen: Variant in data.villagers:
		if not citizen is Dictionary or not ExpansionSystem.number(citizen.get("x"), -1600, 1600) or not ExpansionSystem.number(citizen.get("side"), -1, 1, true) or absf(float(citizen.side)) != 1: return false
		if not ExpansionSystem.number(citizen.get("recover", 0), 0, 1.5) or not ExpansionSystem.number(citizen.get("rise", 0), 0, 1): return false
	if not data.get("gates") is Array or data.gates.size() != gate_count: return false
	for flag: Variant in data.gates:
		if not flag is bool: return false
	if not data.get("walls") is Array or data.walls.size() != 6: return false
	for wall: Variant in data.walls:
		if not wall is Dictionary or not ExpansionSystem.number(wall.get("tier"), 1, 3, true): return false
		if not ExpansionSystem.number(wall.get("hp"), 0, 240 * wall.tier, true) or not ExpansionSystem.number(wall.get("progress"), 0, 4) or not wall.get("ordered") is bool or not wall.get("upgrade") is bool: return false
	return true

func _draw() -> void:
	var workshop: Rect2 = ArtScale.source(GameArt.CIVIC, 2)
	ArtScale.footing(self, ArtScale.grounded(workshop, 94, Vector2(-600, GameRules.FLOOR_Y)))
	draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(workshop, 94, Vector2(-600, GameRules.FLOOR_Y)), workshop)
	for side: int in [-1, 1]:
		var x: float = side * 1340
		var camp: Rect2 = ArtScale.source(GameArt.CIVIC, 0)
		ArtScale.footing(self, ArtScale.grounded(camp, 50, Vector2(x, GameRules.FLOOR_Y)))
		draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(camp, 50, Vector2(x, GameRules.FLOOR_Y)), camp)
		for spark: int in range(4):
			var rise: float = fmod(elapsed * 14 + spark * 7, 23)
			draw_rect(Rect2(x + 25 + sin(elapsed * 2 + spark) * 2, GameRules.FLOOR_Y - 7 - rise, 1, 2), Color("ffce75", 1 - rise / 23))
	var ids: Array[String] = ["wrench", "scrap", "blade", "shield", "wrench", "medical"]
	for index: int in range(RACK_X.size()):
		var x: float = RACK_X[index]
		var unlocked: bool = district.core.tier >= int(FortressRules.ROLES[ROLES[index]])
		draw_texture_rect(GameArt.icon(ids[index]), Rect2(x - 9, 229, 18, 18), false, Color.WHITE if tools[index] > 0 else (Color("8299a8") if unlocked else Color("304356")))
		for item: int in range(tools[index]): draw_rect(Rect2(x - 8 + item * 5, 254, 3, 2), Color("ffce75"))
	var refuge: Rect2 = ArtScale.source(GameArt.CIVIC, 1)
	ArtScale.footing(self, ArtScale.grounded(refuge, 80, Vector2(REFUGE_X, GameRules.FLOOR_Y)))
	draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(refuge, 80, Vector2(REFUGE_X, GameRules.FLOOR_Y)), refuge)
