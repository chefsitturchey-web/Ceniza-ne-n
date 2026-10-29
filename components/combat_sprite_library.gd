class_name CombatSpriteLibrary
extends RefCounted
## Full frames exported by LibreSprite; no body slicing or image manipulation at runtime.
static var layout: Dictionary = {}
static var cache: Dictionary = {}

static func data() -> Dictionary:
	if layout.is_empty(): layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/combat/native/layout.json"))
	return layout

static func offset_for(id: String) -> Vector2:
	var actor: Dictionary = data().actors[id]
	return Vector2.ONE * float(actor.cell) / 2 - Vector2(actor.anchor[0], actor.anchor[1])

static func frames(id: String) -> SpriteFrames:
	if cache.has(id): return cache[id]
	var info: Dictionary = data()
	var size: int = info.actors[id].cell
	var sheet: Texture2D = load("res://assets/combat/native/%s.png" % id)
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	for key: String in info.animations:
		var clip: Dictionary = info.animations[key]
		result.add_animation(key)
		result.set_animation_loop(key, clip.loop)
		result.set_animation_speed(key, clip.fps)
		for index: int in clip.frames:
			var texture: AtlasTexture = AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(Vector2(index % 8, index / 8) * size, Vector2.ONE * size)
			texture.filter_clip = true
			result.add_frame(key, texture)
	cache[id] = result
	return result

static func direction(facing: Vector2) -> String:
	if absf(facing.x) > absf(facing.y): return "east" if facing.x > 0 else "west"
	return "south" if facing.y >= 0 else "north"
