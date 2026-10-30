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
	max_health = 9000

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
		if active_links() == 0:
			exposure_left = 6.0
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
	cue_requested.emit("alarm")

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0:
		return
	elapsed += delta
	tactics.observe(target, delta)
	silence_left = maxf(0, silence_left - delta)
	if not core_exposed:
		var destination: Vector2 = Vector2(320, 220)
		var distance: float = INF
		for relay: ChoirRelay in relays:
			if relay.health > 0 and relay.global_position.distance_to(target.global_position) < distance:
				distance = relay.global_position.distance_to(target.global_position)
				destination = relay.global_position.lerp(Vector2(320, 220), 0.58)
		velocity = tactics.steer(self, destination, 48 if phase == 2 else 34)
		move_and_slide()
	else: velocity = Vector2.ZERO
	if exposure_left > 0:
		exposure_left = maxf(0, exposure_left - delta)
		if exposure_left == 0:
			for relay: ChoirRelay in relays:
				relay.reset_relay(150 if phase == 2 else 180)
			pulse_timer = 1.8
			mark_timer = 3.0
	else:
		pulse_timer -= delta
		mark_timer -= delta
		if pulse_timer <= 0 and silence_left <= 0:
			if waves.size() < 6:
				waves.append({"radius": 18.0, "hit": false, "origin": global_position, "gap": (target.global_position - global_position).angle() + PI * 0.55})
				cue_requested.emit("sonar")
			pulse_timer = 1.5 if phase == 2 else 2.4
		if mark_timer <= 0 and marks.size() < 6:
			add_marks()
			mark_timer = 3.4 if phase == 2 else 4.2
	for index: int in range(waves.size() - 1, -1, -1):
		var wave: Dictionary = waves[index]
		var previous: float = wave.radius
		wave.radius += delta * (115 if phase == 2 else 90)
		var origin: Vector2 = wave.get("origin", global_position)
		var distance: float = origin.distance_to(target.global_position)
		var in_gap: bool = wave.has("gap") and absf(angle_difference(float(wave.gap), (target.global_position - origin).angle())) < 0.3
		if not wave.hit and not in_gap and distance >= previous - 9 and distance <= wave.radius + 9:
			wave.hit = true
			target.take_damage(16)
		if wave.radius > 720: waves.remove_at(index)
	for index: int in range(marks.size() - 1, -1, -1):
		var mark: Dictionary = marks[index]
		mark.time -= delta
		if mark.time <= 0 and not mark.hit:
			mark.hit = true
			if target.global_position.distance_to(mark.position) < 25:
				target.take_damage(22)
		if mark.time < -0.3: marks.remove_at(index)
	update_puppet(delta)

func update_puppet(_delta: float) -> void:
	puppet.position.y = roundf(sin(elapsed * 2.2) * 2)
	machine.queue_redraw()
	queue_redraw()

func status_text() -> String:
	return "NÚCLEO EXPUESTO: %ds para atacar" % ceili(exposure_left) if core_exposed else "ENLACES %d/3: rompe las antenas y esquiva los pulsos" % active_links()

func _draw() -> void:
	if health > 0: draw_circle(Vector2(0, 10), 47, Color(0, 0, 0, 0.4))
