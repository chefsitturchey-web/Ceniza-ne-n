class_name Corpse
extends CubeBody

## Fallen ally remains. Decays over days; from stage 2 it spreads poison
## and can request a rat spawn through CorpseSystem.

var kind: StringName = &"ally"
var died_day: int = 0
var stage: int = 0
var buried: bool = false
var cycle: CycleSystem
## Accumulated cooldown (seconds) between rat_spawn_requested emissions.
## Managed by CorpseSystem; a single float, not a Timer node.
var rat_timer: float = 0.0

func _ready() -> void:
	size = Vector2(16, 10)

func refresh_stage(current_day: int) -> void:
	stage = clampi(current_day - died_day, 0, 3)
	match stage:
		0:
			fill = Color(0.51, 0.6, 0.66)
		1:
			fill = Color(0.35, 0.48, 0.35)
		2:
			fill = Color(0.29, 0.42, 0.29)
		_:
			fill = Color(0.18, 0.29, 0.18)

func aura_radius() -> float:
	if stage < 2:
		return 0.0
	return 36.0 if stage == 2 else 56.0

func poison_dps() -> float:
	if stage < 2:
		return 0.0
	return 2.0 if stage == 2 else 4.0

func bury() -> void:
	if buried:
		return
	buried = true
	queue_free()
