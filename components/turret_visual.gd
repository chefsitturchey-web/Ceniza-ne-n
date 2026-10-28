class_name TurretVisual
extends Node2D
## El PNG original se dibuja en dos piezas: pedestal fijo y cabezal articulado.
const HEAD_HEIGHT: float = 20.0
const PIVOT: Vector2 = Vector2(13, 17)
const BARREL: Vector2 = Vector2(23, -8)
const TURN_SPEED: float = 4.5
var site: Node2D
var facing: float = 1.0
var aim_angle: float = 0.0
var desired_angle: float = 0.0
var tracking: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -1
	facing = -1.0 if site.position.x < 0 else 1.0

func track(world_target: Vector2) -> void:
	var local: Vector2 = site.to_local(world_target)
	if absf(local.x) > 8:
		facing = signf(local.x)
	var direction: Vector2 = local - pivot_position()
	direction.x *= facing
	desired_angle = clampf(direction.angle() - BARREL.angle(), -0.65, 0.95)
	tracking = true

func clear_target() -> void:
	tracking = false

func pivot_position() -> Vector2:
	var extent: Vector2 = site.data.texture.get_size()
	return Vector2((PIVOT.x - extent.x / 2.0) * facing, -extent.y + PIVOT.y)

func recoil_offset() -> Vector2:
	return Vector2(-2.0 * clampf(site.recoil / 0.09, 0, 1), 0)

func muzzle_position() -> Vector2:
	var offset: Vector2 = (BARREL + recoil_offset()).rotated(aim_angle)
	offset.x *= facing
	return site.to_global(pivot_position() + offset)

func fire() -> void:
	# El cabezal debe estar alineado en el instante autoritativo del disparo.
	if tracking:
		aim_angle = desired_angle
	queue_redraw()

func _process(delta: float) -> void:
	if site.hp <= 0:
		return
	elapsed += delta
	if not tracking:
		desired_angle = sin(elapsed * 0.8 + site.position.x * 0.01) * 0.12
	aim_angle = rotate_toward(aim_angle, desired_angle, TURN_SPEED * delta)
	queue_redraw()

func _draw() -> void:
	if site.hp <= 0 or site.data.texture == null:
		return
	var texture: Texture2D = site.data.texture
	var size: Vector2 = texture.get_size()
	var tint: Color = Color(0.8, 1.3, 1.25) if site.boosted else Color.WHITE
	# El pedestal conserva su orientación de construcción y no recibe retroceso.
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if site.position.x < 0 else 1, 1))
	draw_texture_rect_region(texture, Rect2(-size.x / 2, -size.y + HEAD_HEIGHT, size.x, size.y - HEAD_HEIGHT), Rect2(0, HEAD_HEIGHT, size.x, size.y - HEAD_HEIGHT), tint)
	draw_set_transform(Vector2.ZERO)
	var pivot: Vector2 = pivot_position()
	draw_circle(pivot, 3, Color("0b1322"))
	draw_circle(pivot, 2, Color("8299a8"))
	# Reflejar antes de rotar mantiene el mismo ángulo local en ambos frentes.
	var frame: Transform2D = Transform2D(0, Vector2(facing, 1), 0, pivot)
	frame = frame * Transform2D(aim_angle, Vector2.ZERO)
	frame.origin += frame.basis_xform(recoil_offset())
	draw_set_transform_matrix(frame)
	draw_texture_rect_region(texture, Rect2(-PIVOT, Vector2(size.x, HEAD_HEIGHT)), Rect2(0, 0, size.x, HEAD_HEIGHT), tint)
	draw_set_transform(Vector2.ZERO)
	var intensity: float = 0.8 if GamePreferences.current().reduced_flashes else 0.65 + sin(elapsed * 3) * 0.2
	draw_rect(Rect2(-3, -6, 5, 1), Color("47dacb", intensity))
	if site.boosted:
		draw_rect(Rect2(-3, -9, 5, 1), Color("ffce75", intensity))
