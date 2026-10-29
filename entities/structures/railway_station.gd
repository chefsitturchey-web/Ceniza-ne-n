class_name RailwayStation
extends Node2D

signal arrived
const STATION: Texture2D = preload("res://assets/expedition/station.png")
const TRAIN: Texture2D = preload("res://assets/expedition/train.png")
const WHEEL: Texture2D = preload("res://assets/expedition/wheel.png")
var unlocked: bool = false
var train_arrived: bool = false
var train_x: float = 560.0
var wheel_angle: float = 0.0
var elapsed: float = 0.0
var dust_time: float = 0.0
var effects: DebrisEmitter = DebrisEmitter.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(effects)

func restore(available: bool, parked: bool) -> void:
	unlocked = available
	train_arrived = parked
	train_x = 0.0 if parked else 560.0
	queue_redraw()

func _process(delta: float) -> void:
	if not unlocked or train_arrived:
		return
	elapsed += delta
	var previous: float = train_x
	train_x = move_toward(train_x, 0, clampf(train_x * 1.4, 12, 180) * delta)
	wheel_angle += (train_x - previous) / 7.0
	dust_time -= delta
	if dust_time <= 0:
		dust_time = 0.15
		effects.emit_dust(global_position + Vector2(train_x, 0), 3)
		effects.emit_pixels(global_position + Vector2(train_x - 55, -40), 2, Color("b3bdc7"), true)
	if train_x == 0:
		train_arrived = true
		arrived.emit()
	queue_redraw()

func _draw() -> void:
	var source: Rect2 = ArtScale.source(GameArt.CIVIC, 4)
	var frame: Rect2 = ArtScale.grounded(source, 56)
	ArtScale.footing(self, frame)
	draw_texture_rect_region(GameArt.CIVIC, frame, source)
	if not unlocked:
		return
	for index: int in range(5):
		draw_set_transform(Vector2(roundf(train_x) - 57 + index * 28, -7), wheel_angle)
		draw_texture(WHEEL, Vector2(-7, -7))
	var bob: float = roundf(sin(elapsed * 14)) if not train_arrived else 0.0
	draw_set_transform(Vector2(roundf(train_x), bob))
	draw_texture(TRAIN, Vector2(-79, -49))
	draw_set_transform(Vector2.ZERO)
