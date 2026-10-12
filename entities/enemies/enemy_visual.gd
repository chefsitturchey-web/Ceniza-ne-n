class_name EnemyVisual
extends EntityVisual

var actor: SiegeEnemy
var effects: DebrisEmitter = DebrisEmitter.new()
var smoke_timer: float = 0.0
var dust_timer: float = 0.0
var walking: bool = false

func hit_effects(dead: bool) -> void:
	if not effects.is_inside_tree():
		return
	var origin: Vector2 = actor.global_position + Vector2(0, -actor.data.provisional_height * 0.6)
	effects.emit_pixels(origin, 4, Color("ffce75"))
	effects.emit_pixels(origin, 2, Color("e89e54"))
	effects.emit_fragments(actor.global_position, null, effects.rng.randi_range(4, 6) if dead else effects.rng.randi_range(1, 3))

func _process(delta: float) -> void:
	dust_timer -= delta
	if sprite != null and walking and actor.health > 0 and sprite.is_playing() and dust_timer <= 0:
		dust_timer = 0.3
		effects.emit_dust(actor.global_position, 1)
	smoke_timer -= delta
	if actor.health > 0 and actor.health <= actor.max_health * 0.35 and smoke_timer <= 0 and effects.is_inside_tree():
		smoke_timer = 0.45
		var origin: Vector2 = actor.global_position + Vector2(0, -actor.data.provisional_height * 0.7)
		effects.emit_pixels(origin, 1, Color("89939e"), true)
		if effects.rng.randf() < 0.35:
			effects.emit_pixels(origin, 2, Color("ffce75"))

func update_state(moving: bool = false) -> void:
	walking = moving
	if sprite != null:
		sprite.modulate = Color(1.6, 1.3, 1.3) if actor.flash > 0.0 else Color.WHITE
	if actor.windup > 0.0:
		play_visual(&"ataque", actor.data.attack_visual_duration)
	elif actor.hurt_remaining > 0.0:
		play_visual(&"daño", actor.data.hurt_duration)
	elif moving:
		actor.attack_visual_remaining = 0.0
		play_visual(actor.data.move_animation)
	elif actor.attack_visual_remaining > 0.0:
		# Si recibió daño, deja terminar la reacción en vez de reiniciar el golpe.
		if sprite != null and sprite.animation != &"ataque":
			play_visual(&"reposo")
	else:
		play_visual(&"reposo")
	queue_redraw()

func _draw() -> void:
	if actor.health <= 0:
		return
	var color: Color = actor.data.provisional_color
	if actor.flash > 0.0:
		color = Color.WHITE
	var height: float = actor.data.provisional_height
	if sprite == null:
		draw_rect(Rect2(-10, -height, 20, height), color)
		draw_rect(Rect2(-7, -height + 5, 14, 6), Color("271d33"))
	draw_rect(Rect2(-12, -height - 7, 24.0 * actor.health / actor.max_health, 3), color)
	if actor.windup > 0.0:
		draw_line(Vector2(0, -height - 13), Vector2(0, -height - 22), Color("ffce75"), 3.0)
