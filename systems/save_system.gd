class_name SaveSystem
extends Node

## Instantánea de preparación. Las referencias las proporciona SessionController.
var session: SessionController
var save_path: String = "user://partida.json"
const PLAYER_FIELDS: Array[String] = ["health", "stamina", "facing", "attack_facing", "cooldown_remaining", "slash_remaining", "invulnerable", "dodge_remaining", "dodge_direction", "respawn_remaining"]
const OVERLOAD_FIELDS: Array[String] = ["overload_left", "overload_right", "cooldown_left", "cooldown_right"]

static func checkpoint_info(path: String = "user://partida.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	if data.get("handoff", false) == true:
		return {"day": 1, "scrap": int(data.scrap), "zone": int(data.campaign.zone)} if CampaignRoute.valid_handoff(data) else {}
	if not CampaignRoute.valid_state(data.get("campaign", CampaignRoute.initial_state())):
		return {}
	if data.get("version") != 1 or data.get("phase") != "DÍA":
		return {}
	for field: String in ["day", "scrap"]:
		var number: Variant = data.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number < (1 if field == "day" else 0) or number > 2147483647 or number != floorf(number):
			return {}
	if not data.get("player") is Dictionary or not data.get("structures") is Array:
		return {}
	return {"day": int(data.day), "scrap": int(data.scrap), "zone": int(data.get("campaign", CampaignRoute.initial_state()).zone)}

static func archive_checkpoint(path: String = "user://partida.json", remove_original: bool = true) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var original: String = ProjectSettings.globalize_path(path)
	var backup: String = original + ".anterior"
	if DirAccess.copy_absolute(original, backup) != OK:
		return false
	return not remove_original or DirAccess.remove_absolute(original) == OK

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func _fields(object: Object, names: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for field: String in names:
		result[field] = object.get(field)
	return result

func _apply(object: Object, values: Dictionary) -> void:
	for field: String in values:
		object.set(field, values[field])

func _snapshot() -> Dictionary:
	var structures: Array = []
	for site: ConstructionSite in session.bank.sites:
		structures.append({"kind": String(site.kind), "x": site.x, "hp": site.hp,
			"ordered": site.ordered, "progress": site.progress, "shot": site.shot, "tier": site.tier, "upgrade": site.upgrade_pending, "powered": site.powered, "shorted": site.shorted})
	var workers: Array = []
	for worker: ColonyWorker in session.colony.workers:
		workers.append({"role": String(worker.role), "side": worker.side, "x": worker.x,
			"job": worker.job, "external_job": worker.external_job, "gather": worker.gather, "cargo": worker.cargo, "hp": worker.hp, "damage_accum": worker.damage_accum, "wander_target": worker.wander_target, "wander_timer": worker.wander_timer})
	var player: Dictionary = _fields(session.player, PLAYER_FIELDS)
	player["x"] = session.player.position.x
	player["y"] = session.player.position.y
	player["velocity_x"] = session.player.velocity.x
	player["velocity_y"] = session.player.velocity.y
	return {"version": 1, "day": session.cycle.day, "phase": session.cycle.phase, "campaign": session.campaign.duplicate(true),
		"invasion": InvasionState.snapshot(session), "scrap": session.bank.scrap, "energy_capacity": session.bank.energy_capacity,
		"expansion": session.expansion.snapshot() if session.expansion != null else {},
		"civic": session.civic.snapshot() if session.civic != null else {},
		"story": session.interaction.story.snapshot() if session.interaction.story != null else {},
		"core_building": session.core.snapshot(),
		"mobility": session.interaction.mobility.snapshot() if session.interaction.mobility != null else {},
		"core_health": session.core.health, "player": player, "structures": structures,
		"workers": workers, "overload": _fields(session.overload, OVERLOAD_FIELDS),
		"drone_timer": session.defenses.drone_timer,
		"neural": session.neural.snapshot() if session.neural != null else {},
		"expedition": session.expedition.snapshot() if session.expedition != null else {}}

func save_game() -> bool:
	var data: Dictionary = _snapshot()
	if session.finished or not _valid(data):
		return false
	return write_document(data)

func save_handoff(data: Dictionary) -> bool:
	if not CampaignRoute.valid_handoff(data) or int(data.campaign.zone) != session.zone_index + 1:
		return false
	return write_document(data)

func write_document(data: Dictionary) -> bool:
	# Escribir aparte evita truncar la partida anterior si falla la escritura.
	var pending_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(pending_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var success: bool = file.get_error() == OK
	file.close()
	if not success:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(pending_path), ProjectSettings.globalize_path(save_path)) == OK

func load_game() -> bool:
	if not has_save():
		return false
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parser: JSON = JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not _valid(parser.data):
		return false
	# Validar todo antes de modificar la sesión evita cargas parciales.
	var data: Dictionary = parser.data
	if data.get("handoff", false) == true:
		apply_handoff(data)
		return true
	session.campaign = CampaignRoute.initial_state(int(data.get("campaign", CampaignRoute.initial_state()).zone))
	var saved_core: Dictionary = data.get("core_building", {"tier": ColonyCore.saved_tier(data), "ordered": false, "progress": 0})
	session.core.restore(saved_core)
	if session.interaction.mobility != null: session.interaction.mobility.restore(data.get("mobility", {}))
	if session.expansion != null:
		session.expansion.restore(data.get("expansion", {}))
	if session.civic != null: session.civic.restore(data.get("civic", {}))
	if session.interaction.story != null: session.interaction.story.restore(data.get("story", {}))
	if session.neural != null:
		session.neural.restore(data.get("neural", {}))
	if session.expedition != null:
		session.expedition.restore(data.get("expedition", {}))
	session.cycle.day = int(data.day)
	session.cycle.phase = data.phase
	session.cycle.phase_remaining = session.cycle.config.day_duration
	session.bank.scrap = int(data.scrap)
	session.bank.energy_capacity = int(data.energy_capacity)
	session.core.health = int(data.core_health)
	for index: int in range(data.structures.size()):
		var site: ConstructionSite = session.bank.sites[index]
		site.tier = int(data.structures[index].get("tier", 1))
		site.health_component.maximum = site.data.health * site.tier
		site.upgrade_pending = data.structures[index].get("upgrade", false)
		site.powered = data.structures[index].get("powered", true)
		site.shorted = data.structures[index].get("shorted", false)
		for field: String in ["hp", "ordered", "progress", "shot"]:
			site.set(field, data.structures[index][field])
		site.queue_redraw()
	for worker: ColonyWorker in session.colony.workers:
		worker.free()
	session.colony.workers.clear()
	for saved: Dictionary in data.workers:
		session.colony.add_worker(StringName(saved.role))
		var worker: ColonyWorker = session.colony.workers.back()
		worker.external_job = int(saved.get("external_job", -1))
		worker.health_component.reset(int(saved.get("hp", GameRules.WORKER_HEALTH)))
		worker.damage_accum = saved.get("damage_accum", 0.0)
		worker.wander_target = saved.get("wander_target", saved.x)
		worker.wander_timer = saved.get("wander_timer", 0.0)
		for field: String in ["side", "x", "job", "gather", "cargo"]:
			worker.set(field, saved[field])
	for field: String in PLAYER_FIELDS:
		session.player.set(field, data.player[field])
	session.player.position = Vector2(data.player.x, data.player.y)
	session.player.velocity = Vector2(data.player.velocity_x, data.player.velocity_y)
	session.player.refresh_state()
	InvasionState.restore(session, data.get("invasion", {}))
	_apply(session.overload, data.overload)
	session.overload.tick(0.0)
	session.defenses.drone_timer = data.drone_timer
	session.bank.changed.emit(session.bank.scrap, session.bank.energy_used(), session.bank.available_capacity())
	return true

func apply_handoff(data: Dictionary) -> void:
	session.campaign = CampaignRoute.initial_state(int(data.campaign.zone))
	session.bank.scrap = int(data.scrap)
	session.neural.restore(data.neural)
	if session.interaction.mobility != null: session.interaction.mobility.restore(data.get("mobility", {}))
	if session.civic != null: session.civic.capacity = mini(20, maxi(8, ceili(data.crew.size() / 4.0) * 4))
	for worker: ColonyWorker in session.colony.workers:
		worker.free()
	session.colony.workers.clear()
	for role: String in data.crew:
		session.colony.add_worker(StringName(role))
	session.player.health = Player.MAX_HEALTH
	session.player.stamina = Player.MAX_STAMINA
	session.player.position = Vector2(0, GameRules.FLOOR_Y)
	session.player.refresh_state()
	session.bank.changed.emit(session.bank.scrap, session.bank.energy_used(), session.bank.available_capacity())

func _number(data: Dictionary, key: String, minimum: float, maximum: float, integer: bool = false) -> bool:
	var value: Variant = data.get(key)
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and value >= minimum and value <= maximum and (not integer or float(value) == floorf(float(value)))

func _valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if not ColonyCore.valid(data.get("core_building", {})): return false
	if not MobilitySystem.valid(data.get("mobility", {})): return false
	if not ExpansionSystem.valid(data.get("expansion", {})):
		return false
	if not StoryDirector.valid(data.get("story", {})): return false
	if not CivicSystem.valid(data.get("civic", {}), mini(3, session.zone_index) * 2): return false
	for wall: Dictionary in data.get("civic", {}).get("walls", []):
		if int(wall.tier) > ColonyCore.saved_tier(data): return false
	if not data.get("civic", {}).is_empty() and data.get("workers") is Array:
		var population: int = data.workers.size() + data.civic.villagers.size()
		for site: Dictionary in data.get("expansion", {}).get("sites", []):
			population += site.get("crew", [site.ally] if not site.get("ally", {}).is_empty() else []).size()
		if population > data.civic.capacity: return false
	if data.get("handoff", false) == true:
		return CampaignRoute.valid_handoff(data) and int(data.campaign.zone) == session.zone_index
	var route: Variant = data.get("campaign", CampaignRoute.initial_state())
	if not CampaignRoute.valid_state(route) or int(route.zone) != session.zone_index:
		return false
	if not NeuralSystem.valid(data.get("neural", {})):
		return false
	if not ExpeditionManager.valid(data.get("expedition", {})):
		return false
	if not _number(data, "version", 1, 1, true) or data.get("phase") != "DÍA":
		return false
	if not _number(data, "day", 1, 1000000 if session.cycle.boss_required else session.cycle.config.nights, true) or not _number(data, "core_health", 1, FortressRules.CORE_HEALTH[ColonyCore.saved_tier(data) - 1], true):
		return false
	for field: String in ["scrap", "energy_capacity"]:
		if not _number(data, field, 0, 2147483647, true):
			return false
	if not InvasionState.valid(data.get("invasion", {}), session, int(data.day)): return false
	if not _number(data, "drone_timer", 0, GameRules.DRONE_INTERVAL):
		return false
	if not data.get("player") is Dictionary or not data.get("overload") is Dictionary:
		return false
	for field: String in PLAYER_FIELDS + ["x", "y", "velocity_x", "velocity_y"]:
		if not _number(data.player, field, -1000000, 1000000):
			return false
	if not _number(data.player, "health", 0, Player.MAX_HEALTH, true) or not _number(data.player, "stamina", 0, Player.MAX_STAMINA):
		return false
	for field: String in OVERLOAD_FIELDS:
		if not _number(data.overload, field, 0, GameRules.OVERLOAD_COOLDOWN):
			return false
	if data.overload.size() != OVERLOAD_FIELDS.size():
		return false
	if not data.get("structures") is Array or data.structures.size() != session.bank.sites.size():
		return false
	for index: int in range(data.structures.size()):
		var entry: Variant = data.structures[index]
		var site: ConstructionSite = session.bank.sites[index]
		if not entry is Dictionary:
			return false
		if entry.get("kind") != String(site.kind) or not _number(entry, "x", site.x, site.x) or not entry.get("ordered") is bool:
			return false
		var tier: Variant = entry.get("tier", 1)
		if not entry.get("powered", true) is bool or not entry.get("shorted", false) is bool: return false
		if entry.get("shorted", false) and entry.get("powered", true): return false
		if not ExpansionSystem.number(tier, 1, 3, true) or int(tier) > ColonyCore.saved_tier(data) or not entry.get("upgrade", false) is bool: return false
		if not _number(entry, "hp", 0, site.data.health * tier, true) or not _number(entry, "progress", 0, GameRules.BUILD_TIME) or not _number(entry, "shot", 0, maxf(site.data.interval, site.data.overloaded_interval)):
			return false
	if not data.get("workers") is Array or data.workers.size() < (0 if data.has("invasion") else GameRules.INITIAL_POPULATION) or data.workers.size() > 20:
		return false
	var jobs: Array[int] = []
	for entry: Variant in data.workers:
		if not entry is Dictionary or entry.get("role") not in ["builder", "collector"]:
			return false
		for field: String in ["hp", "damage_accum", "wander_target", "wander_timer"]:
			if not entry.has(field): continue
			var low: float = 1.0 if field == "hp" else (-1000000.0 if field in ["wander_target", "wander_timer"] else 0.0)
			var high: float = GameRules.WORKER_HEALTH if field == "hp" else (1.0 if field == "damage_accum" else 1000000.0)
			if not _number(entry, field, low, high, field == "hp"): return false
		var worker_data: WorkerData = session.colony.builder_data if entry.role == "builder" else session.colony.collector_data
		if not ExpansionSystem.number(entry.get("external_job", -1), -1, 13, true): return false
		if not _number(entry, "side", -1, 1) or absf(entry.side) != 1 or not _number(entry, "x", -1000000, 1000000):
			return false
		if not _number(entry, "job", -1, data.structures.size() - 1, true) or not _number(entry, "cargo", 0, worker_data.cargo, true) or not _number(entry, "gather", 0, worker_data.gather_time):
			return false
		if entry.job >= 0:
			if entry.role != "builder" or int(entry.job) in jobs or not data.structures[int(entry.job)].ordered:
				return false
			jobs.append(int(entry.job))
	return true
