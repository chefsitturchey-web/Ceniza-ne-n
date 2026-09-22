extends CharacterBody2D
## Combate manual y esquiva. Los ajustes del Inspector se conservan.
@export var speed: float = 150.0
@export var acceleration: float = 1200.0
@export var gravity: float = 980.0
@export var attack_damage: int = 25
@export var attack_range: float = 42.0
@export var attack_cooldown: float = 0.4
var facing: float = 1.0
var attack_facing: float = 1.0
var cooldown_remaining: float = 0.0
var slash_remaining: float = 0.0
var health: int = 100
var stamina: float = 100.0
var invulnerable: float = 0.0
var dodge_remaining: float = 0.0
var dodge_direction: float = 1.0
var respawn_remaining: float = 0.0
var enabled: bool = true

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	slash_remaining = maxf(0.0, slash_remaining - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	stamina = minf(100.0, stamina + 22.0 * delta)
	if respawn_remaining > 0.0:
		respawn_remaining = maxf(0.0, respawn_remaining - delta)
		if respawn_remaining == 0.0:
			health = 100
			position = Vector2(0, 260)
			invulnerable = 2.0
		queue_redraw()
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	if dodge_remaining <= 0.0 and absf(direction) > 0.1:
		facing = signf(direction)
	if Input.is_action_just_pressed("dodge"):
		dodge()
	if dodge_remaining > 0.0:
		dodge_remaining = maxf(0.0, dodge_remaining - delta)
		velocity.x = dodge_direction * 420.0
	else:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	if Input.is_action_pressed("attack"):
		attack()
	queue_redraw()

func dodge() -> void:
	if not enabled or health <= 0 or stamina < 30.0 or dodge_remaining > 0.0:
		return
	stamina -= 30.0
	dodge_direction = facing
	dodge_remaining = 0.22
	invulnerable = maxf(invulnerable, 0.22)

func take_damage(amount: int) -> void:
	if not enabled or health <= 0 or invulnerable > 0.0:
		return
	health = maxi(0, health - amount)
	invulnerable = 0.6
	if health == 0:
		respawn_remaining = 4.0
		velocity = Vector2.ZERO
		dodge_remaining = 0.0
	queue_redraw()

func attack() -> void:
	if not enabled or health <= 0 or cooldown_remaining > 0.0 or dodge_remaining > 0.0:
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
	if health <= 0:
		draw_circle(Vector2(0, -8), 7, Color("47dacb"))
		return
	if slash_remaining > 0.0:
		var hit_rect: Rect2 = get_attack_rect()
		hit_rect.position -= global_position
		draw_rect(hit_rect, Color(1.0, 0.8, 0.45, 0.65))
	var color: Color = Color.WHITE if invulnerable > 0.0 else Color("47dacb")
	draw_rect(Rect2(-8, -30, 16, 26), color)
	draw_rect(Rect2(-7, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(2, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(-6, -27, 12, 8), Color("17283b"))
	draw_line(Vector2(0, -23), Vector2(facing * 7, -23), Color("ffce75"), 3.0)
