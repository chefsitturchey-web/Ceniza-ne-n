class_name Recaudador
extends CharacterBody2D

signal died
signal fired(origin: Vector2, direction: Vector2)
signal cue_requested(id: String)
enum State { APPROACH, CLAW_WINDUP, CLAW, VOLLEY_WINDUP, VOLLEY, CHARGE_WINDUP, CHARGE, STUNNED, RECOVER, DEAD }
## Around 20 exposed windows at base damage; target 3-5 minutes with flank hits.
@export var max_health: int = 10000
var health: int = 10000
var phase: int = 1
var state: State = State.APPROACH
var timer: float = 2.5
var target: TopdownPlayer
var facing: Vector2 = Vector2.DOWN
var charge_direction: Vector2 = Vector2.DOWN
var next_pattern: int = 0
var charges_left: int = 0
var shot_timer: float = 0.0
var volleys: int = 0
var elapsed: float = 0.0
var smoke_timer: float = 0.0
var core_exposed: bool:
	get: return state == State.STUNNED
var puppet: Node2D = Node2D.new()
var pieces: Array[Sprite2D] = []
var tracks: Array[Sprite2D] = []
var claws: Array[Sprite2D] = []
var core: Sprite2D
var shield: Sprite2D
var hatch: Polygon2D = Polygon2D.new()
var effects: DebrisEmitter = DebrisEmitter.new()

func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 29
	collider.shape = shape
	add_child(collider)
	add_child(puppet)
	for side: int in [-1, 1]:
		tracks.append(piece("tread", Vector2(side * 34, 0)))
	piece("body", Vector2.ZERO)
	core = piece("core", Vector2.ZERO)
	hatch.polygon = PackedVector2Array([Vector2(-11, -11), Vector2(11, -11), Vector2(11, 11), Vector2(-11, 11)])
	hatch.color = Color("233542")
	puppet.add_child(hatch)
	for side: int in [-1, 1]:
		var claw: Sprite2D = piece("claw", Vector2(side * 45, 23))
		claw.flip_h = side < 0
		claws.append(claw)
	shield = piece("shield", Vector2(0, 37))
	effects.planar = true
	add_child(effects)

