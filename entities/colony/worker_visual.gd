class_name WorkerVisual
extends EntityVisual

var actor: ColonyWorker
var effects: DebrisEmitter = DebrisEmitter.new()
var walking: bool = false
var working: bool = false
var elapsed: float = 0.0
var work_timer: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	work_timer -= delta
	if working and work_timer <= 0:
		work_timer = 0.35
		var direction: float = -1.0 if sprite != null and sprite.flip_h else 1.0
		var origin: Vector2 = actor.global_position + Vector2(direction * 10, -8)
		if actor.role == &"collector":
			effects.emit_dust(origin, 2)
		else:
			effects.emit_pixels(origin + Vector2(0, -10), 2, Color("ffce75"))
	queue_redraw()

func _draw() -> void:
	if sprite != null:
		if actor.cargo > 0:
			draw_set_transform(Vector2(0, roundf(sin(elapsed * 10)) if walking else 0))
			draw_rect(Rect2(-5, -42, 10, 8), Color("0b1322"))
			draw_rect(Rect2(-4, -41, 8, 6), Color("8299a8"))
			draw_line(Vector2(-3, -39), Vector2(3, -39), Color("b075ae"), 2)
			draw_line(Vector2(0, -41), Vector2(0, -35), Color("304356"), 1)
		return
	draw_rect(Rect2(-5, -19, 10, 19), Color("b075ae"))
	if actor.cargo > 0:
		draw_rect(Rect2(5, -12, 6, 6), Color("8299a8"))
