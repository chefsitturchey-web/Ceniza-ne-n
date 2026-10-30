class_name SewerRat
extends CubeBody

## Skittish pest that emerges from a corpse, darts toward a powered turret,
## hides while it chews the wiring, and flees after shorting a few machines.

enum State { EMERGE, DART, HIDE, FLEE }

var state: int = State.EMERGE
var speed: float = 260.0
var chew_time: float = 0.0
var chews: int = 0
var target_site: ConstructionSite
var exit_x: float = 0.0

func _ready() -> void:
	size = Vector2(6, 4)
	fill = Color(0.44, 0.33, 0.26)
	z_index = 2
	add_to_group(GameRules.PESTS)
	position.y = GameRules.FLOOR_Y
