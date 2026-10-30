class_name TopdownPlayer
extends CharacterBody2D

signal died
signal damaged
signal dodged
signal stepped(origin: Vector2)
signal slash(origin: Vector2, direction: Vector2, amount: int, reach: float)

const FRAMES: SpriteFrames = preload("res://entities/player/player_frames.tres")
const VIEWS: Array[Texture2D] = [preload("res://assets/player/topdown/idle_south.png"), preload("res://assets/player/topdown/idle_north.png"), preload("res://assets/player/topdown/idle_east.png"), preload("res://assets/player/topdown/idle_west.png")]
var health: int = Player.MAX_HEALTH
var stamina: float = Player.MAX_STAMINA
var speed: float = 220.0
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
var dodge_cooldown_remaining: float = 0.0
var cooldown: float = 0.0
var slash_remaining: float = 0.0
var attack_anim_remaining: float = 0.0
var step_timer: float = 0.0
var death_elapsed: float = 0.0
var slash_direction: Vector2 = Vector2.DOWN
var elapsed: float = 0.0
var dust_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var sprite: Sprite2D = Sprite2D.new()
var runner: AnimatedSprite2D = AnimatedSprite2D.new()
var effects: DebrisEmitter = DebrisEmitter.new()
var stride: DirectionalStride = DirectionalStride.new()
## Add correr_north / correr_south here when their frames are available.
@export var directional_frames: SpriteFrames

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
	add_child(sprite)
	add_child(runner)
	add_child(stride)
	stride.position.y = -16
	sprite.position.y = -16
	runner.position.y = -20
	runner.sprite_frames = FRAMES
	effects.planar = true
	add_child(effects)
	update_visual()

func _physics_process(delta: float) -> void:
	if Engine.get_process_frames() <= GamePreferences.current().input_block_frame:
		return
	if health <= 0:
		return
	elapsed += delta
	invulnerable = maxf(0, invulnerable - delta)
	dodge_cooldown_remaining = maxf(0, dodge_cooldown_remaining - delta)
	cooldown = maxf(0, cooldown - delta)
	slash_remaining = maxf(0, slash_remaining - delta)
	attack_anim_remaining = maxf(0, attack_anim_remaining - delta)
	stamina = minf(Player.MAX_STAMINA, stamina + (Player.STAMINA_REGEN + neural_regen) * delta)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "arena_up", "arena_down")
	if dodge_remaining <= 0 and direction.length() > Player.MOVE_THRESHOLD:
		facing = direction.normalized()
	if Input.is_action_just_pressed("dodge"):
		dodge()
	if dodge_remaining > 0:
		velocity = dodge_direction * Player.DODGE_SPEED
		dodge_remaining = maxf(0, dodge_remaining - delta)
	else:
		velocity = direction * speed + knockback
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
	if health <= 0 or stamina < Player.DODGE_COST or dodge_remaining > 0 or dodge_cooldown_remaining > 0:
		return
	stamina -= Player.DODGE_COST
	dodge_cooldown_remaining = Player.DODGE_COOLDOWN
	dodge_direction = facing
	dodge_remaining = Player.DODGE_DURATION
	invulnerable = maxf(invulnerable, Player.DODGE_DURATION)
	dodged.emit()

func attack() -> void:
	if health <= 0 or cooldown > 0 or dodge_remaining > 0:
		return
	cooldown = attack_cooldown
	slash_remaining = Player.SLASH_DURATION
	attack_anim_remaining = Player.ATTACK_ANIM_DURATION
	slash_direction = facing
	slash.emit(global_position, facing, attack_damage, attack_range)
	queue_redraw()

func take_damage(amount: int, impulse: Vector2 = Vector2.ZERO) -> void:
	if health <= 0 or invulnerable > 0:
		return
	health = maxi(0, health - amount)
	invulnerable = Player.HIT_INVULNERABILITY
	knockback = impulse
	damaged.emit()
	if health == 0:
		velocity = Vector2.ZERO
		update_visual()
		died.emit()

func _process(delta: float) -> void:
	if health > 0:
		return
	death_elapsed += delta
	runner.hide()
	stride.hide()
	sprite.show()
	sprite.rotation = minf(1, death_elapsed / 0.4) * PI * 0.45
	sprite.scale.y = 1.0 - minf(1, death_elapsed / 0.5) * 0.35
	modulate.a = clampf(1 - death_elapsed / 1.4, 0.15, 1)

func update_visual() -> void:
	var horizontal: bool = absf(facing.x) > absf(facing.y)
	var moving: bool = velocity.length() > 10
	var index: int = (2 if facing.x > 0 else 3) if horizontal else (0 if facing.y > 0 else 1)
	var animation: StringName = &"correr_south" if facing.y > 0 else &"correr_north"
	var has_vertical: bool = directional_frames != null and directional_frames.has_animation(animation)
	var attacking: bool = attack_anim_remaining > 0 and dodge_remaining <= 0
	runner.visible = health > 0 and (horizontal or (moving and has_vertical))
	stride.visible = health > 0 and not horizontal and not has_vertical and dodge_remaining <= 0
	sprite.visible = not runner.visible and not stride.visible
	sprite.texture = VIEWS[index]
	sprite.position.y = -16 + (roundf(sin(elapsed * 15)) if moving else 0.0)
	if runner.visible:
		runner.sprite_frames = FRAMES if horizontal else directional_frames
		runner.flip_h = horizontal and facing.x < 0
		var clip: StringName = (&"ataque" if attacking else (&"correr" if moving else &"reposo")) if horizontal else animation
		runner.speed_scale = 1.0
		if clip == &"ataque":
			var length: float = 0
			for frame: int in range(FRAMES.get_frame_count(clip)):
				length += FRAMES.get_frame_duration(clip, frame) / FRAMES.get_animation_speed(clip)
			runner.speed_scale = length / Player.ATTACK_ANIM_DURATION
		runner.play(clip)
	if stride.visible:
		stride.pose(VIEWS[index], elapsed, moving, facing.y < 0, attack_anim_remaining / Player.ATTACK_ANIM_DURATION)
	var roll: float = TAU * (1.0 - dodge_remaining / Player.DODGE_DURATION) if dodge_remaining > 0 else 0.0
	sprite.rotation = roll
	runner.rotation = roll
	modulate.a = 0.35 if invulnerable > 0 and int(elapsed * 24) % 2 == 0 and not GamePreferences.current().reduced_flashes else 1.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 11, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	if slash_remaining > 0 and health > 0:
		var angle: float = slash_direction.angle()
		draw_arc(Vector2.ZERO, attack_range, angle - 0.85, angle + 0.85, 12, Color("ffce75"), 2)
		var tip: Vector2 = Vector2.from_angle(angle + lerpf(0.85, -0.85, slash_remaining / Player.SLASH_DURATION))
		draw_line(tip * 12, tip * attack_range, Color("dcf6ee"), 3)
