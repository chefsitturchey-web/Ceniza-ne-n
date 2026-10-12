class_name RecaudadorBullet
extends CharacterBody2D

var lifetime: float = 6.0
var spent: bool = false

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
	var hit: KinematicCollision2D = move_and_collide(velocity * delta)
	if hit != null:
		var target: TopdownPlayer = hit.get_collider() as TopdownPlayer
		if target != null:
			target.take_damage(12)
		spent = true
	if spent or lifetime <= 0:
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-3, -3, 6, 6), Color("e99b43"))
	draw_rect(Rect2(-1, -2, 2, 4), Color("ffdf8e"))
