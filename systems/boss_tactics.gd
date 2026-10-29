class_name BossTactics
extends RefCounted
## Percepción muestreada, memoria corta y elección por utilidad. Nunca lee Input.
var observed_position: Vector2
var observed_velocity: Vector2
var initialized: bool = false
var sample_time: float = 0
var stationary_time: float = 0
var cooldowns: Dictionary = {}
var history: Array[String] = []
var decisions: int = 0
var reason: String = ""
var navigation: AStarGrid2D
var walkable: Array[Vector2i] = []
var route: PackedVector2Array = []
var route_time: float = 0
var route_goal: Vector2

func observe(target: TopdownPlayer, delta: float) -> void:
	for key: String in cooldowns: cooldowns[key] = maxf(0, float(cooldowns[key]) - delta)
	route_time -= delta
	sample_time += delta
	if not initialized:
		observed_position = target.global_position
		initialized = true
	if sample_time < 0.16: return
	var movement: Vector2 = target.global_position - observed_position
	observed_velocity = observed_velocity.lerp((movement / sample_time).limit_length(230), 0.6)
	stationary_time = stationary_time + sample_time if movement.length() < 5 else 0
	observed_position = target.global_position
	sample_time = 0

func predicted(target: TopdownPlayer, seconds: float = 0.3) -> Vector2:
	return target.global_position + observed_velocity * minf(seconds, 0.4)

func choose(scores: Dictionary, delay: float = 4.0) -> String:
	var selected: String = ""
	var best: float = -INF
	for key: String in scores:
		if float(scores[key]) <= 0: continue
		if float(cooldowns.get(key, 0)) > 0: continue
		var score: float = float(scores[key])
		for index: int in range(history.size()):
			if history[index] == key: score -= 2.5 * (index + 1)
		# Deterministic tie variation, independent of the global random generator.
		score += sin(decisions * 2.4 + key.hash() % 31) * 0.35
		if score > best:
			best = score
			selected = key
	if selected.is_empty(): return ""
	decisions += 1
	history.append(selected)
	if history.size() > 3: history.pop_front()
	cooldowns[selected] = delay
	reason = selected
	return selected

func clear_shot(actor: Node2D, point: Vector2) -> bool:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(actor.global_position, point, 1)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func configure_navigation(boundary: PackedVector2Array, obstacles: Array[Rect2], radius: float = 32) -> void:
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(0, 0, 32, 24)
	navigation.cell_size = Vector2(20, 20)
	navigation.offset = Vector2(10, 10)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	walkable.clear()
	for y: int in range(24):
		for x: int in range(32):
			var cell: Vector2i = Vector2i(x, y)
			var at: Vector2 = navigation.get_point_position(cell)
			var blocked: bool = not Geometry2D.is_point_in_polygon(at, boundary)
			for index: int in range(boundary.size()):
				if Geometry2D.get_closest_point_to_segment(at, boundary[index], boundary[(index + 1) % boundary.size()]).distance_to(at) < radius: blocked = true
			for obstacle: Rect2 in obstacles:
				if obstacle.grow(radius).has_point(at): blocked = true
			navigation.set_point_solid(cell, blocked)
			if not blocked: walkable.append(cell)

func nearest_cell(point: Vector2) -> Vector2i:
	var result: Vector2i = Vector2i.ZERO
	var distance: float = INF
	for cell: Vector2i in walkable:
		var candidate: float = navigation.get_point_position(cell).distance_squared_to(point)
		if candidate < distance:
			distance = candidate
			result = cell
	return result

func steer(actor: CharacterBody2D, destination: Vector2, speed: float) -> Vector2:
	if navigation == null or walkable.is_empty(): return (destination - actor.global_position).limit_length(speed)
	if route_time <= 0 or destination.distance_to(route_goal) > 55:
		route_time = 0.35
		route_goal = destination
		route = navigation.get_point_path(nearest_cell(actor.global_position), nearest_cell(destination), true)
	while route.size() > 1 and actor.global_position.distance_to(route[0]) < 19: route.remove_at(0)
	if route.is_empty(): return Vector2.ZERO
	return (route[0] - actor.global_position).limit_length(speed * 0.2) * 5
