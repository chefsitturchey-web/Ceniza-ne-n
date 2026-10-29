class_name RecaudadorBullet
extends CharacterBody2D

var lifetime: float = 6.0
var spent: bool = false
var boundary: PackedVector2Array = []
var theme_index: int = 0
var combat_effects: BossCombatEffects
var trail: PackedVector2Array = []
var trail_clock: float = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(6, 6)
	collider.shape = shape
	add_child(collider)

func _physics_process(delta: float) -> void:
	if spent:
		return
	lifetime -= delta
	trail_clock -= delta
	if trail_clock <= 0:
		trail_clock = 0.018
		trail.append(global_position)
		if trail.size() > 8: trail.remove_at(0)
	var hit: KinematicCollision2D = move_and_collide(velocity * delta)
	if not Rect2(0, 0, 640, 480).has_point(position) or (not boundary.is_empty() and not Geometry2D.is_point_in_polygon(position, boundary)):
		spent = true
	if hit != null:
		var target: TopdownPlayer = hit.get_collider() as TopdownPlayer
		if target != null:
			target.take_damage(12)
		spent = true
	if spent or lifetime <= 0:
		if spent and is_instance_valid(combat_effects): combat_effects.impact(global_position, 20, 0, 6)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var color: Color = BossCombatEffects.COLORS[theme_index]
	if GamePreferences.current().particles:
		for index: int in range(1, trail.size()):
			var alpha: float = float(index) / trail.size()
			draw_line(to_local(trail[index - 1]), to_local(trail[index]), Color(color, alpha * 0.45), 1 + alpha * 3)
	var forward: Vector2 = velocity.normalized()
	var side: Vector2 = forward.orthogonal()
	# Collision remains 6x6; the elongated luminous tail is cosmetic.
	var shell: PackedVector2Array = PackedVector2Array([forward * 5, side * 3, -forward * 7, -side * 3])
	draw_colored_polygon(shell, color.darkened(0.25))
	draw_polyline(shell, Color(color, 0.8), 1)
	draw_line(-forward * 4, forward * 3, Color("f5f9e4"), 2)
	if theme_index == 1:
		draw_line(-forward * 7 + side * 3, -forward * 13, Color(color, 0.7), 2)
	elif theme_index >= 3:
		draw_line(-forward * 7 - side * 2, -forward * 13 + side * 4, Color(color, 0.8), 1)
