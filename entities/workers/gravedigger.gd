class_name Gravedigger
extends CubeBody

## Walks to the nearest unburied corpse and buries it, but only works during
## the day once the siege is cleared. Otherwise it returns to the core (x=0).

const BURY_RANGE: float = 12.0
const BURY_DURATION: float = 3.0

var corpse_system: CorpseSystem
var director: SiegeDirector
var cycle: CycleSystem
var core: ColonyCore

var speed: float = 60.0
var current: Corpse
var bury_time: float = 0.0
var state: String = "rest"

func _ready() -> void:
	size = Vector2(10, 18)
	fill = Color(0.91, 0.62, 0.35)

func update(delta: float) -> void:
	position.y = GameRules.FLOOR_Y
	var rest_x: float = 0.0 if core == null else core.position.x
	var can_work: bool = cycle != null and cycle.phase == "DÍA" and director != null and director.wave != null and director.is_cleared()
	if not can_work:
		current = null
		bury_time = 0.0
		state = "rest"
		_walk_toward(rest_x, delta)
		return
	if current == null or not is_instance_valid(current) or current.buried:
		current = _nearest_corpse()
		bury_time = 0.0
	if current == null:
		state = "rest"
		_walk_toward(rest_x, delta)
		return
	if absf(current.position.x - position.x) > BURY_RANGE:
		state = "walk"
		_walk_toward(current.position.x, delta)
		return
	state = "bury"
	bury_time += delta
	if bury_time >= BURY_DURATION:
		current.bury()
		current = null
		bury_time = 0.0

func _walk_toward(target_x: float, delta: float) -> void:
	var direction: float = signf(target_x - position.x)
	if direction != 0.0:
		glyph = "◄" if direction < 0.0 else "►"
	position.x = move_toward(position.x, target_x, speed * delta)

func _nearest_corpse() -> Corpse:
	var best: Corpse
	var best_distance: float = INF
	for corpse: Corpse in corpse_system.corpses:
		if not is_instance_valid(corpse) or corpse.buried:
			continue
		var distance: float = absf(corpse.position.x - position.x)
		if distance < best_distance:
			best_distance = distance
			best = corpse
	return best
