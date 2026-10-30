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
var art: Texture2D = load("res://assets/characters/pests/rat.png")
var elapsed: float = 0
var previous_x: float = 0
var facing_left: bool = false

func _process(delta: float) -> void:
	elapsed += delta
	if absf(position.x - previous_x) > 0.1: facing_left = position.x < previous_x
	previous_x = position.x
	queue_redraw()

func _draw() -> void:
	var frame: int = int(elapsed * (15 if state in [State.DART, State.FLEE] else 5)) % 8
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if facing_left else 1, 1))
	draw_texture_rect_region(art, Rect2(-16, -18, 32, 24), Rect2(frame * 32, 0, 32, 24))
	draw_set_transform(Vector2.ZERO)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size = Vector2(6, 4)
	fill = Color(0.44, 0.33, 0.26)
	z_index = 2
	add_to_group(GameRules.PESTS)
	position.y = GameRules.FLOOR_Y
