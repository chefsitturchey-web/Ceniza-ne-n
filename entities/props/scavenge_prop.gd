class_name ScavengeProp
extends CubeBody

## Lootable prop placed from zone data. The player holds E nearby to extract
## parts (and sometimes scrap) until its charges run out, then it darkens.

var data: PropData
var charges_left: int = 0
var depleted: bool = false

func _ready() -> void:
	size = data.size
	fill = data.fill
	glyph = "?"
	charges_left = data.charges

func extract() -> bool:
	if depleted:
		return false
	charges_left -= 1
	if charges_left <= 0:
		depleted = true
		fill = fill * 0.4
		queue_redraw()
	return true
