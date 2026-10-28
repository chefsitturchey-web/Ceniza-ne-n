class_name FieldUnitVisual
extends Node2D
## Siluetas articuladas con paleta compartida; la animación no aplica daño.
var actor: Node2D
var role: String = "ranger"
var elapsed: float = 0
var stride: float = 0
var last_x: float = 0
var moving: bool = false
var death_time: float = 0
const DARK: Color = Color("0b1322")
const STEEL: Color = Color("304356")
const EDGE: Color = Color("8299a8")

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

func plate(rect: Rect2, tint: Color = STEEL) -> void:
	draw_rect(rect.grow(1), DARK)
	draw_rect(rect, tint)
	draw_line(rect.position, rect.position + Vector2(rect.size.x - 1, 0), EDGE, 1)
	if rect.size.x > 6: draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2.ONE), Color("e89e54"))

func joint(a: Vector2, b: Vector2, tint: Color = EDGE) -> void:
	draw_line(a.round(), b.round(), DARK, 5)
	draw_line(a.round(), b.round(), tint, 3)
	draw_circle(a.round(), 2, Color("e89e54"))

func _draw() -> void:
	if not is_instance_valid(actor): return
	var enemy: bool = actor is SiegeEnemy
	var dead: bool = actor.health <= 0 if enemy else actor.hp <= 0
	if dead:
		for part: int in range(6):
			plate(Rect2((part - 3) * minf(6, death_time * 12), -4 - absf(sin(part * 3.0)) * maxf(0, 12 - death_time * 20), 5, 3))
		return
	var tint: Color = Color("dd6482") if enemy else Color("47dacb")
	var facing: float = actor.facing
	var bob: float = roundf(sin(stride * 2) * 1.0) if moving else roundf(sin(elapsed * 2) * 0.5)
	var firing: bool = actor.state == SiegeEnemy.State.ATTACK and actor.cooldown > actor.data.cooldown - 0.15 if enemy else actor.shot > 0
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing, 1))
	if role == "medic":
		var hover: float = roundf(sin(elapsed * 4) * 2)
		for side: int in [-1, 1]:
			joint(Vector2(side * 5, -23 + hover), Vector2(side * 16, -21 + hover))
			plate(Rect2(side * 16 - 5, -27 + hover, 10, 4))
			draw_line(Vector2(side * 16 - 6, -30 + hover), Vector2(side * 16 + 6, -30 + hover), EDGE, 1)
			if int(elapsed * 18) % 2 == 0: draw_rect(Rect2(side * 16 - 3, -22 + hover, 6, 2), tint)
		plate(Rect2(-8, -30 + hover, 16, 13))
		draw_rect(Rect2(-1, -28 + hover, 3, 8), tint)
		draw_rect(Rect2(-4, -25 + hover, 9, 3), tint)
	else:
		var crouch: bool = role == "saboteador"
		for side: int in [-1, 1]:
			var foot: Vector2 = Vector2(side * 7 + (sin(stride + side) * 5 if moving else 0), -2)
			var hip: Vector2 = Vector2(side * 4, -16)
			joint(hip, (hip + foot) * 0.5 + Vector2(3, 0))
			joint((hip + foot) * 0.5 + Vector2(3, 0), foot)
			plate(Rect2(foot - Vector2(4, 2), Vector2(9, 4)))
		plate(Rect2(-9, -30 if crouch else -34, 18, 19), Color("704c43") if enemy else STEEL)
		plate(Rect2(-7, -41 if not crouch else -35, 14, 9))
		draw_rect(Rect2(1, -38 if not crouch else -32, 6, 2), tint)
		for rib: int in range(3): draw_rect(Rect2(-6, -28 + rib * 4, 4, 2), EDGE)
		if role == "artillero":
			plate(Rect2(-15, -36, 9, 23), Color("704c43"))
			plate(Rect2(5 - (2 if firing else 0), -31, 25, 8))
			draw_rect(Rect2(25, -30, 7, 5), DARK)
			for x: int in [10, 15, 20]: draw_rect(Rect2(x, -29, 2, 3), tint)
		elif role == "saboteador":
			joint(Vector2(6, -23), Vector2(14, -14))
			var reach: float = 21 if firing else 16
			joint(Vector2(14, -14), Vector2(reach, -24))
			draw_circle(Vector2(reach, -24), 6, DARK)
			var saw: Vector2 = Vector2.from_angle(elapsed * 14) * 6
			draw_line(Vector2(reach, -24) - saw, Vector2(reach, -24) + saw, tint, 2)
			plate(Rect2(-15, -30, 7, 17))
		else:
			joint(Vector2(-3, -28), Vector2(6, -23))
			plate(Rect2(4 - (2 if firing else 0), -26, 20, 4))
			draw_rect(Rect2(10, -21, 3, 5), DARK)
		if firing and role != "saboteador":
			draw_rect(Rect2(28 if enemy else 24, -29 if enemy else -26, 6, 3), Color("ffce75"))
		if enemy and actor.windup > 0:
			draw_line(Vector2(29, -26), Vector2(220, -26), Color("dd6482", 0.5), 1)
	draw_set_transform(Vector2.ZERO)
