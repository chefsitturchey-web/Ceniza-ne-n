class_name NeuralSystem
extends Node
## Los datos pertenecen a la colonia: cualquier defensa puede recuperarlos.
signal changed
signal point_earned
const KILLS_PER_POINT: int = 6
const MAX_RANK: int = 3
const IDS: Array[String] = ["blade", "drone", "capacitor"]
var kills: int = 0
var ranks: Dictionary = {"blade": 0, "drone": 0, "capacitor": 0}
var player: Player
var defenses: DefenseSystem

func points() -> int:
	return kills / KILLS_PER_POINT - int(ranks.blade) - int(ranks.drone) - int(ranks.capacitor)

func recover_data(_reward: int) -> void:
	kills += 1
	changed.emit()
	if kills % KILLS_PER_POINT == 0:
		point_earned.emit()

func install(id: String) -> bool:
	if id not in IDS or points() <= 0 or ranks[id] >= MAX_RANK:
		return false
	ranks[id] += 1
	apply_modules()
	changed.emit()
	return true

func apply_modules() -> void:
	player.neural_damage = int(ranks.blade) * 10
	player.neural_regen = float(ranks.capacitor) * 5.0
	defenses.drone_rank = int(ranks.drone)

func snapshot() -> Dictionary:
	return {"kills": kills, "ranks": ranks.duplicate()}

func restore(data: Dictionary) -> void:
	kills = int(data.get("kills", 0))
	var saved: Dictionary = data.get("ranks", {})
	for id: String in IDS:
		ranks[id] = int(saved.get(id, 0))
	apply_modules()
	changed.emit()

static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	var count: Variant = value.get("kills")
	var saved: Variant = value.get("ranks")
	if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > 1000000 or floorf(count) != count:
		return false
	if not saved is Dictionary or saved.size() != IDS.size():
		return false
	var spent: int = 0
	for id: String in IDS:
		var rank: Variant = saved.get(id)
		if not (rank is int or rank is float) or not is_finite(float(rank)) or rank < 0 or rank > MAX_RANK or floorf(rank) != rank:
			return false
		spent += int(rank)
	return spent <= int(count) / KILLS_PER_POINT
