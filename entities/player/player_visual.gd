class_name PlayerVisual
extends EntityVisual

var actor: Player
var effects: DebrisEmitter = DebrisEmitter.new()
var rest_position: Vector2
var elapsed: float = 0.0
var sweat_timer: float = 0.0
var shake: float = 0.0
var dust_timer: float = 0.0

func movement_dust(delta: float, was_grounded: bool, previous_speed: float) -> void:
	dust_timer = maxf(0.0, dust_timer - delta)
	if actor.health <= 0 or not actor.is_on_floor() or actor.riding:
		return
	var braking: bool = absf(previous_speed) > 10 and (absf(actor.velocity.x) <= 10 or previous_speed * actor.velocity.x < 0)
	if not was_grounded or braking:
		effects.emit_dust(actor.global_position, 5)
	elif absf(actor.velocity.x) > 10 and dust_timer <= 0:
		effects.emit_dust(actor.global_position, 4 if actor.dodge_remaining > 0 else 2)
		dust_timer = 0.07 if actor.dodge_remaining > 0 else 0.15

func bind(value: AnimatedSprite2D) -> void:
	super.bind(value)
	if sprite != null:
		rest_position = sprite.position

func on_damage(_amount: int, _remaining: int) -> void:
	shake = 0.18

func _process(delta: float) -> void:
	elapsed += delta
	shake = maxf(0, shake - delta)
	sweat_timer -= delta
	var tired: bool = actor.health > 0 and actor.stamina < Player.MAX_STAMINA * 0.3 and actor.state in [Player.State.IDLE, Player.State.MOVE] and actor.attack_anim_remaining <= 0
	var offset: Vector2 = Vector2.ZERO
	if actor.riding: offset.y = actor.mobility.rider_offset()
	if tired and actor.state == Player.State.IDLE:
		offset.y += roundf(sin(elapsed * 4))
	if shake > 0 and not GamePreferences.current().reduced_flashes:
		offset.x = 1 if int(elapsed * 45) % 2 == 0 else -1
	if sprite != null:
		sprite.position = rest_position + offset
		if sprite.animation == &"correr":
			sprite.speed_scale = 0.8 if tired else 1.0
	else:
		position = offset
	if tired and sweat_timer <= 0:
		sweat_timer = 0.65
		effects.emit_sweat(actor.global_position + Vector2(actor.facing * 7, -28))


func _draw() -> void:
	if sprite != null:
		sprite.modulate.a = 0.5 if actor.invulnerable > 0.0 and actor.health > 0 else 1.0
		return
	if actor.health <= 0:
		draw_circle(Vector2(0, -8), 7, Color("47dacb"))
		return
	if actor.slash_remaining > 0.0:
		var hit_rect: Rect2 = actor.get_attack_rect()
		hit_rect.position -= actor.global_position
		draw_rect(hit_rect, Color(1.0, 0.8, 0.45, 0.65))
	var color: Color = Color.WHITE if actor.invulnerable > 0.0 else Color("47dacb")
	draw_rect(Rect2(-8, -30, 16, 26), color)
	draw_rect(Rect2(-7, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(2, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(-6, -27, 12, 8), Color("17283b"))
	draw_line(Vector2(0, -23), Vector2(actor.facing * 7, -23), Color("ffce75"), 3.0)
