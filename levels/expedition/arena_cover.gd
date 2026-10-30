class_name ArenaCover
extends StaticBody2D
## Destruction keeps a short-lived wreck; collision and navigation disappear together.
signal broken
var health: int = 100
var maximum: int = 100
var extent: Vector2 = Vector2(34, 34)
var debris: DebrisEmitter
var flash: float = 0

func _ready() -> void:
	debris = DebrisEmitter.new()
	add_child(debris)

func receive_damage(amount: int) -> void:
	if health <= 0 or amount <= 0: return
	health = maxi(0, health - amount)
	flash = 0.15
	debris.emit_pixels(global_position, 5, Color("ffce75"))
	if health == 0:
		collision_layer = 0
		(get_child(0) as CollisionShape2D).set_deferred("disabled", true)
		debris.emit_fragments(global_position, null, 14)
		if get_child_count() > 1: (get_child(1) as Sprite2D).modulate = Color("4e5a62", 0.4)
		broken.emit()
	queue_redraw()

func _process(delta: float) -> void:
	flash = maxf(0, flash - delta)
	queue_redraw()

func _draw() -> void:
	if health == maximum: return
	var color: Color = Color("ffce75") if flash > 0 else Color("080e17")
	for index: int in range(1 + int(3.0 * (1.0 - float(health) / maximum))):
		var x: float = (index - 1) * extent.x * 0.18
		draw_polyline(PackedVector2Array([Vector2(x - 4, -extent.y * 0.4), Vector2(x + 3, -3), Vector2(x - 2, 4), Vector2(x + 5, extent.y * 0.4)]), color, 1.5)
