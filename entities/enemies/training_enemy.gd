class_name TrainingEnemy
extends Node2D
## Blanco inmóvil: muestra daño y reaparece para repetir la práctica.

@export var max_health: int = 100
var health_component: HealthComponent = HealthComponent.new()
var hurtbox: HurtboxComponent = HurtboxComponent.new()
var health: int:
	get: return health_component.current
	set(value): health_component.reset(value)
var flash_remaining: float = 0.0
var respawn_remaining: float = 0.0
var health_label: Label

func _ready() -> void:
	add_child(health_component)
	health_component.maximum = max_health
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	hurtbox.bounds = Rect2(-12, -34, 24, 34)
	hurtbox.hit.connect(take_damage)
	add_child(hurtbox)
	add_to_group(GameRules.ENEMIES)
	health = max_health
	health_label = Label.new()
	health_label.position = Vector2(-55, -66)
	health_label.size = Vector2(110, 20)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 12)
	add_child(health_label)
	update_label()

func get_hurt_rect() -> Rect2:
	return hurtbox.world_rect()

func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health_component.take_damage(amount)
	flash_remaining = 0.12
	if health == 0:
		respawn_remaining = 3.0
	update_label()
	queue_redraw()

func _process(delta: float) -> void:
	flash_remaining = maxf(0.0, flash_remaining - delta)
	if respawn_remaining > 0.0:
		respawn_remaining = maxf(0.0, respawn_remaining - delta)
		if respawn_remaining == 0.0:
			health = max_health
			update_label()
	queue_redraw()

func update_label() -> void:
	health_label.text = "%d / %d" % [health, max_health] if health > 0 else "Reaparece en 3 s"

func _draw() -> void:
	if health <= 0:
		draw_rect(Rect2(-12, -5, 24, 5), Color("70475b"))
		return
	var color: Color = Color.WHITE if flash_remaining > 0.0 else Color("dd6482")
	draw_rect(Rect2(-12, -34, 24, 34), color)
	draw_rect(Rect2(-8, -28, 16, 7), Color("271d33"))
	draw_rect(Rect2(-20, -43, 40, 4), Color("352a3e"))
	draw_rect(Rect2(-20, -43, 40.0 * float(health) / max_health, 4), Color("ec8096"))
