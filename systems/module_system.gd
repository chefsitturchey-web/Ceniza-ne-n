class_name ModuleSystem
extends Node2D
## Dos módulos automáticos como máximo. La evolución requiere nivel, pasiva y núcleo.
const DATA: Array[ModuleData] = [preload("res://data/modules/drone.tres"), preload("res://data/modules/tesla.tres"), preload("res://data/modules/orbital.tres")]
const MAX_LEVEL: int = 5
const SLOTS: int = 2
const PASSIVE_IDS: Array[String] = ["optic", "battery", "bearing", "magnet", "condenser", "recovery"]
const PASSIVE_TITLES: Dictionary = {"optic": "Óptica táctica", "battery": "Batería auxiliar", "bearing": "Rodamiento magnético", "magnet": "Bobina de atracción", "condenser": "Condensador de impacto", "recovery": "Recuperador cinético"}
const PASSIVE_TEXT: Dictionary = {"optic": "Mayor alcance del dron; catalizador de Enjambre.", "battery": "Mayor alcance Tesla; catalizador de Tormenta.", "bearing": "Mayor radio orbital; catalizador de Corona de acero.", "magnet": "Atrae datos neuronales desde más lejos.", "condenser": "+4 daño de hoja por nivel de pasiva.", "recovery": "+2 regeneración de resistencia por nivel."}
var levels: Dictionary = {"drone": 1, "tesla": 0, "orbital": 0}
var passives: Dictionary = {"optic": false, "battery": false, "bearing": false, "magnet": false, "condenser": false, "recovery": false}
var passive_levels: Dictionary = {"optic": 0, "battery": 0, "bearing": 0, "magnet": 0, "condenser": 0, "recovery": 0}
var evolved: Dictionary = {"drone": false, "tesla": false, "orbital": false}
var equipped: Array[String] = ["drone"]
var cores: int = 0
var timers: Dictionary = {"tesla": 0.0, "orbital": 0.0, "drone": 0.0}
var actor: CharacterBody2D
var defenses: DefenseSystem
var boss: Recaudador
var planar: bool = false
var elapsed: float = 0.0
var flashes: Array[Dictionary] = []
signal fired

static func definition(id: String) -> ModuleData:
	for data: ModuleData in DATA:
		if data.id == id:
			return data
	return null

func spent() -> int:
	var total: int = -1 # El primer nivel del dron es gratuito.
	for value: int in levels.values():
		total += value
	for id: String in PASSIVE_IDS:
		total += passive_rank(id)
	return total

func passive_rank(id: String) -> int:
	return maxi(int(passive_levels.get(id, 0)), 1 if passives.get(id, false) else 0)

func passive_count() -> int:
	var count: int = 0
	for id: String in PASSIVE_IDS:
		if passives[id]: count += 1
	return count

func toggle_passive(id: String) -> bool:
	if id not in PASSIVE_IDS or passive_rank(id) == 0: return false
	if not passives[id] and passive_count() >= 4: return false
	passives[id] = not passives[id]
	return true

func damage_for(id: String) -> int:
	var data: ModuleData = definition(id)
	return data.damage + maxi(0, int(levels[id]) - 1) * data.damage_per_level

func command_damage() -> int:
	# Los enlaces equipados transmiten mejoras a las tropas sin disparar en colonia.
	var bonus: int = 0
	for id: String in equipped:
		bonus += int(levels[id]) + (3 if evolved[id] else 0)
	return bonus + (passive_rank("condenser") if passives.condenser else 0)

func range_for(id: String) -> float:
	var result: float = definition(id).attack_range
	if id == "drone" and passives.optic:
		result += 25 + maxi(0, passive_rank("optic") - 1) * 5
	elif id == "tesla" and passives.battery:
		result += 20 + maxi(0, passive_rank("battery") - 1) * 3
	elif id == "orbital" and passives.bearing:
		result += 8 + maxi(0, passive_rank("bearing") - 1) * 2
	if id == "orbital" and evolved.orbital:
		result += 18
	return result

func equip(id: String) -> bool:
	if not levels.has(id) or levels[id] <= 0:
		return false
	if id in equipped:
		if equipped.size() == 1:
			return false
		equipped.erase(id)
		return true
	if equipped.size() >= SLOTS:
		return false
	equipped.append(id)
	return true

func can_evolve(id: String) -> bool:
	var data: ModuleData = definition(id)
	return data != null and levels[id] == MAX_LEVEL and passives[data.passive] and not evolved[id] and cores > 0

