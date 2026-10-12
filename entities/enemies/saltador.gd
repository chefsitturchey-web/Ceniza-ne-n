class_name Saltador
extends SiegeEnemy
## Al llegar a la primera muralla en pie se agacha y salta por encima una sola vez.

const CROUCH_TIME: float = 0.4
const JUMP_TIME: float = 0.7
const JUMP_HEIGHT: float = 46.0
## Distancia detrás de la muralla donde aterriza.
const LAND_OFFSET: float = 34.0

var jumped: bool = false
var jumps: int = 0
var crouch: float = 0.0
var airborne: float = 0.0
var jump_from: float = 0.0
var jump_to: float = 0.0
var ground_y: float = 0.0
var rest_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	super._ready()
	if sprite != null:
		rest_scale = sprite.scale

func _physics_process(delta: float) -> void:
	if session == null or health <= 0 or session.finished:
		super._physics_process(delta)
		return
	if crouch > 0.0:
		crouch = maxf(0.0, crouch - delta)
		if crouch == 0.0:
			airborne = JUMP_TIME
			if sprite != null:
				sprite.scale = rest_scale
		return
	if airborne > 0.0:
		airborne = maxf(0.0, airborne - delta)
		var progress: float = 1.0 - airborne / JUMP_TIME
		position.x = lerpf(jump_from, jump_to, progress)
		position.y = ground_y - sin(progress * PI) * JUMP_HEIGHT
		if airborne == 0.0:
			position.y = ground_y
			jumped = true
			jumps += 1
			if visual.effects.is_inside_tree():
				visual.effects.emit_dust(global_position, 5)
		return
	if not jumped:
		var index: int = find_wall()
		if index >= 0:
			var wall_x: float = construction.sites[index].x
			jump_from = position.x
			jump_to = wall_x - signf(wall_x) * LAND_OFFSET
			ground_y = position.y
			crouch = CROUCH_TIME
			face_toward(0.0)
			if sprite != null:
				sprite.scale = Vector2(rest_scale.x, rest_scale.y * 0.8)
			return
	super._physics_process(delta)
