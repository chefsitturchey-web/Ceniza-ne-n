class_name DepotArt
extends RefCounted
const PARTS: Texture2D = preload("res://assets/expedition/boss/collector_parts_v2.png")
const PROPS: Texture2D = preload("res://assets/expedition/arena/depot_props_v2.png")
static var parts: Dictionary = {}
static var props: Dictionary = {}
static var shutter: AtlasTexture

static func reactor_shutter() -> Texture2D:
	if shutter == null:
		shutter = AtlasTexture.new()
		shutter.atlas = PARTS
		var body: Rect2 = ArtScale.source(PARTS, 0)
		shutter.region = Rect2(body.position + body.size * Vector2(0.4, 0.015), body.size * Vector2(0.24, 0.23))
		shutter.filter_clip = true
	return shutter

static func part(index: int) -> Texture2D:
	if not parts.has(index): parts[index] = ArtScale.atlas(PARTS, index)
	return parts[index] as Texture2D

static func prop(index: int) -> Texture2D:
	if not props.has(index): props[index] = ArtScale.atlas(PROPS, index)
	return props[index] as Texture2D
