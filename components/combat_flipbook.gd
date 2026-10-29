class_name CombatFlipbook
extends Node2D
var actor: Node2D
var actor_id: String = "portador"
var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
var current: StringName = &""
var clip_clock: float = 0
var travel: float = 0
var last_position: Vector2
var hurt_left: float = 0
var state_duration: float = 1
var previous_state: int = -1
var state_name: String = "idle"
var walk_direction: String = ""
var last_step: Vector2 = Vector2.ZERO
var walk_phase: float = 0
var walking_backwards: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = CombatSpriteLibrary.frames(actor_id)
	sprite.position = CombatSpriteLibrary.offset_for(actor_id) * CombatSpriteLibrary.scale_for(actor_id)
	add_child(sprite)
	last_position = actor.global_position
	set_pose("idle", Vector2.DOWN)

func _process(delta: float) -> void:
	clip_clock += delta
	hurt_left = maxf(0, hurt_left - delta)
	if actor is Recaudador: pose_boss(actor)
	else: pose_player()

func set_pose(state: String, facing: Vector2, progress: float = -1) -> void:
	var direction: String = CombatSpriteLibrary.direction(facing)
	if state == "walk":
		# A small dead band prevents diagonal path corners flickering between views.
		if walk_direction.is_empty() or absf(facing.x) > absf(facing.y) * 1.25 or absf(facing.y) > absf(facing.x) * 1.25:
			walk_direction = direction
		direction = walk_direction
	else: walk_direction = ""
	var clip: StringName = StringName(state + "_" + direction)
	if current != clip:
		current = clip
		clip_clock = 0
	state_name = state
	var count: int = sprite.sprite_frames.get_frame_count(clip)
	var duration: float = 0
	for index: int in count: duration += sprite.sprite_frames.get_frame_duration(clip, index)
	var cursor: float = clampf(progress, 0, 1) * duration if progress >= 0 else clip_clock * sprite.sprite_frames.get_animation_speed(clip)
	if progress < 0 and sprite.sprite_frames.get_animation_loop(clip): cursor = fposmod(cursor, duration)
	var frame: int = count - 1
	var elapsed: float = 0
	for index: int in count:
		elapsed += sprite.sprite_frames.get_frame_duration(clip, index)
		if cursor < elapsed:
			frame = index
			break
	sprite.animation = clip
	sprite.pause()
	sprite.frame = frame
	sprite.rotation = 0
	sprite.flip_h = false
	sprite.scale = Vector2.ONE * CombatSpriteLibrary.scale_for(actor_id)

func record_travel() -> void:
	var distance: float = actor.global_position.distance_to(last_position)
	last_step = actor.global_position - last_position if distance < 90 else Vector2.ZERO
	if distance < 90: travel += distance
	last_position = actor.global_position

func pose_player() -> void:
	record_travel()
	var side: bool = actor is Player
	var facing: Vector2 = Vector2(actor.facing, 0) if side else actor.facing
	var health: int = actor.health
	var moving: bool = actor.velocity.length() > 10
	var remaining: float = actor.attack_anim_remaining
	var dodge: float = actor.dodge_remaining
	position.y = actor.mobility.rider_offset() if side and actor.riding else 0.0
	if health <= 0: set_pose("death", facing)
	elif dodge > 0: set_pose("dodge", facing, 1 - dodge / Player.DODGE_DURATION)
	elif hurt_left > 0: set_pose("hurt", facing, 1 - hurt_left / 0.18)
	elif remaining > 0:
		var aim: Vector2 = Vector2(actor.attack_facing, 0) if side else actor.slash_direction
		var ratio: float = clampf(1 - remaining / Player.ATTACK_ANIM_DURATION, 0, 1)
		if ratio < 0.25: set_pose("windup", aim, ratio / 0.25)
		else: set_pose("attack", aim, (ratio - 0.25) / 0.75)
	elif moving and not (side and actor.riding): set_pose("walk", facing, fposmod(travel / (64.0 if side else 56.0), 1))
	else: set_pose("exposed" if actor.stamina < 30 else "idle", facing)

func pose_boss(boss: Recaudador) -> void:
	record_travel()
	if previous_state != boss.state:
		previous_state = boss.state
		state_duration = maxf(0.01, boss.timer)
	var direction: Vector2 = boss.facing
	if boss.state == Recaudador.State.DEAD: set_pose("death", direction)
	elif boss.core_exposed: set_pose("exposed", direction)
	elif boss is MadreCero and boss.cast_recovery > 0: set_pose("attack", direction, 1 - boss.cast_recovery / 0.35)
	elif boss is MadreCero and boss.casting_time() < 0.65: set_pose("windup", direction, 1 - maxf(0, boss.casting_time()) / 0.65)
	elif hurt_left > 0: set_pose("hurt", direction, 1 - hurt_left / 0.18)
	else:
		match boss.state:
			Recaudador.State.CLAW_WINDUP, Recaudador.State.CHARGE_WINDUP, Recaudador.State.VOLLEY_WINDUP:
				set_pose("windup", boss.charge_direction if boss.state == Recaudador.State.CHARGE_WINDUP else direction, 1 - boss.timer / state_duration)
			Recaudador.State.CLAW: set_pose("attack", direction, 1 - boss.timer / state_duration)
			Recaudador.State.VOLLEY: set_pose("shoot", direction, 1 - clampf(boss.shot_timer / 0.55, 0, 1))
			Recaudador.State.CHARGE: set_pose("charge", boss.charge_direction)
			_:
				var walking: bool = boss.velocity.length() > 2
				var stride: float = 92.0 if boss is MadreCero else (76.0 if boss is ElPrefecto else 58.0)
				var alignment: float = boss.velocity.normalized().dot(direction)
				if alignment < -0.25: walking_backwards = true
				elif alignment > 0.25: walking_backwards = false
				walk_phase += last_step.length() / stride * (-1 if walking_backwards else 1)
				# Guards keep the visible shield aligned with their blocking direction.
				# Backpedalling reverses the stride continuously rather than turning the torso.
				set_pose("walk" if walking else "idle", boss.velocity if walking and boss is MadreCero else direction, fposmod(walk_phase, 1) if walking else -1)

func pulse_hurt() -> void: hurt_left = 0.18

func texture() -> Texture2D:
	return sprite.sprite_frames.get_frame_texture(current, sprite.frame)
