class_name DebrisEmitter
extends Node2D
## Aleatoriedad visual independiente de las reglas y presupuesto compartido.
const LIMIT: int = 120
static var live_count: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

class Pixel extends Node2D:
	var velocity: Vector2
	var precise_position: Vector2
	var gravity: float = 280.0
	var lifetime: float = 1.5
	var age: float = 0.0
	var spin: float = 0.0
	var tint: Color = Color.WHITE
	var size: Vector2 = Vector2.ONE
	var texture: Texture2D
	var region: Rect2
	var mirrored: bool = false

	func _enter_tree() -> void:
		DebrisEmitter.live_count += 1

	func _exit_tree() -> void:
		DebrisEmitter.live_count -= 1

	func _process(delta: float) -> void:
		age += delta
		if age >= lifetime:
			queue_free()
			return
		velocity.y += gravity * delta
		precise_position += velocity * delta
		if gravity > 0.0 and precise_position.y >= GameRules.FLOOR_Y - size.y / 2.0:
			precise_position.y = GameRules.FLOOR_Y - size.y / 2.0
			velocity = Vector2(velocity.x * 0.7, -absf(velocity.y) * 0.32)
		global_position = precise_position.round()
		rotation += spin * delta
		modulate.a = clampf((lifetime - age) / 0.45, 0.0, 1.0)

	func _draw() -> void:
		if texture != null:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if mirrored else 1.0, 1.0))
			draw_texture_rect_region(texture, Rect2((-size / 2.0).round(), size), region)
		else:
			draw_rect(Rect2((-size / 2.0).round(), size), tint)

func _ready() -> void:
	rng.seed = hash(str(global_position)) + 719

func emit_pixels(origin: Vector2, count: int, color: Color, smoke: bool = false) -> void:
	for index: int in range(mini(count, LIMIT - live_count)):
		var piece: Pixel = _create(origin)
		piece.tint = color
		piece.size = Vector2.ONE * rng.randi_range(1, 3)
		if smoke:
			piece.gravity = -5.0
			piece.velocity = Vector2(rng.randf_range(-7, 7), rng.randf_range(-18, -10))
			piece.lifetime = 1.2
		else:
			piece.lifetime = 0.7
		piece.queue_redraw()

func emit_fragments(origin: Vector2, texture: Texture2D, count: int, mirrored: bool = false, shatter: bool = false) -> void:
	if texture == null:
		for index: int in range(mini(count, LIMIT - live_count)):
			var piece: Pixel = _create(origin + Vector2(0, -20))
			piece.tint = Color("8299a8")
			piece.size = Vector2(rng.randi_range(1, 3), 2)
			piece.spin = rng.randf_range(-4, 4)
		return
	var extent: Vector2 = texture.get_size()
	for index: int in range(mini(count, LIMIT - live_count)):
		var region_size: Vector2 = (extent / Vector2(4, 2)).floor() if shatter else Vector2(3, 3)
		var source: Vector2 = Vector2(index % 4, floorf(index * 0.25)) * region_size if shatter else Vector2(rng.randf_range(0, extent.x - 3), rng.randf_range(0, extent.y - 3)).floor()
		var offset: Vector2 = source + region_size / 2.0 - Vector2(extent.x / 2.0, extent.y)
		if mirrored:
			offset.x = -offset.x
		var piece: Pixel = _create(origin + offset)
		piece.texture = texture
		piece.region = Rect2(source, region_size)
		piece.size = region_size
		piece.mirrored = mirrored
		piece.spin = rng.randf_range(-3, 3)
		piece.queue_redraw()

func emit_sweat(origin: Vector2) -> void:
	if live_count >= LIMIT:
		return
	var piece: Pixel = _create(origin)
	piece.tint = Color("a5f8ff")
	piece.velocity = Vector2(0, 8)
	piece.lifetime = 0.5

func _create(origin: Vector2) -> Pixel:
	var piece: Pixel = Pixel.new()
	piece.top_level = true
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.velocity = Vector2(rng.randf_range(-55, 55), rng.randf_range(-100, -45))
	# Hermano del actor: persiste tras su muerte y se limpia al cerrar el mundo.
	get_parent().get_parent().add_child(piece)
	piece.precise_position = origin
	piece.global_position = origin.round()
	return piece
