class_name RatTrap
extends CubeBody

## Craftable trap placed at a fixed spot. Armed traps catch dashing rats once,
## then enter a cooldown before they can trigger again.

var armed: bool = false
var cooldown: float = 0.0

func _ready() -> void:
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
