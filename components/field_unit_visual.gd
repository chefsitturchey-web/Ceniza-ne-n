class_name FieldUnitVisual
extends Node2D
## El cuerpo y las piernas se animan por separado. El dibujo nunca aplica da?o.
var actor: Node2D
var role: String = "ranger"
var elapsed: float = 0
var stride: float = 0
var last_x: float = 0
var moving: bool = false
var death_time: float = 0

func _ready() -> void:
	last_x = actor.position.x
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	var travel: float = absf(actor.position.x - last_x)
	moving = travel > 0.01
	stride += travel * 0.16
	last_x = actor.position.x
	var dead: bool = actor.health <= 0 if actor is SiegeEnemy else actor.hp <= 0
	death_time = death_time + delta if dead else 0
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(actor): return
	var enemy: bool = actor is SiegeEnemy
	var dead: bool = actor.health <= 0 if enemy else actor.hp <= 0
	var firing: bool = actor.state == SiegeEnemy.State.ATTACK and actor.cooldown > actor.data.cooldown - 0.15 if enemy else actor.shot > 0
	var source: Rect2 = ArtScale.source(GameArt.UNITS, maxi(0, GameArt.UNIT_IDS.find(role)))
	var height: float = 40 if role == "artillero" else (38 if role == "guardian" else ArtScale.PERSON_HEIGHT)
	var frame: Rect2 = ArtScale.grounded(source, height)
	if dead:
		var fall: float = minf(PI * 0.5, death_time * 5)
		draw_set_transform(Vector2(0, -sin(fall) * frame.size.x * 0.5), actor.facing * fall, Vector2(actor.facing, 0.75))
		draw_texture_rect_region(GameArt.UNITS, frame, source, Color(1, 1, 1, maxf(0, 1 - death_time * 0.8)))
		return
	var bob: float = minf(0, roundf(sin(stride * 2))) if moving else 0.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(actor.facing, 1))
	var torso: Rect2 = Rect2(source.position, Vector2(source.size.x, source.size.y * 0.72))
	draw_texture_rect_region(GameArt.UNITS, Rect2(frame.position - Vector2(1 if firing else 0, 0), Vector2(frame.size.x, height * 0.72)), torso)
	for side: int in range(2):
		var leg: Rect2 = Rect2(source.position + Vector2(source.size.x * 0.5 * side, source.size.y * 0.72), Vector2(source.size.x * 0.5, source.size.y * 0.28))
		var step: float = sin(stride + side * PI) if moving else 0.0
		draw_texture_rect_region(GameArt.UNITS, Rect2(frame.position.x + side * frame.size.x * 0.5 + step * 1.5, -height * 0.28 - maxf(0, step) * 2, frame.size.x * 0.5, height * 0.28), leg)
	if firing:
		var color: Color = Color("47dacb") if role in ["medic", "technician"] else Color("ffce75")
		draw_circle(Vector2(23, -27), 4, Color(color, 0.22))
		draw_line(Vector2(22, -27), Vector2(28, -27), color, 2)
	if enemy and actor.windup > 0:
		draw_line(Vector2(25, -27), Vector2(220, -27), Color("dd6482", 0.5), 1)
	draw_set_transform(Vector2.ZERO)
