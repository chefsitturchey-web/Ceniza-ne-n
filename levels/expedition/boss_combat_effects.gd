class_name BossCombatEffects
extends Node2D
## Secondary attacks share their exact geometry with their warnings. Cosmetic
## smoke/shards have a separate bounded budget and never determine damage.
const PARTICLE_LIMIT: int = 180
const COLORS: Array[Color] = [Color("f1bd73"), Color("f27640"), Color("60dce0"), Color("9dc9f0"), Color("ed80ad")]
var arena: RecaudadorArena
var hazards: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cooldown: float = 5.0
var smoke_clock: float = 0
var clock: float = 0
var shake: float = 0
var last_state: int = -1
var combo_number: int = 0
var enabled: bool = true

func _ready() -> void:
	z_index = 6
	rng.seed = 419 + arena.zone_index
	arena.boss.fired.connect(muzzle)
	arena.boss.hit_feedback.connect(func(blocked: bool) -> void:
		impact(arena.boss.position - arena.boss.facing * 16, 22, 0.0, 5 if blocked else 10))

func tint() -> Color: return COLORS[arena.zone_index]

func clear_attacks() -> void:
	hazards.clear()
	shake = 0
	arena.camera.offset = Vector2.ZERO
	queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(arena.camera): arena.camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not arena.boss.is_physics_processing(): return
	tick(delta)

func tick(delta: float) -> void:
	var boss: Recaudador = arena.boss
	if not enabled or arena.ending or boss.health <= 0 or arena.player.health <= 0:
		clear_attacks()
		return
	# A genuine punish window cancels pending secondary damage, including its warning.
	if boss.core_exposed or (boss is CoroSumergido and (boss as CoroSumergido).silence_left > 0):
		hazards.clear()
		cooldown = maxf(cooldown, 1.4)
	else:
		cooldown -= delta
		if cooldown <= 0:
			request_combo()
			cooldown = [7.0, 6.2, 5.6, 4.7, 4.2][arena.zone_index] * (0.76 if boss.phase == 2 else 1.0)
	for index: int in range(hazards.size() - 1, -1, -1):
		var hazard: Dictionary = hazards[index]
		hazard.time -= delta
		if hazard.time <= 0 and not hazard.hit:
			hazard.hit = true
			resolve(hazard)
		if hazard.time < -0.42: hazards.remove_at(index)
	if last_state != boss.state:
		if boss.state == Recaudador.State.CLAW:
			impact(boss.position + boss.facing * 65, 96, 2.8, 22)
		elif last_state == Recaudador.State.CHARGE:
			impact(boss.position, 108, 4.5, 28)
		last_state = boss.state

func safe_point(point: Vector2) -> Vector2:
	var boundary: PackedVector2Array = ArenaLayout.boundary(arena.zone_index)
	if Geometry2D.is_point_in_polygon(point, boundary): return point
	var nearest: Vector2 = Vector2(320, 240)
	var distance: float = INF
	for index: int in boundary.size():
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(point, boundary[index], boundary[(index + 1) % boundary.size()])
		if candidate.distance_squared_to(point) < distance:
			nearest = candidate
			distance = candidate.distance_squared_to(point)
	return nearest.move_toward(Vector2(320, 240), 18)

func request_combo() -> void:
	var boss: Recaudador = arena.boss
	if not enabled or arena.ending or boss.core_exposed or boss.health <= 0 or not hazards.is_empty(): return
	combo_number += 1
	var predicted: Vector2 = safe_point(boss.tactics.predicted(arena.player, 0.38))
	var count: int = 1 if arena.zone_index == 0 else (3 if boss.phase == 2 and arena.zone_index >= 2 else 2)
	for index: int in count:
		var origin: Vector2 = boss.position
		var kind: String = "burst"
		var radius: float = 48 + arena.zone_index * 3
		var endpoint: Vector2 = origin
		var delay: float = 1.15 + index * 0.22
		if arena.zone_index == 0:
			radius = 142 if boss.phase == 2 else 118
		elif arena.zone_index == 3 or (arena.zone_index == 4 and combo_number % 2 == 0):
			kind = "lance"
			radius = 20 if arena.zone_index == 3 else 25
			var direction: Vector2 = (predicted - origin).normalized().rotated((index - (count - 1) * 0.5) * 0.30)
			endpoint = safe_point(origin + direction * 400)
			var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, endpoint, 1)
			var collision: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
			if not collision.is_empty(): endpoint = collision.position
		else:
			var angle: float = float(index) / count * TAU + combo_number * 0.7
			origin = safe_point(predicted + Vector2.from_angle(angle) * (62 if count > 1 else 0))
			endpoint = origin
		hazards.append({"origin": origin, "end": endpoint, "kind": kind, "radius": radius, "time": delay, "warning": delay, "hit": false})
	arena.boss.cue_requested.emit("alarm")

