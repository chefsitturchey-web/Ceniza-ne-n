class_name FortressRules
extends RefCounted
const BUILDINGS: Dictionary = {"barracks": 1, "generator": 1, "medical": 2, "recycler": 2}
const ROLES: Dictionary = {"builder": 1, "collector": 1, "ranger": 1, "guardian": 2, "technician": 2, "medic": 2}
const CAPACITY: Array[int] = [8, 16, 20]
const UPGRADE_COSTS: Array[int] = [60, 120, 0]
const CORE_HEALTH: Array[int] = [300, 450, 650]

static func damage(site: ConstructionSite) -> int:
	return roundi(site.data.damage * [1.0, 1.45, 2.0][site.tier - 1])

static func interval(site: ConstructionSite, boosted: bool) -> float:
	return (site.data.overloaded_interval if boosted else site.data.interval) * [1.0, 0.85, 0.7][site.tier - 1]

static func reach(site: ConstructionSite) -> float:
	return site.data.attack_range + (site.tier - 1) * 30
