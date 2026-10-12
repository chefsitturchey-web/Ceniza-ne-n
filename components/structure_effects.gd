class_name StructureEffects
extends DebrisEmitter
## Presentación compartida por obras y núcleo; nunca modifica vida o posición física.
var health: HealthComponent
var texture: Texture2D
var mirrored: bool = false
var elapsed: float = 0.0
var smoke_timer: float = 0.0
var shake: float = 0.0
var cracks: Array[PackedVector2Array] = []

func setup(component: HealthComponent, image: Texture2D, flip: bool = false) -> void:
	health = component
	texture = image
	mirrored = flip
	health.damaged.connect(_damaged)
	health.healed.connect(_healed)
	var size: Vector2 = texture.get_size() if texture != null else Vector2(24, 40)
	for index: int in range(4):
		var start: Vector2 = Vector2(rng.randf_range(-size.x * 0.3, size.x * 0.3), -size.y * (0.25 + index * 0.16)).round()
		cracks.append(PackedVector2Array([start, start + Vector2(3, 4), start + Vector2(-2, 7), start + Vector2(2, 11)]))

func stage(value: int) -> int:
	var ratio: float = float(value) / health.maximum
	return 2 if ratio <= 0.33 else (1 if ratio <= 0.66 else 0)

func _damaged(amount: int, remaining: int) -> void:
	shake = 0.18
	emit_pixels(global_position + Vector2(0, -24), 3, Color("ffce75"))
	if remaining > 0 and (stage(remaining) > stage(remaining + amount) or amount >= health.maximum * 0.2):
		emit_fragments(global_position, texture, rng.randi_range(2, 5), mirrored)
	queue_redraw()

func _healed(_amount: int, _remaining: int) -> void:
	repair_sparks()
	queue_redraw()

func repair_sparks() -> void:
	emit_pixels(global_position + Vector2(0, -24), 5, Color("75fff0"))

func shatter() -> void:
	emit_fragments(global_position, texture, 8, mirrored, true)
	emit_pixels(global_position + Vector2(0, -8), 6, Color("89939e"), true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	shake = maxf(0.0, shake - delta)
	smoke_timer -= delta
	if health != null and health.current > 0 and stage(health.current) == 2 and smoke_timer <= 0.0:
		smoke_timer = 0.3
		emit_pixels(global_position + Vector2(0, -30), 1, Color("89939e"), true)
	queue_redraw()

func _draw() -> void:
	if health == null or health.current <= 0:
		return
	for index: int in range(stage(health.current) * 2):
		draw_polyline(cracks[index], Color("0b1322"), 1.0)
