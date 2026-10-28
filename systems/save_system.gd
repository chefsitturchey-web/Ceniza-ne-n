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
	if data.get("version") != 1 or data.get("phase") != "DÍA":
		return {}
	for field: String in ["day", "scrap"]:
		var number: Variant = data.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number < (1 if field == "day" else 0) or number > 2147483647 or number != floorf(number):
			return {}
	if not data.get("player") is Dictionary or not data.get("structures") is Array:
		return {}
	return {"day": int(data.day), "scrap": int(data.scrap)}

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
			"ordered": site.ordered, "progress": site.progress, "shot": site.shot})
	var workers: Array = []
	for worker: ColonyWorker in session.colony.workers:
		workers.append({"role": String(worker.role), "side": worker.side, "x": worker.x,
			"job": worker.job, "gather": worker.gather, "cargo": worker.cargo})
	var player: Dictionary = _fields(session.player, PLAYER_FIELDS)
	player["x"] = session.player.position.x
	player["y"] = session.player.position.y
	player["velocity_x"] = session.player.velocity.x
	player["velocity_y"] = session.player.velocity.y
	return {"version": 1, "day": session.cycle.day, "phase": session.cycle.phase,
		"scrap": session.bank.scrap, "energy_capacity": session.bank.energy_capacity,
		"core_health": session.core.health, "player": player, "structures": structures,
		"workers": workers, "overload": _fields(session.overload, OVERLOAD_FIELDS),
		"drone_timer": session.defenses.drone_timer,
		"neural": session.neural.snapshot() if session.neural != null else {},
		"expedition": session.expedition.snapshot() if session.expedition != null else {}}

func save_game() -> bool:
	var data: Dictionary = _snapshot()
	if session.finished or not _valid(data):
		return false
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
		for field: String in ["hp", "ordered", "progress", "shot"]:
			site.set(field, data.structures[index][field])
		site.queue_redraw()
	for worker: ColonyWorker in session.colony.workers:
		worker.free()
	session.colony.workers.clear()
	for saved: Dictionary in data.workers:
		session.colony.add_worker(StringName(saved.role))
		var worker: ColonyWorker = session.colony.workers.back()
		for field: String in ["side", "x", "job", "gather", "cargo"]:
			worker.set(field, saved[field])
	for field: String in PLAYER_FIELDS:
		session.player.set(field, data.player[field])
	session.player.position = Vector2(data.player.x, data.player.y)
	session.player.velocity = Vector2(data.player.velocity_x, data.player.velocity_y)
	session.player.refresh_state()
	_apply(session.overload, data.overload)
	session.overload.tick(0.0)
	session.defenses.drone_timer = data.drone_timer
	session.bank.changed.emit(session.bank.scrap, session.bank.energy_used(), session.bank.energy_capacity)
	return true

func _number(data: Dictionary, key: String, minimum: float, maximum: float, integer: bool = false) -> bool:
	var value: Variant = data.get(key)
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and value >= minimum and value <= maximum and (not integer or float(value) == floorf(float(value)))

func _valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	if not NeuralSystem.valid(data.get("neural", {})):
		return false
	if not ExpeditionManager.valid(data.get("expedition", {})):
		return false
	if not _number(data, "version", 1, 1, true) or data.get("phase") != "DÍA":
		return false
	if not _number(data, "day", 1, session.cycle.config.nights, true) or not _number(data, "core_health", 1, session.core.health_component.maximum, true):
		return false
	for field: String in ["scrap", "energy_capacity"]:
		if not _number(data, field, 0, 2147483647, true):
			return false
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
		if not _number(entry, "hp", 0, site.max_hp, true) or not _number(entry, "progress", 0, GameRules.BUILD_TIME) or not _number(entry, "shot", 0, maxf(site.data.interval, site.data.overloaded_interval)):
			return false
	if not data.get("workers") is Array or data.workers.size() < GameRules.INITIAL_POPULATION or data.workers.size() > GameRules.POPULATION:
		return false
	var jobs: Array[int] = []
	for entry: Variant in data.workers:
		if not entry is Dictionary or entry.get("role") not in ["builder", "collector"]:
			return false
		var worker_data: WorkerData = session.colony.builder_data if entry.role == "builder" else session.colony.collector_data
		if not _number(entry, "side", -1, 1) or absf(entry.side) != 1 or not _number(entry, "x", -1000000, 1000000):
			return false
		if not _number(entry, "job", -1, data.structures.size() - 1, true) or not _number(entry, "cargo", 0, worker_data.cargo, true) or not _number(entry, "gather", 0, worker_data.gather_time):
			return false
		if entry.job >= 0:
			if entry.role != "builder" or int(entry.job) in jobs or not data.structures[int(entry.job)].ordered:
				return false
			jobs.append(int(entry.job))
	return true
