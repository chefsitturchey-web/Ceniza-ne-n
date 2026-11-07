class_name Recaudador
extends CharacterBody2D

signal died
signal damaged(amount: int, remaining: int)
signal fired(origin: Vector2, direction: Vector2)
signal cue_requested(id: String)
signal phase_changed(number: int)
signal hit_feedback(blocked: bool)
signal ground_impact(point: Vector2, radius: float, strength: float)
## Avisa el principio y el final de una embestida para que el rumor la acompañe.
signal dash_changed(active: bool)
## Comienza el aviso de un golpe cuerpo a cuerpo (para pistas y sonido).
signal melee_started(kind: String)
enum State { APPROACH, CLAW_WINDUP, CLAW, VOLLEY_WINDUP, VOLLEY, CHARGE_WINDUP, CHARGE, STUNNED, RECOVER, DEAD }
## Around 20 exposed windows at base damage; target 3-5 minutes with flank hits.
@export var max_health: int = 9000
var health: int = 9000
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
## Capa cuerpo a cuerpo común a todos los jefes. Cada golpe se avisa con su forma exacta
## (arco, círculo o corredor) y su dirección queda fija en la segunda mitad del aviso:
## el daño solo llega al terminar el aviso y una esquiva o un paso fuera lo evitan.
var melee: Dictionary = {}
var melee_queue: Array[Dictionary] = []
var melee_cooldown: float = 1.2
var melee_combos: int = 0
## Golpes del jugador contra el escudo seguidos: quien insiste recibe un empujón.
var blocked_streak: int = 0
var blocked_clock: float = 0
## Momento en que terminó el último patrón cuerpo a cuerpo: quien se aleja demasiado rato recibe una embestida corta.
var melee_last_end: float = 0

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

func melee_reach() -> float:
	return 108.0 if self is ElPrefecto else 118.0

func hit_multiplier(origin: Vector2) -> float:
	var front: bool = facing.dot((origin - global_position).normalized()) > 0.45
	return 2.0 if core_exposed else (0.0 if front else 0.25)

func strike_attachments(_origin: Vector2, _direction: Vector2, _amount: int, _reach: float) -> bool:
	return false

func clear_hazards() -> void:
	pass

func status_text() -> String:
	if melee_active(): return melee_status()
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

## Cada jefe sobrescribe el aviso de sus poderes: "claw", "charge" o "volley".
func windup_cue(power: String) -> String:
	return "telegraph_" + power

func change_state(value: State, duration: float) -> void:
	if value == State.CLAW_WINDUP:
		cue_requested.emit(windup_cue("claw"))
	elif value == State.CHARGE_WINDUP:
		cue_requested.emit(windup_cue("charge"))
	elif value == State.VOLLEY_WINDUP:
		cue_requested.emit(windup_cue("volley"))
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
	if tick_melee(delta):
		update_puppet(delta)
		return
	timer -= delta
	var difference: Vector2 = target.global_position - global_position
	if state in [State.APPROACH, State.RECOVER] and try_melee(difference.length()):
		update_puppet(delta)
		return
	if state in [State.APPROACH, State.VOLLEY_WINDUP, State.VOLLEY, State.RECOVER]:
		facing = Vector2.from_angle(rotate_toward(facing.angle(), difference.angle(), (1.5 if phase == 1 else 2.0) * delta))
	match state:
		State.APPROACH:
			velocity = tactics.steer(self, target.global_position, 82 if phase == 1 else 104) if difference.length() > 65 else Vector2.ZERO
			move_and_slide()
			if timer <= 0 or difference.length() < 72:
				choose_attack(difference.length())
		State.CLAW_WINDUP:
			if timer <= 0:
				change_state(State.CLAW, 0.35)
		State.CLAW:
			var sweep: Vector2 = facing.rotated(lerpf(-1.1, 1.1, clampf(1 - timer / 0.35, 0, 1)))
			if difference.length() < melee_reach() and sweep.dot(difference.normalized()) > 0.82:
				target.take_damage(20, difference.normalized() * 180)
			if timer <= 0:
				next_pattern = -1
				change_state(State.RECOVER, 0.6 if phase == 2 else 0.75)
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
				change_state(State.RECOVER, 0.55 if phase == 2 else 0.65)
		State.CHARGE_WINDUP:
			if timer <= 0:
				change_state(State.CHARGE, 1.8)
		State.CHARGE:
			var before: Vector2 = global_position
			velocity = charge_direction * (360 if phase == 1 else 440)
			var hit: KinematicCollision2D = move_and_collide(velocity * delta)
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
			if closest.distance_to(target.global_position) < 52:
				target.take_damage(32, charge_direction * 310)
			if hit != null:
				var cover: ArenaCover = hit.get_collider() as ArenaCover
				if cover != null: cover.receive_damage(90 if phase == 1 else 130)
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
					change_state(State.APPROACH, 1.6 if phase == 2 else 2.0)
	update_puppet(delta)

