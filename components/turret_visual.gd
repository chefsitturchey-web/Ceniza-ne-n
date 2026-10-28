class_name TurretVisual
extends Node2D
## Pedestal y cabezal propios de cada nivel, con pivote, seguimiento y retroceso.
const HEAD_HEIGHT: float = 20.0
const PIVOT: Vector2 = Vector2(13, 17)
const BARREL: Vector2 = Vector2(31, 0)
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
	return Vector2(0, -FortressArt.TURRET_HEIGHTS[site.tier - 1] + 5)

func recoil_offset() -> Vector2:
	return Vector2(-2.0 * clampf(site.recoil / 0.09, 0, 1), 0)

func muzzle_position() -> Vector2:
	var offset: Vector2 = (BARREL + Vector2((site.tier - 1) * 3, 0) + recoil_offset()).rotated(aim_angle)
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
	if site.hp <= 0: return
	var base: Texture2D = FortressArt.texture("turret_base", site.tier)
	var head: Texture2D = FortressArt.texture("turret_head", site.tier)
	var source: Rect2 = ArtScale.source(base)
	var tint: Color = Color(0.8, 1.25, 1.2) if site.boosted else Color.WHITE
	draw_texture_rect_region(base, ArtScale.grounded(source, FortressArt.TURRET_HEIGHTS[site.tier - 1]), source, tint)
	var pivot: Vector2 = pivot_position()
	var frame: Transform2D = Transform2D(0, Vector2(facing, 1), 0, pivot) * Transform2D(aim_angle, Vector2.ZERO)
	frame.origin += frame.basis_xform(recoil_offset())
	draw_set_transform_matrix(frame)
	var head_source: Rect2 = ArtScale.source(head)
	var width: float = 39 + site.tier * 3
	var height: float = width * head_source.size.y / head_source.size.x
	draw_texture_rect_region(head, Rect2(-11, -height * 0.5, width, height), head_source, tint)
	draw_set_transform(Vector2.ZERO)
