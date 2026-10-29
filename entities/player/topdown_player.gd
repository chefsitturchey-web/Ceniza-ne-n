class_name TopdownPlayer
extends CharacterBody2D

signal died
signal damaged
signal dodged
signal stepped(origin: Vector2)
signal slash(origin: Vector2, direction: Vector2, amount: int, reach: float)

var health: int = Player.MAX_HEALTH
var debug_invincible: bool = false
var stamina: float = Player.MAX_STAMINA
var speed: float = 220.0
var terrain_speed_factor: float = 1.0
var attack_damage: int = 50
var attack_range: float = 42.0
var attack_cooldown: float = 0.4
var neural_regen: float = 0.0
var drone_rank: int = 0
var module_state: Dictionary = {}
var facing: Vector2 = Vector2.DOWN
var dodge_direction: Vector2 = Vector2.DOWN
var invulnerable: float = 0.0
var dodge_remaining: float = 0.0
var cooldown: float = 0.0
var slash_remaining: float = 0.0
var attack_anim_remaining: float = 0.0
var step_timer: float = 0.0
var slash_direction: Vector2 = Vector2.DOWN
var elapsed: float = 0.0
var dust_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var effects: DebrisEmitter = DebrisEmitter.new()
var combat_visual: CombatFlipbook
var attack_pending: bool = false

func copy_from(source: Player) -> void:
	health = source.health
	stamina = source.stamina
	speed = source.speed
	attack_damage = source.attack_damage + source.neural_damage
	neural_regen = source.neural_regen
	if source.modules != null:
		module_state = source.modules.snapshot()
		drone_rank = source.modules.defenses.drone_rank
	attack_range = source.attack_range
	attack_cooldown = source.attack_cooldown

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8
	collider.shape = shape
	add_child(collider)
	effects.planar = true
	add_child(effects)
	combat_visual = CombatFlipbook.new()
	combat_visual.actor = self
	combat_visual.actor_id = "portador_cenital"
	add_child(combat_visual)
	update_visual()

func _physics_process(delta: float) -> void:
	if Engine.get_process_frames() <= GamePreferences.current().input_block_frame:
		return
	if health <= 0:
		return
	elapsed += delta
	invulnerable = maxf(0, invulnerable - delta)
	cooldown = maxf(0, cooldown - delta)
	slash_remaining = maxf(0, slash_remaining - delta)
	attack_anim_remaining = maxf(0, attack_anim_remaining - delta)
	stamina = minf(Player.MAX_STAMINA, stamina + (Player.STAMINA_REGEN + neural_regen) * delta)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "arena_up", "arena_down")
	if dodge_remaining <= 0 and direction.length() > Player.MOVE_THRESHOLD:
		facing = direction.normalized()
	if Input.is_action_just_pressed("dodge"):
		dodge()
	if attack_pending and attack_anim_remaining <= Player.ATTACK_ANIM_DURATION * 0.75:
		attack_pending = false
		slash_remaining = Player.SLASH_DURATION
		slash.emit(global_position, slash_direction, attack_damage, attack_range)
	if dodge_remaining > 0:
		velocity = dodge_direction * Player.DODGE_SPEED
		dodge_remaining = maxf(0, dodge_remaining - delta)
	else:
		velocity = direction * speed * terrain_speed_factor * (0.65 if attack_anim_remaining > 0 else 1.0) + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 900 * delta)
	move_and_slide()
	step_timer = maxf(0, step_timer - delta)
	if velocity.length() > 20 and dodge_remaining <= 0 and step_timer == 0:
		stepped.emit(global_position)
		step_timer = 0.3
	if Input.is_action_pressed("attack"):
		attack()
	dust_timer -= delta
	if velocity.length() > 10 and dust_timer <= 0:
		effects.emit_dust(global_position)
		dust_timer = 0.12
	update_visual()

func dodge() -> void:
	if health <= 0 or stamina < Player.DODGE_COST or dodge_remaining > 0:
		return
	stamina -= Player.DODGE_COST
	attack_pending = false
	attack_anim_remaining = 0
	dodge_direction = facing
	dodge_remaining = Player.DODGE_DURATION
	invulnerable = maxf(invulnerable, Player.DODGE_DURATION)
	dodged.emit()

func attack() -> void:
	if health <= 0 or cooldown > 0 or dodge_remaining > 0:
		return
	cooldown = attack_cooldown
	slash_remaining = 0
	attack_anim_remaining = Player.ATTACK_ANIM_DURATION
	attack_pending = true
	slash_direction = facing
	queue_redraw()

func take_damage(amount: int, impulse: Vector2 = Vector2.ZERO) -> void:
	if debug_invincible or health <= 0 or invulnerable > 0:
		return
	health = maxi(0, health - amount)
	invulnerable = Player.HIT_INVULNERABILITY
	knockback = impulse
	attack_pending = false
	attack_anim_remaining = 0
	if combat_visual != null: combat_visual.pulse_hurt()
	damaged.emit()
	if health == 0:
		velocity = Vector2.ZERO
		update_visual()
		died.emit()

func update_visual() -> void:
	if combat_visual != null: combat_visual.pose_player()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.75))
	draw_circle(Vector2.ZERO, 11, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
