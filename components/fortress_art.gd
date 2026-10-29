class_name FortressArt
extends RefCounted
const CORE_HEIGHTS: Array[float] = [72, 88, 106]
const WALL_HEIGHTS: Array[float] = [40, 54, 68]
const TURRET_HEIGHTS: Array[float] = [30, 40, 50]
const FAMILY: Texture2D = preload("res://assets/world/structures/coherent_fortress_v3.png")
const WALLS: Texture2D = preload("res://assets/world/structures/coherent_walls_v3.png")
static var atlas_cache: Dictionary = {}


static func texture(kind: String, tier: int) -> Texture2D:
	var level: int = clampi(tier, 1, 3) - 1
	var key: String = kind + str(level)
	if not atlas_cache.has(key):
		var index: int = {"core": 0, "turret_base": 6, "turret_head": 9}.get(kind, 0) + level
		atlas_cache[key] = ArtScale.atlas(WALLS if kind == "wall" else FAMILY, level if kind == "wall" else index)
	return atlas_cache[key] as Texture2D

static func size_of(kind: String, tier: int, height: float) -> Vector2:
	return ArtScale.grounded(ArtScale.source(texture(kind, tier)), height).size
