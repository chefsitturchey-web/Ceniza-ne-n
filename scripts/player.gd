extends CharacterBody2D
## El origen del personaje está en sus pies. No hay salto en este prototipo.

@export var speed: float = 150.0
@export var acceleration: float = 1200.0
@export var gravity: float = 980.0
var facing: float = 1.0
@export var attack_damage: int = 25
@export var attack_range: float = 42.0
@export var attack_cooldown: float = 0.4
var cooldown_remaining: float = 0.0
var slash_remaining: float = 0.0
var attack_facing: float = 1.0

func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	slash_remaining = maxf(0.0, slash_remaining - delta)
	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if absf(direction) > 0.1:
		facing = signf(direction)
	move_and_slide()
	if Input.is_action_just_pressed("attack"):
		attack()
	queue_redraw()

func attack() -> void:
	if cooldown_remaining > 0.0:
		return
	cooldown_remaining = attack_cooldown
	slash_remaining = 0.12
	attack_facing = facing
	var hit_rect: Rect2 = get_attack_rect()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if hit_rect.intersects(enemy.get_hurt_rect()):
			enemy.take_damage(attack_damage)

func get_attack_rect() -> Rect2:
	var left: float = 8.0 if attack_facing > 0.0 else -8.0 - attack_range
	return Rect2(global_position + Vector2(left, -30), Vector2(attack_range, 30))

func _draw() -> void:
	if slash_remaining > 0.0:
		var hit_rect: Rect2 = get_attack_rect()
		hit_rect.position -= global_position
		draw_rect(hit_rect, Color(1.0, 0.8, 0.45, 0.65))
	draw_rect(Rect2(-8, -30, 16, 30), Color("47dacb"))
	draw_rect(Rect2(-6, -27, 12, 8), Color("17283b"))
	draw_line(Vector2(0, -23), Vector2(facing * 7, -23), Color("ffce75"), 3.0)
