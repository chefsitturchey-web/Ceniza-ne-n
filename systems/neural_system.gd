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
var modules: ModuleSystem
var experience: ExperienceSystem

func points() -> int:
	return kills / KILLS_PER_POINT + (experience.level - 1 + experience.chest_credits if experience != null else 0) - int(ranks.blade) - int(ranks.drone) - int(ranks.capacitor) - (modules.spent() if modules != null else 0)

func upgrade_module(id: String) -> bool:
	if modules == null or not modules.levels.has(id) or points() <= 0 or modules.levels[id] >= ModuleSystem.MAX_LEVEL:
		return false
	modules.levels[id] += 1
	if id not in modules.equipped and modules.equipped.size() < ModuleSystem.SLOTS:
		modules.equipped.append(id)
	changed.emit()
	return true

func install_passive(id: String) -> bool:
	if modules == null or not modules.passives.has(id) or modules.passive_rank(id) >= 5 or points() <= 0:
		return false
	if not modules.passives[id] and modules.passive_count() >= 4: return false
	modules.passive_levels[id] = modules.passive_rank(id) + 1
	modules.passives[id] = true
	apply_modules()
	changed.emit()
	return true

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
	player.neural_damage = int(ranks.blade) * 10 + (modules.passive_rank("condenser") * 4 if modules != null and modules.passives.condenser else 0)
	player.neural_regen = float(ranks.capacitor) * 5.0 + (modules.passive_rank("recovery") * 2 if modules != null and modules.passives.recovery else 0)
	defenses.drone_rank = int(ranks.drone)

func snapshot() -> Dictionary:
	return {"kills": kills, "ranks": ranks.duplicate(), "modules": modules.snapshot() if modules != null else {}, "experience": experience.snapshot() if experience != null else {}}

func restore(data: Dictionary) -> void:
	if experience != null: experience.restore(data.get("experience", {}))
	kills = int(data.get("kills", 0))
	var saved: Dictionary = data.get("ranks", {})
	for id: String in IDS:
		ranks[id] = int(saved.get(id, 0))
	if modules != null:
		modules.restore(data.get("modules", {}))
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
	var equipment: Variant = value.get("modules", {})
	var progression: Variant = value.get("experience", {})
	if not ExperienceSystem.valid(progression): return false
	var credits: int = int(progression.get("level", 1)) - 1 + int(progression.get("chest_credits", 0))
	return ModuleSystem.valid(equipment) and spent + ModuleSystem.saved_spent(equipment) <= int(count) / KILLS_PER_POINT + credits
