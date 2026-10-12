class_name ConstructionSite
extends Node2D

signal destroyed
@export var data: StructureData
var health_component: HealthComponent = HealthComponent.new()
var boosted: bool = false
var ordered: bool = false
var progress: float = 0.0
var shot: float = 0.0
var x: float:
	get: return position.x
var kind: StringName:
	get: return data.id
var cost: int:
	get: return data.cost
var max_hp: int:
	get: return data.health
var hp: int:
	get: return health_component.current
	set(value): health_component.reset(value)

func _ready() -> void:
	add_child(health_component)
	health_component.maximum = data.health
	health_component.reset(0)
	health_component.died.connect(_on_destroyed)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func complete_work() -> void:
	health_component.reset()
	ordered = false
	progress = 0.0

func _on_destroyed() -> void:
	ordered = false
	progress = 0.0
	destroyed.emit()

func update_overload(left_active: bool, right_active: bool) -> void:
	boosted = left_active if x < 0.0 else right_active
	queue_redraw()

func _draw() -> void:
	var color: Color = Color("47dacb") if boosted else Color("8299a8")
	if hp > 0:
		if data.blocks_enemies:
			draw_rect(Rect2(-10, -45, 20, 45), color)
			draw_rect(Rect2(-5, -40, 10, 30), Color("304356"))
		else:
			draw_rect(Rect2(-5, -35, 10, 35), color)
			draw_rect(Rect2(-14, -45, 28, 12), color)
		draw_rect(Rect2(-14, -54, 28.0 * hp / max_hp, 3), Color("47dacb"))
	else:
		draw_rect(Rect2(-12, -40, 24, 40), Color("b075ae"), false, 1.0)
	if ordered:
		draw_rect(Rect2(-14, -60, 28.0 * progress / GameRules.BUILD_TIME, 3), Color("ffce75"))