func contains(hazard: Dictionary, point: Vector2) -> bool:
	if hazard.kind == "lance":
		return Geometry2D.get_closest_point_to_segment(point, hazard.origin, hazard.end).distance_to(point) <= hazard.radius
	return point.distance_to(hazard.origin) <= hazard.radius

func resolve(hazard: Dictionary) -> void:
	var player: TopdownPlayer = arena.player
	if contains(hazard, player.position):
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(hazard.origin, player.position, 1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			player.take_damage(16 + arena.zone_index * 2, (player.position - hazard.origin).normalized() * 160)
	impact(hazard.origin if hazard.kind == "burst" else hazard.end, hazard.radius if hazard.kind == "burst" else 55, 3.6, 24)
	arena.boss.cue_requested.emit("hit")

func muzzle(origin: Vector2, direction: Vector2) -> void:
	impact(origin, 15, 0, 3)
	if arena.zone_index < 3:
		add_particle(origin - direction * 5, -direction * 12 + Vector2(0, -20), 0.7, 5, true)

func impact(point: Vector2, radius: float, strength: float = 2.0, shards: int = 18) -> void:
	if impacts.size() < 32: impacts.append({"position": point, "radius": radius, "age": 0.0, "seed": rng.randi() % 1000})
	if not GamePreferences.current().reduced_flashes: shake = maxf(shake, strength)
	for index: int in shards:
		var direction: Vector2 = Vector2.from_angle(rng.randf() * TAU)
		add_particle(point, direction * rng.randf_range(35, 120) + Vector2(0, -30), rng.randf_range(0.25, 0.65), rng.randf_range(1, 3), false)
	for index: int in mini(4, shards / 4):
		add_particle(point + Vector2(rng.randf_range(-12, 12), 0), Vector2(rng.randf_range(-10, 10), -30), 0.8, 5, true)

func add_particle(point: Vector2, speed: Vector2, duration: float, size: float, smoke: bool) -> void:
	if not GamePreferences.current().particles or particles.size() >= PARTICLE_LIMIT: return
	particles.append({"position": point, "velocity": speed, "age": 0.0, "life": duration, "size": size, "smoke": smoke, "seed": rng.randf() * TAU})

func _process(delta: float) -> void:
	clock += delta
	if not GamePreferences.current().particles: particles.clear()
	for index: int in range(particles.size() - 1, -1, -1):
		var part: Dictionary = particles[index]
		part.age += delta
		part.position += part.velocity * delta
		part.velocity.y += (-8.0 if part.smoke else 85.0) * delta
		if part.age >= part.life: particles.remove_at(index)
	for index: int in range(impacts.size() - 1, -1, -1):
		impacts[index].age += delta
		if impacts[index].age > 0.65: impacts.remove_at(index)
	if enabled and not arena.ending and arena.boss.health > 0 and arena.zone_index < 3:
		smoke_clock -= delta
		if smoke_clock <= 0:
			smoke_clock = 0.10 if arena.boss.phase == 2 else 0.22
			for side: int in [-1, 1]:
				var vent_height: float = [60.0, 66.0, 55.0][arena.zone_index]
				add_particle(arena.boss.position + Vector2(side * 24, -vent_height), Vector2(side * 5, -22), 1.3, 4 if arena.boss.phase == 1 else 6, true)
	shake = move_toward(shake, 0, delta * 11)
	if GamePreferences.current().reduced_flashes: shake = 0
	arena.camera.offset = Vector2(sin(clock * 107), cos(clock * 89)) * shake
	queue_redraw()

func draw_warning(origin: Vector2, radius: float, progress: float, color: Color) -> void:
	draw_circle(origin, radius, Color(color, 0.07))
	# A broken outer boundary and inward teeth leave the ground readable.
	for index: int in 12:
		var angle: float = index * TAU / 12
		var radial: Vector2 = Vector2.from_angle(angle)
		draw_arc(origin, radius, angle, angle + 0.32, 6, Color(color, 0.8), 2)
		var center: Vector2 = origin + radial * radius * (1.10 - progress * 0.10)
		draw_colored_polygon(PackedVector2Array([center - radial * 6, center + radial.orthogonal() * 3, center - radial.orthogonal() * 3]), Color(color, 0.8))
	draw_arc(origin, maxf(1, radius * (1 - progress)), 0, TAU, 48, Color(color, 0.45), 1)

func draw_lance(origin: Vector2, end: Vector2, width: float, active: bool) -> void:
	var direction: Vector2 = (end - origin).normalized()
	var normal: Vector2 = direction.orthogonal()
	var color: Color = tint()
	draw_colored_polygon(PackedVector2Array([origin - normal * width, end - normal * width, end + normal * width, origin + normal * width]), Color(color, 0.22 if active else 0.09))
	for side: int in [-1, 1]:
		draw_line(origin + normal * width * side, end + normal * width * side, Color(color, 0.8), 2)
	if active:
		var points: PackedVector2Array = []
		for index: int in 16:
			points.append(origin.lerp(end, index / 15.0) + normal * sin(index * 3.1 + clock * 19) * width * 0.6)
		draw_polyline(points, Color(color, 0.4), 12)
		draw_polyline(points, Color("f0f9ff", 0.9), 3)
	else:
		for index: int in 7:
			var point: Vector2 = origin.lerp(end, (index + 0.5) / 7.0)
			draw_polyline(PackedVector2Array([point - direction * 5 - normal * 5, point, point - direction * 5 + normal * 5]), color, 1)

func draw_crescent(origin: Vector2, direction: Vector2, radius: float, progress: float, span: float = 2.2) -> void:
	var angle: float = direction.angle() - span * 0.5 + progress * span
	var polygon: PackedVector2Array = []
	for index: int in 17:
		var ratio: float = index / 16.0
		polygon.append(origin + Vector2.from_angle(angle - ratio * 1.0) * radius)
	for index: int in range(16, -1, -1):
		var ratio: float = index / 16.0
		polygon.append(origin + Vector2.from_angle(angle - ratio * 1.0) * (radius - sin(ratio * PI) * 19 - 2))
	draw_colored_polygon(polygon, Color(tint(), 0.55))
	draw_arc(origin, radius, angle - 0.85, angle, 24, Color("f1f8ff", 0.9), 3)
	for index: int in 5:
		var tip: Vector2 = origin + Vector2.from_angle(angle - index * 0.15) * (radius + 4 + index * 2)
		draw_line(tip, tip - direction.orthogonal() * (5 + index), Color(tint(), 0.65), 1)

func _draw() -> void:
	var color: Color = tint()
	for hazard: Dictionary in hazards:
		if hazard.kind == "lance": draw_lance(hazard.origin, hazard.end, hazard.radius, hazard.hit)
		elif not hazard.hit: draw_warning(hazard.origin, hazard.radius, 1 - hazard.time / hazard.warning, color)
	for hit: Dictionary in impacts:
		var age: float = hit.age / 0.65
		var radius: float = hit.radius * sqrt(age)
		# Radial fissures, a pressure lip and flying chips rather than a solid ball.
		for index: int in 10:
			var direction: Vector2 = Vector2.from_angle(index * TAU / 10 + hit.seed)
			var start: Vector2 = hit.position + direction * radius * 0.25
			var middle: Vector2 = hit.position + direction * radius * 0.55 + direction.orthogonal() * sin(index * 4.7) * 6
			var end: Vector2 = hit.position + direction * radius
			draw_polyline(PackedVector2Array([start, middle, end]), Color(color, (1 - age) * 0.7), 2)
		draw_arc(hit.position, maxf(1, radius), 0, TAU, 64, Color(color, (1 - age) * 0.40), maxf(1, (1 - age) * 7))
		if age < 0.22 and not GamePreferences.current().reduced_flashes:
			draw_star(hit.position, 18 * (1 - age), Color("f3f6e5", 0.8))
	var boss: Recaudador = arena.boss
	if enabled and not arena.ending and boss.health > 0:
		if boss.state == Recaudador.State.CLAW and arena.zone_index in [0, 3]:
			draw_crescent(boss.position, boss.facing, boss.melee_reach(), clampf(1 - boss.timer / (0.3 if boss is ElPrefecto else 0.35), 0, 1), 3.54 if boss is ElPrefecto else 2.2)
		if boss.state == Recaudador.State.CHARGE:
			var normal: Vector2 = boss.charge_direction.orthogonal()
			for side: int in [-1, 1]:
				var point: Vector2 = boss.position + normal * 28 * side
				draw_polyline(PackedVector2Array([point - boss.charge_direction * 85, point - boss.charge_direction * 25 + normal * side * 7, point]), Color(color, 0.55), 3)
	for part: Dictionary in particles:
		var fade: float = 1 - part.age / part.life
		if part.smoke:
			var size: float = part.size * (1 + part.age * 1.8)
			for index: int in 3:
				var point: Vector2 = part.position + Vector2.from_angle(index * 2.1 + part.seed) * size * 0.42
				draw_circle(point.round(), size * 0.65, Color("6e7880", fade * 0.16))
		else:
			var point: Vector2 = part.position.round()
			draw_line(point, point - part.velocity.normalized() * part.size * 3, Color(color, fade * 0.7), part.size)
			draw_rect(Rect2(point - Vector2.ONE, Vector2.ONE * 2), Color("f7eed0", fade))

func draw_star(point: Vector2, radius: float, color: Color) -> void:
	var polygon: PackedVector2Array = []
	for index: int in 16:
		polygon.append(point + Vector2.from_angle(index * TAU / 16) * (radius if index % 2 == 0 else radius * 0.25))
	draw_colored_polygon(polygon, color)
