class_name UnitSpriteLibrary
extends RefCounted
## Atlas exportados por LibreSprite. Un mismo recurso de fotogramas por profesión.
const ROLES: Array[String] = ["ranger", "guardian", "technician", "medic", "builder", "collector", "civilian", "artillero", "saboteador"]
const CELL: Vector2 = Vector2(64, 64)
const OFFSET: Vector2 = Vector2(0, -24)
static var cache: Dictionary = {}
static var layout: Dictionary = {}

static func frames(role: String) -> SpriteFrames:
	if cache.has(role): return cache[role] as SpriteFrames
	if layout.is_empty():
		layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/units/animated/layout.json"))
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	var sheet: Texture2D = load("res://assets/units/animated/%s.png" % role)
	for key: String in layout.animations:
		var animation: Dictionary = layout.animations[key]
		result.add_animation(key)
		result.set_animation_speed(key, animation.fps)
		result.set_animation_loop(key, animation.loop)
		for index: int in animation.frames:
			var texture: AtlasTexture = AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(Vector2(index % 8, index / 8) * CELL, CELL)
			texture.filter_clip = true
			result.add_frame(key, texture)
	cache[role] = result
	return result
