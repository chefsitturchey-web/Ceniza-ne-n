class_name Player
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK, DODGE, DEAD }
const MAX_HEALTH: int = 100
const MAX_STAMINA: float = 100.0
const STAMINA_REGEN: float = 22.0
const DODGE_COST: float = 30.0
const DODGE_SPEED: float = 420.0
const DODGE_DURATION: float = 0.22
const HIT_INVULNERABILITY: float = 0.6
const RESPAWN_INVULNERABILITY: float = 2.0
const RESPAWN_DURATION: float = 4.0
const SLASH_DURATION: float = 0.12
const MOVE_THRESHOLD: float = 0.1
const ATTACK_OFFSET: float = 8.0
const ATTACK_HEIGHT: float = 30.0
signal state_changed(state: State)
var state: State = State.IDLE
var health_component: HealthComponent = HealthComponent.new()
var hitbox: HitboxComponent = HitboxComponent.new()
var visual: PlayerVisual = PlayerVisual.new()

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
var health: int:
	get: return health_component.current
	set(value): health_component.reset(value)
var stamina: float = MAX_STAMINA
var invulnerable: float = 0.0
var dodge_remaining: float = 0.0
var dodge_direction: float = 1.0
var respawn_remaining: float = 0.0
var enabled: bool = true

func _ready() -> void:
	health_component.maximum = MAX_HEALTH
	add_child(health_component)
	add_child(hitbox)
	visual.actor = self
	add_child(visual)
	visual.bind(get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)

func set_state(value: State) -> void:
	if state != value:
		state = value
		state_changed.emit(state)

func refresh_state() -> void:
	if health <= 0:
		set_state(State.DEAD)
	elif dodge_remaining > 0.0:
		set_state(State.DODGE)
	elif slash_remaining > 0.0:
		set_state(State.ATTACK)
	else:
		set_state(State.MOVE if absf(velocity.x) > 0.0 else State.IDLE)
	visual.face(facing < 0.0)
	visual.play_visual([&"reposo", &"correr", &"ataque", &"esquiva", &"muerte"][state])
	visual.queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	slash_remaining = maxf(0.0, slash_remaining - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	stamina = minf(MAX_STAMINA, stamina + STAMINA_REGEN * delta)
	if respawn_remaining > 0.0:
		respawn_remaining = maxf(0.0, respawn_remaining - delta)
		if respawn_remaining == 0.0:
			health = MAX_HEALTH
			position = Vector2(0, GameRules.FLOOR_Y)
			invulnerable = RESPAWN_INVULNERABILITY
		refresh_state()
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	if dodge_remaining <= 0.0 and absf(direction) > MOVE_THRESHOLD:
		facing = signf(direction)
	if Input.is_action_just_pressed("dodge"):
		dodge()
	if dodge_remaining > 0.0:
		dodge_remaining = maxf(0.0, dodge_remaining - delta)
		velocity.x = dodge_direction * DODGE_SPEED
	else:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	if Input.is_action_pressed("attack"):
		attack()
	refresh_state()

func dodge() -> void:
	if not enabled or health <= 0 or stamina < DODGE_COST or dodge_remaining > 0.0:
		return
	stamina -= DODGE_COST
	dodge_direction = facing
	dodge_remaining = DODGE_DURATION
	invulnerable = maxf(invulnerable, DODGE_DURATION)
	refresh_state()

func take_damage(amount: int) -> void:
	if not enabled or health <= 0 or invulnerable > 0.0:
		return
	health_component.take_damage(amount)
	invulnerable = HIT_INVULNERABILITY
	if health == 0:
		respawn_remaining = RESPAWN_DURATION
		velocity = Vector2.ZERO
		dodge_remaining = 0.0
	refresh_state()

func attack() -> void:
	if not enabled or health <= 0 or cooldown_remaining > 0.0 or dodge_remaining > 0.0:
		return
	cooldown_remaining = attack_cooldown
	slash_remaining = SLASH_DURATION
	attack_facing = facing
	var hit_rect: Rect2 = get_attack_rect()
	hitbox.strike(hit_rect, attack_damage)
	refresh_state()

func get_attack_rect() -> Rect2:
	var left: float = ATTACK_OFFSET if attack_facing > 0.0 else -ATTACK_OFFSET - attack_range
	return Rect2(global_position + Vector2(left, -ATTACK_HEIGHT), Vector2(attack_range, ATTACK_HEIGHT))
