class_name CombatSpriteLibrary
extends RefCounted
## Full frames exported by LibreSprite; no body slicing or image manipulation at runtime.
static var layout: Dictionary = {}
static var cache: Dictionary = {}

static func data() -> Dictionary:
	if layout.is_empty():
		layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/combat/native/layout.json"))
		var painted_path: String = "res://assets/combat/illustrated/layout.json"
		if FileAccess.file_exists(painted_path):
			var painted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(painted_path))
			layout.actors.merge(painted.actors, true)
			layout.animations.merge(painted.animations, true)
	return layout

static func scale_for(id: String) -> float:
	return float(data().actors[id].get("render_scale", 1.0))

static func sheet_path(id: String) -> String:
	return data().actors[id].get("texture", "res://assets/combat/native/%s.png" % id)

static func source_path(id: String) -> String:
	return data().actors[id].get("source", "res://assets/combat/native/sources/%s.ase" % id)

static func offset_for(id: String) -> Vector2:
	var actor: Dictionary = data().actors[id]
	return Vector2.ONE * float(actor.cell) / 2 - Vector2(actor.anchor[0], actor.anchor[1])

static func frames(id: String) -> SpriteFrames:
	if cache.has(id): return cache[id]
	var info: Dictionary = data()
	var size: int = info.actors[id].cell
	var sheet: Texture2D = load(sheet_path(id))
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	for key: String in info.animations:
		var clip: Dictionary = info.animations[key]
		result.add_animation(key)
		result.set_animation_loop(key, clip.loop)
		result.set_animation_speed(key, clip.fps)
		for position: int in clip.frames.size():
			var index: int = clip.frames[position]
			var texture: AtlasTexture = AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(Vector2(index % 8, index / 8) * size, Vector2.ONE * size)
			texture.filter_clip = true
			result.add_frame(key, texture, float(clip.timing[position]) if clip.has("timing") else 1.0)
	cache[id] = result
	return result

static func direction(facing: Vector2) -> String:
	if absf(facing.x) > absf(facing.y): return "east" if facing.x > 0 else "west"
	return "south" if facing.y >= 0 else "north"
