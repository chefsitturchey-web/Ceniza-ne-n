class_name CoroSumergido
extends Recaudador

var relays: Array[ChoirRelay] = []
var waves: Array[Dictionary] = []
var marks: Array[Dictionary] = []
var pulse_timer: float = 2.0
var mark_timer: float = 4.0
var exposure_left: float = 0.0
var machine: BossMachineVisual
var silence_left: float = 0

func _init() -> void:
	max_health = 12000

func build_visual() -> void:
	machine = BossMachineVisual.new()
	machine.actor = self
	machine.kind = "choir"
	puppet.add_child(machine)

func install_relays(parent: Node2D) -> void:
	for point: Vector2 in [Vector2(140, 100), Vector2(500, 100), Vector2(320, 330)]:
		var relay: ChoirRelay = ChoirRelay.new()
		relay.position = point
		parent.add_child(relay)
		relays.append(relay)

func is_core_exposed() -> bool:
	return exposure_left > 0

func clear_hazards() -> void:
	waves.clear()
	marks.clear()
	for relay: ChoirRelay in relays:
		relay.health = 0
		relay.queue_redraw()

func hit_multiplier(_origin: Vector2) -> float:
	return 2.0 if core_exposed else 0.0

## Latigazos de cables y reflujo: acercarse a romper antenas ya no es gratis.
func melee_profile() -> Dictionary:
	return {"close": 115.0, "band": Vector2(140, 240), "cooldown": 1.9,
		"combo": [
			{"kind": "swing", "name": "Latigazo de cables", "windup": 0.68, "reach": 128.0, "arc": 1.15, "damage": 16, "push": 190.0},
			{"kind": "swing", "name": "Contralatigazo", "windup": 0.55, "reach": 128.0, "arc": 1.15, "damage": 16, "push": 190.0}],
		"finisher": {"kind": "slam", "name": "Reflujo", "windup": 0.8, "reach": 100.0, "damage": 22, "push": 260.0},
		"lunge": {"kind": "lunge", "name": "Arrastre abisal", "windup": 0.8, "reach": 42.0, "travel": 170.0, "damage": 20, "push": 220.0},
		"shove": {"kind": "shove", "name": "Ola de presión", "windup": 0.5, "reach": 95.0, "damage": 10, "push": 360.0, "stamina": 20.0}}

func active_links() -> int:
	var count: int = 0
	for relay: ChoirRelay in relays:
		if relay.health > 0: count += 1
	return count

func strike_attachments(origin: Vector2, direction: Vector2, amount: int, reach: float) -> bool:
	for relay: ChoirRelay in relays:
		var offset: Vector2 = relay.global_position - origin
		if relay.health <= 0 or offset.length() > reach + 18 or direction.dot(offset.normalized()) < cos(0.85):
			continue
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, relay.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		relay.receive(amount)
		cue_requested.emit("hit")
		# Represalia: en fase 2 romper una antena atrae marcas sobre el atacante.
		if phase == 2 and active_links() > 0 and marks.size() < 6:
			add_marks()
			mark_timer = maxf(mark_timer, 2.0)
		if active_links() == 0:
			exposure_left = 5.0
			waves.clear()
			marks.clear()
			cue_requested.emit("upgrade")
		return true
	return false

