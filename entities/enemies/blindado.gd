class_name Blindado
extends SiegeEnemy
## Escudo frontal: los disparos que llegan de frente hacen solo una parte del daño.
## La sobrecarga (disparo eléctrico) y el cuerpo a cuerpo lo atraviesan.

const FRONT_FACTOR: float = 0.25
var shield: ShieldPlate

class ShieldPlate extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-3, -30, 6, 26), Color("0b1322"))
		draw_rect(Rect2(-2, -29, 4, 24), Color("8299a8"))
		draw_line(Vector2(-1, -28), Vector2(-1, -7), Color("b8c4cc"))
		for y: int in [-27, -9]:
			draw_rect(Rect2(1, y, 1, 1), Color("ffce75"))
		draw_rect(Rect2(-2, -21, 2, 7), Color("182639"))
		draw_line(Vector2(-2, -22), Vector2(1, -19), Color("dd6482"), 1)

func _ready() -> void:
	shield = ShieldPlate.new()
	add_child(shield)
	super._ready()

func _process(_delta: float) -> void:
	shield.position.x = facing * 13.0
	shield.visible = health > 0

func blocks_shot(origin: Vector2) -> bool:
	return signf(origin.x - position.x) == facing

func receive_shot(amount: int, origin: Vector2, electric: bool = false) -> void:
	if not electric and blocks_shot(origin):
		amount = maxi(1, roundi(amount * FRONT_FACTOR))
		if visual.effects.is_inside_tree():
			visual.effects.emit_pixels(global_position + Vector2(facing * 14.0, -18.0), 3, Color("ffce75"))
	hurtbox.receive(amount)
