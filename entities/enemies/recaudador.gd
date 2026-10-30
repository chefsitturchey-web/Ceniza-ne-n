class_name Recaudador
extends CharacterBody2D

signal died
signal fired(origin: Vector2, direction: Vector2)
signal cue_requested(id: String)
signal phase_changed(number: int)
signal hit_feedback(blocked: bool)
## Avisa el principio y el final de una embestida para que el rumor la acompañe.
signal dash_changed(active: bool)
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
	get: return is_core_exposed()
var puppet: Node2D = Node2D.new()
var pieces: Array[Sprite2D] = []
var tracks: Array[Sprite2D] = []
var claws: Array[Sprite2D] = []
var core: Sprite2D
var shield: Sprite2D
var turbine: Sprite2D
var track_distance: float = 0
var hatch: Sprite2D
var effects: DebrisEmitter = DebrisEmitter.new()
var tactics: BossTactics = BossTactics.new()
var last_decision: String = ""
@export var native_combat_art: bool = true
var combat_visual: CombatFlipbook

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
	build_visual()
	if native_combat_art:
		combat_visual = CombatFlipbook.new()
		combat_visual.actor = self
		combat_visual.actor_id = "caldera" if self is SantaCaldera else ("coro" if self is CoroSumergido else ("prefecto" if self is ElPrefecto else ("madre" if self is MadreCero else "recaudador")))
		add_child(combat_visual)
		puppet.hide()
	effects.planar = true
	add_child(effects)

func build_visual() -> void:
	hatch = Sprite2D.new()
	for side: int in [-1, 1]:
		tracks.append(piece("tread", Vector2(side * 34, 0)))
	piece("body", Vector2.ZERO)
	core = piece("core", Vector2.ZERO)
	hatch.texture = DepotArt.reactor_shutter()
	hatch.scale = Vector2(25, 23) / hatch.texture.get_size()
	puppet.add_child(hatch)
	for side: int in [-1, 1]:
		var claw: Sprite2D = piece("claw", Vector2(side * 45, 23))
		claw.flip_h = side < 0
		claws.append(claw)
	shield = piece("shield", Vector2(0, 37))
	turbine = piece("fan", Vector2(0, -20))

func is_core_exposed() -> bool:
	return state == State.STUNNED

func hit_multiplier(origin: Vector2) -> float:
	var front: bool = facing.dot((origin - global_position).normalized()) > 0.45
	return 2.0 if core_exposed else (0.0 if front else 0.25)

func strike_attachments(_origin: Vector2, _direction: Vector2, _amount: int, _reach: float) -> bool:
	return false

func clear_hazards() -> void:
	pass

func status_text() -> String:
	match state:
		State.CHARGE_WINDUP: return "EMBESTIDA: esquiva hacia un lado cuando arranque"
		State.CHARGE: return "Deja que choque contra una pared o cobertura"
		State.STUNNED: return "NÚCLEO EXPUESTO: ataca antes de que cierre"
		State.CLAW_WINDUP, State.CLAW: return "GARRAZO: toma distancia"
		State.VOLLEY_WINDUP, State.VOLLEY: return "COBRO: usa las coberturas"
	return "Escudo frontal: provoca una embestida contra un obstáculo"

