class_name Blindado
extends SiegeEnemy
## Escudo frontal: los disparos que llegan de frente hacen solo una parte del daño.
## La sobrecarga (disparo eléctrico) y el cuerpo a cuerpo lo atraviesan.

const FRONT_FACTOR: float = 0.25
var shield: ShieldPlate

class ShieldPlate extends Node2D:
	func _draw() -> void:
		var outline: PackedVector2Array = PackedVector2Array([Vector2(-5, -35), Vector2(4, -35), Vector2(7, -30), Vector2(7, -10), Vector2(4, -4), Vector2(-5, -4)])
		draw_colored_polygon(outline, Color("304356"))
		outline.append(outline[0])
		draw_polyline(outline, Color("0b1322"), 1)
		draw_line(Vector2(-3, -34), Vector2(3, -34), Color("b8c4cc"), 1)
		draw_line(Vector2(4, -30), Vector2(4, -10), Color("8299a8"), 2)
		draw_rect(Rect2(-3, -30, 5, 22), Color("182639"))
		for y: int in [-31, -8]:
			draw_rect(Rect2(1, y, 1, 1), Color("ffce75"))
		draw_polyline(PackedVector2Array([Vector2(-2, -24), Vector2(2, -21), Vector2(-2, -18)]), Color("dd6482"), 1)
		draw_line(Vector2(-3, -11), Vector2(0, -14), Color("8299a8"), 1)
		draw_line(Vector2(1, -7), Vector2(4, -9), Color("e89e54"), 1)

func _ready() -> void:
	shield = ShieldPlate.new()
	add_child(shield)
	super._ready()

func _process(_delta: float) -> void:
	shield.position.x = facing * 13.0
	shield.scale.x = facing
	shield.visible = health > 0

func blocks_shot(origin: Vector2) -> bool:
	return signf(origin.x - position.x) == facing

func receive_shot(amount: int, origin: Vector2, electric: bool = false) -> void:
	if not electric and blocks_shot(origin):
		amount = maxi(1, roundi(amount * FRONT_FACTOR))
		if visual.effects.is_inside_tree():
			visual.effects.emit_pixels(global_position + Vector2(facing * 14.0, -18.0), 3, Color("ffce75"))
	hurtbox.receive(amount)
