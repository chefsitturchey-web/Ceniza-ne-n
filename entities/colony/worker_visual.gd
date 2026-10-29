class_name WorkerVisual
extends PersonVisual

var actor: ColonyWorker
var walking: bool = false
var working: bool = false
var elapsed: float = 0.0
var work_timer: float = 0.0
var last_x: float = 0
var fleeing: bool = false

func bind(value: AnimatedSprite2D) -> void:
	setup_person(String(actor.role), value)
	last_x = actor.x

func refresh_state() -> void:
	update_person(0, 1 if walking else 0, working, -1 if sprite.flip_h else 1, false, false, actor.cargo > 0, fleeing)

func _process(delta: float) -> void:
	if sprite == null: return
	var distance: float = absf(actor.x - last_x)
	last_x = actor.x
	update_person(delta, distance, working, -1 if sprite.flip_h else 1, false, false, actor.cargo > 0, fleeing)
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
		return
	draw_rect(Rect2(-5, -19, 10, 19), Color("b075ae"))
	if actor.cargo > 0:
		draw_rect(Rect2(5, -12, 6, 6), Color("8299a8"))
