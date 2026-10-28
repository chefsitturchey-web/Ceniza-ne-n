class_name ArtScale
extends RefCounted
## Píxeles de mundo: un humano mide 35–38; las bases visibles apoyan en y=0.
const PERSON_HEIGHT: float = 36
const METADATA: Script = preload("res://data/art_bounds.gd")
static var bounds: Dictionary = METADATA.REGIONS

static func source(texture: Texture2D, index: int = 0) -> Rect2:
	var regions: Array = bounds.get(texture.resource_path, [])
	if index >= regions.size(): return Rect2(Vector2.ZERO, texture.get_size())
	var value: Array = regions[index]
	return Rect2(value[0], value[1], value[2], value[3])

static func grounded(region: Rect2, height: float, origin: Vector2 = Vector2.ZERO) -> Rect2:
	var width: float = region.size.x * height / region.size.y
	return Rect2(origin + Vector2(-width * 0.5, -height), Vector2(width, height))