func add_marks() -> void:
	var center: Vector2 = tactics.predicted(target, 0.28)
	for offset: Vector2 in [Vector2.ZERO, Vector2(-70, 0), Vector2(70, 0)]:
		marks.append({"position": (center + offset.rotated(tactics.observed_velocity.angle())).clamp(Vector2(70, 65), Vector2(570, 415)), "time": 0.9, "hit": false})
	if phase == 2:
		for offset: Vector2 in [Vector2(0, -70), Vector2(0, 70)]:
			marks.append({"position": (target.global_position + offset).clamp(Vector2(40, 40), Vector2(600, 440)), "time": 0.9, "hit": false})
	cue_requested.emit("telegraph_volley")

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0:
		return
	elapsed += delta
	tactics.observe(target, delta)
	silence_left = maxf(0, silence_left - delta)
	var meleeing: bool = tick_melee(delta)
	if meleeing: pass
	elif not core_exposed and try_melee(global_position.distance_to(target.global_position)): meleeing = true
	elif not core_exposed:
		var destination: Vector2 = Vector2(320, 220)
		var distance: float = INF
		for relay: ChoirRelay in relays:
			if relay.health > 0 and relay.global_position.distance_to(target.global_position) < distance:
				distance = relay.global_position.distance_to(target.global_position)
				destination = relay.global_position.lerp(Vector2(320, 220), 0.58)
		velocity = tactics.steer(self, destination, 56 if phase == 2 else 42)
		move_and_slide()
	else: velocity = Vector2.ZERO
	if exposure_left > 0 and meleeing: cancel_melee()
	if exposure_left > 0:
		exposure_left = maxf(0, exposure_left - delta)
		if exposure_left == 0:
			for relay: ChoirRelay in relays:
				relay.reset_relay(150 if phase == 2 else 180)
			pulse_timer = 1.8
			mark_timer = 3.0
	elif not meleeing or not melee_winding():
		# Durante el aviso de un golpe cercano no se suman pulsos ni marcas nuevas.
		pulse_timer -= delta
		mark_timer -= delta
		if pulse_timer <= 0 and silence_left <= 0:
			if waves.size() < 6:
				waves.append({"radius": 18.0, "hit": false, "origin": global_position, "gap": (target.global_position - global_position).angle() + PI * 0.55})
				cue_requested.emit("sonar")
			pulse_timer = 1.35 if phase == 2 else 2.0
		if mark_timer <= 0 and marks.size() < 6:
			add_marks()
			mark_timer = 3.0 if phase == 2 else 3.6
	# Damage emits died synchronously: arena.finish() may clear both arrays.
	# Iterate a snapshot and stop immediately when combat has resolved.
	for wave: Dictionary in waves.duplicate():
		if health <= 0 or not is_instance_valid(target) or target.health <= 0: return
		var previous: float = wave.radius
		wave.radius += delta * (115 if phase == 2 else 90)
		var origin: Vector2 = wave.get("origin", global_position)
		var distance: float = origin.distance_to(target.global_position)
		var in_gap: bool = wave.has("gap") and absf(angle_difference(float(wave.gap), (target.global_position - origin).angle())) < 0.3
		if not wave.hit and not in_gap and distance >= previous - 9 and distance <= wave.radius + 9:
			wave.hit = true
			target.take_damage(16)
			if target.health <= 0: return
		if wave.radius > 720: waves.erase(wave)
	for mark: Dictionary in marks.duplicate():
		if health <= 0 or not is_instance_valid(target) or target.health <= 0: return
		mark.time -= delta
		if mark.time <= 0 and not mark.hit:
			mark.hit = true
			ground_impact.emit(mark.position, 32, 2.4)
			if target.global_position.distance_to(mark.position) < 32:
				target.take_damage(22)
				if target.health <= 0: return
		if mark.time < -0.3: marks.erase(mark)
	update_puppet(delta)

func update_puppet(_delta: float) -> void:
	puppet.position.y = roundf(sin(elapsed * 2.2) * 2)
	machine.queue_redraw()
	queue_redraw()

func status_text() -> String:
	if melee_active(): return melee_status()
	return "NÚCLEO EXPUESTO: %ds para atacar" % ceili(exposure_left) if core_exposed else "ENLACES %d/3: rompe las antenas y esquiva los pulsos" % active_links()

func _draw() -> void:
	if health > 0:
		draw_set_transform(Vector2(0, 3), 0, Vector2(1, 0.55))
		draw_circle(Vector2.ZERO, 60, Color(0, 0, 0, 0.4))