func piece(asset: String, offset: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	var index: int = {"body": 0, "tread": 1, "claw": 2, "shield": 3, "core": 4, "fan": 5}[asset]
	sprite.texture = DepotArt.part(index)
	var extent: Vector2 = {"body": Vector2(70, 64), "tread": Vector2(23, 77), "claw": Vector2(25, 52), "shield": Vector2(87, 33), "core": Vector2(23, 23), "fan": Vector2(17, 17)}[asset]
	sprite.scale = extent / sprite.texture.get_size()
	sprite.position = offset
	puppet.add_child(sprite)
	pieces.append(sprite)
	return sprite

func change_state(value: State, duration: float) -> void:
	if value in [State.CLAW_WINDUP, State.CHARGE_WINDUP, State.VOLLEY_WINDUP]:
		cue_requested.emit("alarm")
	elif value == State.STUNNED:
		cue_requested.emit("hit")
	if value == State.CHARGE and state != State.CHARGE:
		dash_changed.emit(true)
	elif state == State.CHARGE and value != State.CHARGE:
		dash_changed.emit(false)
	state = value
	timer = duration
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if state == State.DEAD or target == null or target.health <= 0:
		return
	elapsed += delta
	tactics.observe(target, delta)
	timer -= delta
	var difference: Vector2 = target.global_position - global_position
	if state in [State.APPROACH, State.VOLLEY_WINDUP, State.VOLLEY, State.RECOVER]:
		facing = Vector2.from_angle(rotate_toward(facing.angle(), difference.angle(), (1.5 if phase == 1 else 2.0) * delta))
	match state:
		State.APPROACH:
			velocity = tactics.steer(self, target.global_position, 65 if phase == 1 else 85) if difference.length() > 65 else Vector2.ZERO
			move_and_slide()
			if timer <= 0 or difference.length() < 72:
				choose_attack(difference.length())
		State.CLAW_WINDUP:
			if timer <= 0:
				change_state(State.CLAW, 0.35)
		State.CLAW:
			var sweep: Vector2 = facing.rotated(lerpf(-1.1, 1.1, clampf(1 - timer / 0.35, 0, 1)))
			if difference.length() < 88 and sweep.dot(difference.normalized()) > 0.82:
				target.take_damage(20, difference.normalized() * 180)
			if timer <= 0:
				next_pattern = -1
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
				next_pattern = -1
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
				elif next_pattern == -1:
					choose_attack(difference.length())
				else:
					change_state(State.APPROACH, 2.5)
	update_puppet(delta)

func begin_charge() -> void:
	charge_direction = (tactics.predicted(target, 0.25) - global_position).normalized()
	facing = charge_direction
	change_state(State.CHARGE_WINDUP, 0.8)

func choose_attack(distance: float) -> void:
	var visible: bool = tactics.clear_shot(self, target.global_position)
	last_decision = tactics.choose({"claw": 12.0 if distance < 90 else -5.0, "volley": 7.0 if visible else -3.0, "charge": 9.0 if distance > 130 or not visible else 2.0}, 3.5)
	match last_decision:
		"claw": change_state(State.CLAW_WINDUP, 0.65)
		"volley": change_state(State.VOLLEY_WINDUP, 0.8)
		"charge":
			charges_left = 2 if phase == 2 else 1
			begin_charge()
		_: change_state(State.APPROACH, 0.6)

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
	if health <= 0 or amount <= 0:
		return 0
	var factor: float = hit_multiplier(origin)
	var damage: int = maxi(1, int(amount * factor)) if factor > 0 else 0
	hit_feedback.emit(damage == 0)
	if damage == 0:
		cue_requested.emit("shield")
	effects.emit_pixels(global_position + (origin - global_position).normalized() * 28, 5, Color("ffce75"))
	health = maxi(0, health - damage)
	if damage > 0 and combat_visual != null: combat_visual.pulse_hurt()
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		phase_changed.emit(phase)
		cue_requested.emit("alarm")
	if health == 0:
		change_state(State.DEAD, 0)
		clear_hazards()
		if combat_visual != null:
			effects.emit_fragments(global_position, combat_visual.texture(), 16)
		else:
			for sprite: Sprite2D in pieces:
				effects.emit_fragments(sprite.global_position, sprite.texture, 8, sprite.flip_h, true, sprite.global_scale, sprite.global_rotation)
		puppet.hide()
		effects.emit_pixels(global_position, 16, Color("89939e"), true)
		set_collision_layer_value(3, false)
		died.emit()
	return damage

func update_puppet(delta: float) -> void:
	puppet.rotation = facing.angle() - PI / 2
	track_distance += velocity.length() * delta
	for index: int in range(tracks.size()):
		tracks[index].position.y = roundf(sin(track_distance * 0.3 + index * PI)) if velocity.length() > 1 else 0.0
	if turbine != null: turbine.rotation += delta * (9.0 if phase == 2 else 4.0)
	for index: int in range(claws.size()):
		claws[index].rotation = sin(elapsed * 3 + index * PI) * 0.15
		claws[index].position.y = 23
	if state == State.CLAW_WINDUP:
		claws[0].position.y = 5
		claws[0].rotation = -0.9
	elif state == State.CLAW:
		claws[0].rotation = lerpf(1.2, -0.9, timer / 0.35)
		claws[0].position.y = 23 + sin(clampf(1 - timer / 0.35, 0, 1) * PI) * 16
	if state == State.VOLLEY:
		puppet.position = Vector2(0, -maxf(0, 1 - shot_timer / 0.12) * 2)
	else: puppet.position = Vector2.ZERO
	hatch.position.x = move_toward(hatch.position.x, 23 if core_exposed else 0, delta * 100)
	core.visible = core_exposed
	core.modulate = Color(1.2, 0.9, 0.5) if GamePreferences.current().reduced_flashes else Color(1.4, 0.9 + sin(elapsed * 12) * 0.3, 0.5)
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
	var radius: float = 45
	var support: Vector2 = Vector2(0, 8)
	if combat_visual != null and combat_visual.actor_id in ["prefecto", "madre"]:
		radius = 22 if combat_visual.actor_id == "prefecto" else 26
		support = Vector2(0, 2)
	draw_circle(support, radius, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	if core_exposed:
		draw_circle(Vector2.ZERO, 26 + sin(elapsed * 12) * 3, Color(1, 0.55, 0.15, 0.18))
	if state == State.CHARGE_WINDUP:
		var side: Vector2 = charge_direction.orthogonal() * 26
		draw_colored_polygon(PackedVector2Array([charge_direction * 40 - side, charge_direction * 900 - side, charge_direction * 900 + side, charge_direction * 40 + side]), Color(1, 0.2, 0.23, 0.1))
		draw_line(charge_direction * 40, charge_direction * 900, Color(1, 0.2, 0.23, 0.4), 2)
	elif state in [State.CLAW_WINDUP, State.CLAW]:
		draw_arc(Vector2.ZERO, 85, facing.angle() - 1.1, facing.angle() + 1.1, 20, Color(1, 0.5, 0.2, 0.5), 2)
	elif state == State.VOLLEY_WINDUP:
		var count: int = 7 if phase == 2 else 5
		for index: int in range(count):
			var direction: Vector2 = facing.rotated((index - (count - 1) * 0.5) * 0.19)
			draw_line(direction * 44, direction * 72, Color(1, 0.7, 0.3, 0.6), 1)
