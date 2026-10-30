class_name RatTrap
extends CubeBody

## Craftable trap placed at a fixed spot. Armed traps catch dashing rats once,
## then enter a cooldown before they can trigger again.

var armed: bool = false
var cooldown: float = 0.0
var art: Texture2D = load("res://assets/world/salvage/trap.png")

func _draw() -> void:
	var frame: int = 1 if not armed else (2 if cooldown > 0 else 0)
	draw_texture_rect_region(art, Rect2(-16, -21, 32, 24), Rect2(frame * 32, 0, 32, 24), Color.WHITE if armed else Color("53616d"))

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size = Vector2(18, 6)
	glyph = "T"

func refresh_visual() -> void:
	if not armed:
		fill = Color(0.4, 0.4, 0.45)
	else:
		fill = Color(0.91, 0.62, 0.35)
		if cooldown > 0.0:
			fill = fill.darkened(0.4)
	queue_redraw()
