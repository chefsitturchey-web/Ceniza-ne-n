class_name DirectionalStride
extends Node2D
## Articulación en ejecución de las vistas norte/sur existentes, sin reemplazar PNG.
var source: Texture2D
var phase: float = 0.0
var walking: bool = false
var north: bool = false
var attack_amount: float = 0.0
var left_step: float = 0.0
var right_step: float = 0.0
var torso_bob: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func pose(texture: Texture2D, time: float, moving: bool, looking_north: bool, attack: float) -> void:
	source = texture
	phase = time * 14.0
	walking = moving
	north = looking_north
	left_step = roundf(sin(phase) * 2.0) if walking else 0.0
	right_step = -left_step
	torso_bob = -roundf(absf(sin(phase)) * 0.75) if walking else roundf(sin(time * 2) * 0.65)
	attack_amount = roundf(sin(clampf(attack, 0, 1) * PI) * 4.0)
	queue_redraw()

func _piece(region: Rect2, offset: Vector2) -> void:
	draw_texture_rect_region(source, Rect2(Vector2(-24, -24) + region.position + offset, region.size), region)

func _draw() -> void:
	if source == null:
		return
	# Pies y brazos avanzan alternadamente; pelvis y cabeza permanecen unidas.
	_piece(Rect2(0, 30, 24, 18), Vector2(0, left_step))
	_piece(Rect2(24, 30, 24, 18), Vector2(0, right_step))
	_piece(Rect2(19, 28, 11, 6), Vector2(0, torso_bob))
	_piece(Rect2(20, 18, 8, 12), Vector2(0, torso_bob))
	_piece(Rect2(0, 18, 20, 12), Vector2(0, roundf(right_step * 0.5)))
	_piece(Rect2(28, 18, 20, 12), Vector2(0, roundf(left_step * 0.5) + attack_amount * (-1 if north else 1)))
	_piece(Rect2(0, 0, 48, 18), Vector2(0, torso_bob))
