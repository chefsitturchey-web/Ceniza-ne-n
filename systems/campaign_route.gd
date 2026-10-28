class_name CampaignRoute
extends RefCounted
## Traspaso portátil: datos puros, sin referencias a escenas ni nodos anteriores.
const COUNT: int = 5
const ZONE_PATHS: Array[String] = ["res://data/zones/periphery.tres", "res://data/zones/foundry.tres", "res://data/zones/flooded.tres", "res://data/zones/citadel.tres", "res://data/zones/network.tres"]
const SCENES: Array[String] = ["res://levels/main.tscn", "res://levels/zones/foundry.tscn", "res://levels/zones/flooded.tscn", "res://levels/zones/citadel.tscn", "res://levels/zones/network.tscn"]
static var pending: Dictionary = {}
static var pending_path: String = "user://partida.json"
static var pending_persistence: bool = true
static var resume_path: String = ""

static func zone(index: int) -> ZoneData:
	return load(ZONE_PATHS[index]) as ZoneData

static func initial_state(zone: int = 0) -> Dictionary:
	var cleared: Array[bool] = []
	for index: int in range(COUNT):
		cleared.append(index < zone)
	return {"zone": zone, "cleared": cleared}

static func valid_state(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var zone: Variant = value.get("zone")
	var cleared: Variant = value.get("cleared")
	if not (zone is int or zone is float) or not is_finite(float(zone)) or zone != floorf(zone) or zone < 0 or zone >= COUNT:
		return false
	# Las rutas de la demo de tres distritos migran al cargar, sin perder la colonia.
	if not cleared is Array or (cleared.size() != COUNT and cleared.size() != 3) or zone >= cleared.size():
		return false
	for index: int in range(cleared.size()):
		if not cleared[index] is bool or cleared[index] != (index < int(zone)):
			return false
	return true

static func handoff(zone: int, neural: Dictionary, scrap: int, workers: Array) -> Dictionary:
	var roles: Array[String] = []
	for worker: Variant in workers:
		roles.append(String(worker.role))
	var carried: Dictionary = neural.duplicate(true)
	if not carried.get("experience", {}).is_empty():
		carried.experience.drops = []
		carried.experience.lost = {}
	return {"version": 1, "handoff": true, "campaign": initial_state(zone), "phase": "DÍA", "day": 1,
		"scrap": GameRules.INITIAL_SCRAP + mini(40, maxi(0, scrap)), "neural": carried, "crew": roles}

static func valid_handoff(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1 or value.get("handoff") != true or value.get("phase") != "DÍA" or value.get("day") != 1:
		return false
	if not valid_state(value.get("campaign")) or value.campaign.zone < 1 or not NeuralSystem.valid(value.get("neural")):
		return false
	var scrap: Variant = value.get("scrap")
	if not (scrap is int or scrap is float) or not is_finite(float(scrap)) or scrap != floorf(scrap) or scrap < GameRules.INITIAL_SCRAP or scrap > GameRules.INITIAL_SCRAP + 40:
		return false
	var crew: Variant = value.get("crew")
	if not crew is Array or crew.size() < GameRules.INITIAL_POPULATION or crew.size() > 20:
		return false
	for role: Variant in crew:
		if role not in ["builder", "collector"]:
			return false
	return "builder" in crew and "collector" in crew

static func queue_handoff(data: Dictionary, path: String, persistence: bool) -> void:
	pending = data.duplicate(true)
	pending_path = path
	pending_persistence = persistence

static func take(zone: int) -> Dictionary:
	if pending.is_empty() or not valid_handoff(pending) or int(pending.campaign.zone) != zone:
		return {}
	var result: Dictionary = {"data": pending.duplicate(true), "path": pending_path, "persistence": pending_persistence}
	pending.clear()
	pending_path = "user://partida.json"
	pending_persistence = true
	return result
