class_name ColonyCore
extends Node2D

var health_component: HealthComponent = HealthComponent.new()
var health: int:
	get: return health_component.current
	set(value):
		health_component.reset(value)
		queue_redraw()

func _ready() -> void:
	health_component.maximum = GameRules.CORE_HEALTH
	health_component.reset()
	add_child(health_component)
	health_component.damaged.connect(_on_health_changed)
	health_component.healed.connect(_on_health_changed)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func _on_health_changed(_amount: int, _remaining: int) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-30, -65, 60, 65), Color("304356"))
	draw_rect(Rect2(-14, -52, 28, 32), Color("e89e54"))
	draw_rect(Rect2(-30, -74, 60.0 * health / GameRules.CORE_HEALTH, 4), Color("47dacb"))