func piece(asset: String, offset: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/expedition/boss/%s.png" % asset) as Texture2D
	sprite.position = offset
	puppet.add_child(sprite)
	pieces.append(sprite)
	return sprite

func change_state(value: State, duration: float) -> void:
	if value in [State.CLAW_WINDUP, State.CHARGE_WINDUP, State.VOLLEY_WINDUP]:
		cue_requested.emit("alarm")
	elif value == State.STUNNED:
		cue_requested.emit("hit")
	state = value
	timer = duration
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if state == State.DEAD or target == null or target.health <= 0:
		return
	elapsed += delta
	timer -= delta
	var difference: Vector2 = target.global_position - global_position
	if state in [State.APPROACH, State.VOLLEY_WINDUP, State.VOLLEY, State.RECOVER]:
		facing = Vector2.from_angle(rotate_toward(facing.angle(), difference.angle(), (1.5 if phase == 1 else 2.0) * delta))
	match state:
		State.APPROACH:
			velocity = difference.normalized() * (65 if phase == 1 else 85) if difference.length() > 65 else Vector2.ZERO
			move_and_slide()
			if timer <= 0 or difference.length() < 72:
				change_state(State.CLAW_WINDUP, 0.4)
		State.CLAW_WINDUP:
			if timer <= 0:
				change_state(State.CLAW, 0.35)
		State.CLAW:
			var sweep: Vector2 = facing.rotated(lerpf(-1.1, 1.1, clampf(1 - timer / 0.35, 0, 1)))
			if difference.length() < 88 and sweep.dot(difference.normalized()) > 0.82:
				target.take_damage(20, difference.normalized() * 180)
			if timer <= 0:
				next_pattern = 1
				change_state(State.RECOVER, 0.9)
		State.VOLLEY_WINDUP:
			if timer <= 0:
				volleys = 0
				shot_timer = 0
				change_state(State.VOLLEY, 1.8)
		State.VOLLEY:
			shot_timer -= delta
			if shot_timer <= 0 and volleys < 3:
				fire_fan()
				volleys += 1
				shot_timer = 0.55
			if timer <= 0:
				next_pattern = 2
				change_state(State.RECOVER, 0.8)
		State.CHARGE_WINDUP:
			if timer <= 0:
				change_state(State.CHARGE, 1.8)
		State.CHARGE:
			var before: Vector2 = global_position
			velocity = charge_direction * (360 if phase == 1 else 440)
			var hit: KinematicCollision2D = move_and_collide(velocity * delta)
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
			if closest.distance_to(target.global_position) < 41:
				target.take_damage(32, charge_direction * 310)
			if hit != null:
				stun()
			elif timer <= 0:
				finish_charge()
		State.STUNNED:
			if timer <= 0:
				finish_charge()
		State.RECOVER:
			if timer <= 0:
				if next_pattern == 1:
					change_state(State.VOLLEY_WINDUP, 0.65)
				elif next_pattern == 2:
					charges_left = 2 if phase == 2 else 1
					begin_charge()
				else:
					change_state(State.APPROACH, 2.5)
	update_puppet(delta)

func begin_charge() -> void:
	charge_direction = (target.global_position - global_position).normalized()
	facing = charge_direction
	change_state(State.CHARGE_WINDUP, 0.8)

func finish_charge() -> void:
	charges_left -= 1
	if charges_left > 0:
		begin_charge()
	else:
		next_pattern = 0
		change_state(State.RECOVER, 1.1)

func stun() -> void:
	change_state(State.STUNNED, 2.5)
	effects.emit_pixels(global_position, 14, Color("ffce75"))
	effects.emit_pixels(global_position, 8, Color("89939e"), true)

func fire_fan() -> void:
	var count: int = 7 if phase == 2 else 5
	for index: int in range(count):
		var angle: float = (index - (count - 1) * 0.5) * 0.19 + (0.09 if phase == 2 and volleys % 2 == 1 else 0.0)
		var direction: Vector2 = facing.rotated(angle)
		fired.emit(global_position + facing * 42, direction)

func receive_hit(origin: Vector2, amount: int) -> int:
	if health <= 0:
		return 0
	var front: bool = facing.dot((origin - global_position).normalized()) > 0.45
	var damage: int = amount * 2 if core_exposed else (0 if front else maxi(1, int(amount * 0.25)))
	effects.emit_pixels(global_position + (origin - global_position).normalized() * 28, 5, Color("ffce75"))
	health = maxi(0, health - damage)
	if health <= max_health * 0.5:
		phase = 2
	if health == 0:
		change_state(State.DEAD, 0)
		for sprite: Sprite2D in pieces:
			effects.emit_fragments(sprite.global_position, sprite.texture, 8, sprite.flip_h, true)
		puppet.hide()
		effects.emit_pixels(global_position, 16, Color("89939e"), true)
		set_collision_layer_value(3, false)
		died.emit()
	return damage

func update_puppet(delta: float) -> void:
	puppet.rotation = facing.angle() - PI / 2
	for index: int in range(tracks.size()):
		tracks[index].position.y = roundf(sin(elapsed * 40 + index * PI) * 2) if velocity.length() > 1 or state == State.CHARGE_WINDUP else 0.0
	for index: int in range(claws.size()):
		claws[index].rotation = sin(elapsed * 3 + index * PI) * 0.15
		claws[index].position.y = 23
	if state == State.CLAW_WINDUP:
		claws[0].position.y = 5
		claws[0].rotation = -0.9
	elif state == State.CLAW:
		claws[0].rotation = lerpf(1.2, -0.9, timer / 0.35)
	hatch.position.x = move_toward(hatch.position.x, 23 if core_exposed else 0, delta * 100)
	core.visible = core_exposed
	core.modulate = Color(1.4, 0.9 + sin(elapsed * 12) * 0.3, 0.5)
	shield.position.y = move_toward(shield.position.y, 47 if core_exposed else 37, delta * 50)
	puppet.modulate = Color("ffaaa0") if phase == 2 else Color.WHITE
	smoke_timer -= delta
	if smoke_timer <= 0 and (phase == 2 or core_exposed or state == State.CHARGE_WINDUP):
		smoke_timer = 0.16
		effects.emit_pixels(global_position, 2, Color("89939e"), true)
		if state == State.CHARGE_WINDUP or core_exposed:
			effects.emit_pixels(global_position + Vector2(26, 0), 2, Color("ffce75"))
	queue_redraw()

func _draw() -> void:
	if state == State.DEAD:
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.65))
	draw_circle(Vector2(0, 8), 45, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	if core_exposed:
		draw_circle(Vector2.ZERO, 26 + sin(elapsed * 12) * 3, Color(1, 0.55, 0.15, 0.18))
	if state == State.CHARGE_WINDUP:
		draw_line(charge_direction * 40, charge_direction * 900, Color(1, 0.2, 0.23, 0.4), 2)
	elif state in [State.CLAW_WINDUP, State.CLAW]:
		draw_arc(Vector2.ZERO, 85, facing.angle() - 1.1, facing.angle() + 1.1, 20, Color(1, 0.5, 0.2, 0.5), 2)
	elif state == State.VOLLEY_WINDUP:
		for index: int in range(5):
			var direction: Vector2 = facing.rotated((index - 2) * 0.19)
			draw_line(direction * 44, direction * 72, Color(1, 0.7, 0.3, 0.6), 1)