func begin_charge() -> void:
	charge_direction = (tactics.predicted(target, 0.25) - global_position).normalized()
	facing = charge_direction
	# Contra quien esquiva por anticipado, alterna una carga retardada en fase 2.
	change_state(State.CHARGE_WINDUP, (1.2 if tactics.decisions % 2 == 0 else 0.6) if phase == 2 and tactics.dodge_happy() else 0.8)

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
		change_state(State.RECOVER, 0.75 if phase == 2 else 0.9)

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


## Golpes propios de cada jefe. Claves de cada golpe: kind (swing, slam, shove, lunge),
## windup (aviso en segundos), reach, arc (semiángulo del arco), damage, push, travel y name.
func melee_profile() -> Dictionary:
	return {"close": 105.0, "band": Vector2(150, 260), "cooldown": 1.5,
		"combo": [
			{"kind": "swing", "name": "Garra derecha", "windup": 0.62, "reach": 112.0, "arc": 1.05, "damage": 18, "push": 170.0},
			{"kind": "swing", "name": "Garra izquierda", "windup": 0.5, "reach": 112.0, "arc": 1.05, "damage": 18, "push": 170.0}],
		"finisher": {"kind": "slam", "name": "Pisotón", "windup": 0.7, "reach": 92.0, "damage": 24, "push": 240.0},
		"lunge": {"kind": "lunge", "name": "Cobro a quemarropa", "windup": 0.7, "reach": 40.0, "travel": 190.0, "damage": 22, "push": 220.0},
		"shove": {"kind": "shove", "name": "Empujón", "windup": 0.5, "reach": 78.0, "damage": 12, "push": 330.0, "stamina": 25.0}}

## Intensidad: la segunda fase (y la última guardia en los jefes finales) acorta avisos y pausas.
func melee_tempo() -> float:
	return 0.85 if phase == 2 else 1.0

func melee_active() -> bool:
	return not melee.is_empty()

func melee_winding() -> bool:
	return not melee.is_empty() and float(melee.time) > 0

## Progreso 0..1 del aviso (o del golpe activo), para animación y avisos de suelo.
func melee_progress() -> float:
	if melee.is_empty(): return 0.0
	if float(melee.time) > 0: return 1.0 - float(melee.time) / float(melee.windup)
	return 1.0 - clampf(float(melee.active) / float(melee.active_total), 0, 1)

func melee_clip() -> String:
	if melee_winding(): return "windup"
	return "charge" if melee.kind == "lunge" else "attack"

## Intenta abrir un patrón cuerpo a cuerpo desde un estado neutral. Devuelve true si empieza.
func try_melee(distance: float) -> bool:
	if melee_active() or melee_cooldown > 0 or core_exposed or health <= 0 or target == null: return false
	var profile: Dictionary = melee_profile()
	var sequence: Array[Dictionary] = []
	if blocked_streak >= 2 and distance < float(profile.close) + 20 and profile.has("shove"):
		sequence.append(profile.shove)
		blocked_streak = 0
	elif distance < float(profile.close):
		for move: Dictionary in profile.combo: sequence.append(move)
		if phase == 2 and not profile.finisher.is_empty(): sequence.append(profile.finisher)
	elif profile.has("lunge") and distance >= profile.band.x and distance <= profile.band.y and (tactics.stationary_time > 0.8 or elapsed - melee_last_end > 4.0):
		sequence.append(profile.lunge)
		# Tras cerrar distancia remata con el primer golpe de su combo.
		sequence.append(profile.combo[0])
	else:
		return false
	melee_combos += 1
	melee_queue = sequence
	next_melee()
	return true

func next_melee() -> void:
	if melee_queue.is_empty():
		melee = {}
		melee_cooldown = float(melee_profile().cooldown) * melee_tempo()
		melee_last_end = elapsed
		return
	var move: Dictionary = melee_queue.pop_front().duplicate()
	move.windup = maxf(0.4, float(move.windup) * melee_tempo())
	move.time = move.windup
	move.active_total = 0.22 if move.kind == "lunge" else 0.12
	move.active = move.active_total
	move.direction = (target.global_position - global_position).normalized() if target != null else facing
	move.hit = false
	melee = move
	facing = move.direction
	velocity = Vector2.ZERO
	cue_requested.emit("telegraph_charge" if move.kind == "lunge" else "telegraph_claw")
	melee_started.emit(String(move.kind))

func cancel_melee() -> void:
	if not melee.is_empty() and melee.kind == "lunge" and float(melee.time) <= 0: dash_changed.emit(false)
	melee = {}
	melee_queue.clear()

## Comprueba si un punto está dentro de la forma exacta que se ve en el suelo.
func melee_contains(point: Vector2) -> bool:
	if melee.is_empty(): return false
	var offset: Vector2 = point - global_position
	match String(melee.kind):
		"swing":
			return offset.length() <= float(melee.reach) and absf(angle_difference(Vector2(melee.direction).angle(), offset.angle())) <= float(melee.arc)
		"slam", "shove":
			return offset.length() <= float(melee.reach)
	return false