func evolve(id: String) -> bool:
	if not can_evolve(id):
		return false
	cores -= 1
	evolved[id] = true
	return true

func snapshot() -> Dictionary:
	var ranks: Dictionary = {}
	for id: String in PASSIVE_IDS: ranks[id] = passive_rank(id)
	return {"levels": levels.duplicate(), "passives": passives.duplicate(), "passive_levels": ranks, "evolved": evolved.duplicate(), "equipped": equipped.duplicate(), "cores": cores}

func restore(data: Dictionary) -> void:
	levels = data.get("levels", {"drone": 1, "tesla": 0, "orbital": 0}).duplicate()
	passives = data.get("passives", {"optic": false, "battery": false, "bearing": false}).duplicate()
	passives["magnet"] = passives.get("magnet", false)
	passive_levels = data.get("passive_levels", {}).duplicate()
	for id: String in PASSIVE_IDS:
		passives[id] = passives.get(id, false)
		passive_levels[id] = int(passive_levels.get(id, 1 if passives[id] else 0))
	evolved = data.get("evolved", {"drone": false, "tesla": false, "orbital": false}).duplicate()
	equipped.assign(data.get("equipped", ["drone"]))
	cores = int(data.get("cores", 0))
	for id: String in levels:
		levels[id] = int(levels[id])
		timers[id] = 0.0
	queue_redraw()

static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	for field: String in ["levels", "evolved"]:
		if not value.get(field) is Dictionary or value[field].size() != 3:
			return false
	if not value.get("passives") is Dictionary or value.passives.size() not in [3, 4, 6]: return false
	var active: int = 0
	for id: Variant in value.passives:
		if id not in PASSIVE_IDS or not value.passives[id] is bool: return false
		if value.passives[id]: active += 1
	if active > 4: return false
	if value.passives.has("magnet") and not value.passives.magnet is bool: return false
	if value.has("passive_levels"):
		if not value.passive_levels is Dictionary or value.passive_levels.size() not in [4, 6]: return false
		for id: String in PASSIVE_IDS:
			if not ExpansionSystem.number(value.passive_levels.get(id, 0), 0, 5, true) or (value.passives.get(id, false) and value.passive_levels.get(id, 0) == 0): return false
	var core_count: Variant = value.get("cores")
	if not (core_count is int or core_count is float) or not is_finite(float(core_count)) or core_count < 0 or core_count > 1000000 or floorf(core_count) != core_count:
		return false
	for data: ModuleData in DATA:
		var level: Variant = value.levels.get(data.id)
		if not (level is int or level is float) or not is_finite(float(level)) or level < (1 if data.id == "drone" else 0) or level > MAX_LEVEL or level != floorf(level):
			return false
		if not value.evolved.get(data.id) is bool or not value.passives.get(data.passive) is bool:
			return false
		if value.evolved[data.id] and level != MAX_LEVEL:
			return false
	var slots: Variant = value.get("equipped")
	if not slots is Array or slots.is_empty() or slots.size() > SLOTS:
		return false
	var unique: Array = []
	for id: Variant in slots:
		if not id is String or not value.levels.has(id) or value.levels[id] <= 0 or id in unique:
			return false
		unique.append(id)
	return true

static func saved_spent(value: Dictionary) -> int:
	if value.is_empty():
		return 0
	var total: int = -1
	for level: Variant in value.levels.values():
		total += int(level)
	for id: String in PASSIVE_IDS:
		total += int(value.get("passive_levels", {}).get(id, 1 if value.passives.get(id, false) else 0))
	return total

func _process(delta: float) -> void:
	elapsed += delta
	for index: int in range(flashes.size() - 1, -1, -1):
		flashes[index].time -= delta
		if flashes[index].time <= 0:
			flashes.remove_at(index)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if planar and is_instance_valid(actor) and actor.health > 0 and is_instance_valid(boss) and boss.health > 0:
		update_arena(delta)

func update_lateral(delta: float) -> void:
	if actor is Player and not actor.combat_enabled: return
	if actor == null or actor.health <= 0:
		return
	for id: String in ["tesla", "orbital"]:
		timers[id] = maxf(0.0, float(timers[id]) - delta)
		if id not in equipped or timers[id] > 0:
			continue
		var target: Node2D = defenses.nearest_enemy(actor.position.x, range_for(id))
		if target == null:
			continue
		if id == "tesla":
			fire_tesla(target)
		else:
			var count: int = 0
			for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
				if absf(enemy.position.x - actor.position.x) <= range_for(id) and count < (6 if evolved.orbital else 3):
					defenses.fire_from(actor.position + Vector2(0, -18), enemy, damage_for(id))
					count += 1
			timers.orbital = 0.65 if evolved.orbital else definition(id).interval

