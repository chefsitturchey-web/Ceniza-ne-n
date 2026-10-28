class_name FortressArt
extends RefCounted
const CORE_HEIGHTS: Array[float] = [72, 88, 106]
const WALL_HEIGHTS: Array[float] = [40, 54, 68]
const TURRET_HEIGHTS: Array[float] = [30, 40, 50]
const TEXTURES: Dictionary = {
	"core": [preload("res://assets/structures/fortress/core_1.png"), preload("res://assets/structures/fortress/core_2.png"), preload("res://assets/structures/fortress/core_3.png")],
	"wall": [preload("res://assets/structures/fortress/wall_1.png"), preload("res://assets/structures/fortress/wall_2.png"), preload("res://assets/structures/fortress/wall_3.png")],
	"turret_base": [preload("res://assets/structures/fortress/turret_base_1.png"), preload("res://assets/structures/fortress/turret_base_2.png"), preload("res://assets/structures/fortress/turret_base_3.png")],
	"turret_head": [preload("res://assets/structures/fortress/turret_head_1.png"), preload("res://assets/structures/fortress/turret_head_2.png"), preload("res://assets/structures/fortress/turret_head_3.png")]
}

static func texture(kind: String, tier: int) -> Texture2D:
	return TEXTURES[kind][clampi(tier, 1, 3) - 1] as Texture2D

static func size_of(kind: String, tier: int, height: float) -> Vector2:
	return ArtScale.grounded(ArtScale.source(texture(kind, tier)), height).size