## Avanza la capa cuerpo a cuerpo. Mientras devuelva true el resto del patrón espera.
func tick_melee(delta: float) -> bool:
	melee_cooldown = maxf(0, melee_cooldown - delta)
	blocked_clock = maxf(0, blocked_clock - delta)
	if blocked_clock == 0: blocked_streak = 0
	if melee.is_empty(): return false
	if target == null or target.health <= 0 or core_exposed:
		cancel_melee()
		return false
	var difference: Vector2 = target.global_position - global_position
	velocity = Vector2.ZERO
	if float(melee.time) > 0:
		melee.time = float(melee.time) - delta
		# Sigue al jugador en la primera mitad del aviso; luego la forma queda fija.
		if float(melee.time) > float(melee.windup) * 0.5 and difference.length() > 1:
			melee.direction = Vector2.from_angle(rotate_toward(Vector2(melee.direction).angle(), difference.angle(), 3.0 * delta))
		facing = melee.direction
		if float(melee.time) <= 0:
			strike_melee()
		return true
	melee.active = float(melee.active) - delta
	if melee.kind == "lunge":
		var before: Vector2 = global_position
		var step: Vector2 = Vector2(melee.direction) * float(melee.travel) / float(melee.active_total) * delta
		var collision: KinematicCollision2D = move_and_collide(step)
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
		if not melee.hit and nearest.distance_to(target.global_position) <= float(melee.reach):
			melee.hit = true
			target.take_damage(int(melee.damage), Vector2(melee.direction) * float(melee.push))
		if collision != null: melee.active = 0.0
	if float(melee.active) <= 0:
		if melee.kind == "lunge": dash_changed.emit(false)
		next_melee()
	return true

func strike_melee() -> void:
	if melee.kind == "lunge":
		dash_changed.emit(true)
		return
	var point: Vector2 = global_position + (Vector2(melee.direction) * float(melee.reach) * 0.55 if melee.kind == "swing" else Vector2.ZERO)
	ground_impact.emit(point, float(melee.reach) * (0.6 if melee.kind == "swing" else 1.0), 2.0 if melee.kind == "swing" else 3.2)
	if melee_contains(target.global_position):
		melee.hit = true
		var away: Vector2 = (target.global_position - global_position).normalized()
		target.take_damage(int(melee.damage), away * float(melee.push))
		if melee.has("stamina"): target.stamina = maxf(0, target.stamina - float(melee.stamina))

func melee_status() -> String:
	match String(melee.kind):
		"swing": return String(melee.name).to_upper() + ": sal del arco o esquiva hacia un lado"
		"slam": return String(melee.name).to_upper() + ": aléjate del círculo"
		"shove": return String(melee.name).to_upper() + ": deja de golpear su escudo"
		"lunge": return String(melee.name).to_upper() + ": sal de la línea marcada"
	return ""

func receive_hit(origin: Vector2, amount: int) -> int:
	if health <= 0 or amount <= 0:
		return 0
	var factor: float = hit_multiplier(origin)
	var damage: int = maxi(1, int(amount * factor)) if factor > 0 else 0
	hit_feedback.emit(damage == 0)
	if damage == 0:
		cue_requested.emit("shield")
		blocked_streak += 1
		blocked_clock = 2.5
		if blocked_streak >= 2: melee_cooldown = minf(melee_cooldown, 0.2)
	effects.emit_pixels(global_position + (origin - global_position).normalized() * 28, 5, Color("ffce75"))
	health = maxi(0, health - damage)
	damaged.emit(damage, health)
	if damage > 0 and combat_visual != null: combat_visual.pulse_hurt()
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		phase_changed.emit(phase)
		cue_requested.emit("alarm")
	if health == 0:
		cancel_melee()
		change_state(State.DEAD, 0)
		clear_hazards()
		if combat_visual != null:
			effects.emit_fragments(combat_visual.sprite.global_position, combat_visual.texture(), 16, false, false, combat_visual.sprite.global_scale)
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
	if not native_combat_art and smoke_timer <= 0 and (phase == 2 or core_exposed or state == State.CHARGE_WINDUP):
		smoke_timer = 0.16
		effects.emit_pixels(global_position, 2, Color("89939e"), true)
		if state == State.CHARGE_WINDUP or core_exposed:
			effects.emit_pixels(global_position + Vector2(26, 0), 2, Color("ffce75"))
	queue_redraw()

func _draw() -> void:
	if state == State.DEAD:
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.65))
	var radius: float = 58 if native_combat_art else 45
	var support: Vector2 = Vector2(0, 8)
	if combat_visual != null and combat_visual.actor_id in ["prefecto", "madre"]:
		radius = 22 if combat_visual.actor_id == "prefecto" else 26
		support = Vector2(0, 2)
	draw_circle(support, radius, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	if native_combat_art: return # Warnings and textured strikes live in the arena layers.
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