func fire_tesla(target: Node2D) -> void:
	var origin: Vector2 = actor.position + Vector2(0, -25)
	var used: Array[Node2D] = []
	var current: Node2D = target
	var chain_limit: int = 4 if evolved.tesla else 1
	for index: int in range(chain_limit):
		if current == null:
			break
		used.append(current)
		var endpoint: Vector2 = current.position + Vector2(0, -16)
		defenses.fire_from(origin, current, maxi(1, roundi(damage_for("tesla") * pow(0.8, index))), true)
		origin = endpoint
		current = null
		var distance: float = 96.0
		for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
			var candidate: float = absf(enemy.position.x - endpoint.x)
			if enemy not in used and candidate < distance:
				distance = candidate
				current = enemy
		timers.tesla = definition("tesla").interval

func update_arena(delta: float) -> void:
	for id: String in equipped:
		timers[id] = maxf(0.0, float(timers[id]) - delta)
		var distance: float = actor.global_position.distance_to(boss.global_position)
		if timers[id] > 0 or distance > range_for(id) + 29:
			continue
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(actor.global_position, boss.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		var damage: int = damage_for(id)
		if id == "drone":
			damage += int(actor.get("drone_rank")) * 4
			if evolved.drone:
				damage = roundi(damage * 1.65)
		elif id == "tesla" and evolved.tesla:
			damage = roundi(damage * 1.4)
		boss.receive_hit(actor.global_position, damage)
		var muzzle: Vector2 = drone_origin(0) if id == "drone" else actor.global_position + Vector2(0, -20)
		flashes.append({"from": muzzle, "to": boss.global_position, "time": 0.12, "electric": id == "tesla"})
		fired.emit()
		timers[id] = definition(id).interval * (1.0 - int(actor.get("drone_rank")) * 0.1) if id == "drone" else definition(id).interval

func drone_origin(index: int) -> Vector2:
	return actor.position + Vector2(-22 if index == 0 else 22, -26 + roundf(sin(elapsed * 3 + index * PI) * 2))

func _draw() -> void:
	if not is_instance_valid(actor) or actor.health <= 0:
		return
	if planar and "drone" in equipped:
		for index: int in range(2 if evolved.drone else 1):
			var center: Vector2 = drone_origin(index).round()
			draw_rect(Rect2(center - Vector2(7, 3), Vector2(14, 6)), Color("0b1322"))
			draw_rect(Rect2(center - Vector2(5, 2), Vector2(10, 4)), Color("8299a8"))
			draw_rect(Rect2(center - Vector2(2, 1), Vector2(4, 2)), Color("47dacb"))
			for side: int in [-1, 1]:
				draw_rect(Rect2(center + Vector2(side * 4 - 1, 4), Vector2(2, 3)), Color("47dacb"))
	if "tesla" in equipped:
		var center: Vector2 = actor.position + Vector2(-10, -27 if planar else -32)
		draw_rect(Rect2(center - Vector2(2, 5), Vector2(5, 10)), Color("0b1322"))
		for ring: int in range(3):
			draw_rect(Rect2(center + Vector2(-3, -3 + ring * 3), Vector2(7, 1)), Color("47dacb"))
	if "orbital" in equipped:
		var origin: Vector2 = actor.position if planar else actor.position + Vector2(0, -18)
		var count: int = 4 if evolved.orbital else 2
		for index: int in range(count):
			var angle: float = elapsed * 3.0 + index * TAU / count
			var offset: Vector2 = Vector2(cos(angle), sin(angle) * (1.0 if planar else 0.3)) * range_for("orbital")
			var center: Vector2 = (origin + offset).round()
			draw_circle(center, 4, Color("0b1322"))
			draw_line(center - Vector2(4, 0), center + Vector2(4, 0), Color("8299a8"), 2)
			draw_line(center - Vector2(0, 3), center + Vector2(0, 3), Color("47dacb"), 1)
	for flash: Dictionary in flashes:
		draw_line(flash.from, flash.to, Color("47dacb") if flash.electric else Color("ffce75"), 1)
