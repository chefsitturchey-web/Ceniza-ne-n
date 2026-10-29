class_name FieldUnitVisual
extends PersonVisual
## Secuencias completas; el cuerpo nunca se corta en rectángulos durante el juego.
var actor: Node2D
var role: String = "ranger"
var elapsed: float = 0
var last_x: float = 0
var moving: bool = false
var death_time: float = 0
var previous_hp: int = 0

func _ready() -> void:
	last_x = actor.position.x
	previous_hp = actor.health if actor is SiegeEnemy else actor.hp
	setup_person(role)

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	elapsed += delta
	var travel: float = absf(actor.position.x - last_x)
	moving = travel > 0.01
	last_x = actor.position.x
	var enemy: bool = actor is SiegeEnemy
	var hp: int = actor.health if enemy else actor.hp
	if hp < previous_hp and hp > 0: pulse_hurt()
	previous_hp = hp
	var action: bool = actor.state == SiegeEnemy.State.ATTACK and actor.cooldown > actor.data.cooldown - 0.15 if enemy else actor.shot > 0
	update_person(delta, travel, false, actor.facing, action, hp <= 0)
	death_time = down_time
	queue_redraw()

func _draw() -> void:
	if actor is SiegeEnemy and actor.health > 0 and actor.windup > 0:
		draw_line(Vector2(actor.facing * 25, -27), Vector2(actor.facing * 220, -27), Color("dd6482", 0.5), 1)
