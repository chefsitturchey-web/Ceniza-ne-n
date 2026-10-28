class_name ColonyCore
extends Node2D

## El estado del mundo se comunica con efectos, nunca con barras.
const WORLD_BARS_ENABLED: bool = false

const TEXTURE: Texture2D = preload("res://assets/structures/core_01.png")

var effects: StructureEffects = StructureEffects.new()

var health_component: HealthComponent = HealthComponent.new()
var health: int:
	get: return health_component.current
	set(value):
		health_component.reset(value)
		queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	health_component.maximum = GameRules.CORE_HEALTH
	health_component.reset()
	add_child(health_component)
	health_component.damaged.connect(_on_health_changed)
	health_component.healed.connect(_on_health_changed)
	add_child(effects)
	effects.setup(health_component, TEXTURE)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func _on_health_changed(_amount: int, _remaining: int) -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var size: Vector2 = TEXTURE.get_size()
	var offset: Vector2 = Vector2(2 if int(effects.elapsed * 40) % 2 == 0 else -1, 0) if effects.shake > 0 and not GamePreferences.current().reduced_flashes else Vector2.ZERO
	effects.position = offset
	draw_set_transform(offset)
	draw_texture(TEXTURE, Vector2(-size.x / 2.0, -size.y))
	if health > 0:
		var intensity: float = 0.75 if GamePreferences.current().reduced_flashes else 0.55 + sin(effects.elapsed * 2) * 0.2
		var color: Color = Color("47dacb") if health > GameRules.CORE_HEALTH * 0.3 else Color("ffce75")
		for index: int in range(3):
			draw_rect(Rect2(-16 + index * 5, -8, 3, 1), Color(color, intensity))
	draw_set_transform(Vector2.ZERO)
