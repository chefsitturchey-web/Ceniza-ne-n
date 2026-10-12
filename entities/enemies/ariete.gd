class_name Ariete
extends SiegeEnemy
## Especialista en romper murallas: retrocede, carga y hace daño triple a estructuras.

const STRUCTURE_MULTIPLIER: int = 3
const CHARGE_TIME: float = 0.5
const BACKSTEP: float = 6.0

var head: RamHead
var charging: bool = false

class RamHead extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-5, -22, 10, 12), Color("0b1322"))
		draw_rect(Rect2(-4, -21, 8, 10), Color("304356"))
		draw_rect(Rect2(-4, -21, 8, 2), Color("8299a8"))
		draw_rect(Rect2(2, -19, 2, 6), Color("e89e54"))

func _ready() -> void:
	head = RamHead.new()
	add_child(head)
	super._ready()

func _process(_delta: float) -> void:
	head.position.x = facing * 15.0 + (sprite.position.x if sprite != null else 0.0)
	head.scale.x = facing
	head.visible = health > 0

func _physics_process(delta: float) -> void:
	var before: State = state
	super._physics_process(delta)
	if state == State.WINDUP and before != State.WINDUP and target_kind == "wall":
		# Telegrafía la embestida: retrocede antes de golpear.
		windup += CHARGE_TIME
		charging = true
		if sprite != null:
			var base_x: float = sprite.position.x
			var tween: Tween = create_tween()
			tween.tween_property(sprite, "position:x", base_x - facing * BACKSTEP, windup * 0.7)
			tween.tween_property(sprite, "position:x", base_x + facing * 4.0, windup * 0.3)
			tween.tween_property(sprite, "position:x", base_x, 0.15)
	elif state != State.WINDUP:
		charging = false

func land_hit() -> void:
	if target_kind == "wall":
		construction.damage_site(target_index, damage * STRUCTURE_MULTIPLIER)
	else:
		super.land_hit()
