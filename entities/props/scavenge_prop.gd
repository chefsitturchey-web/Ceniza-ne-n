class_name ScavengeProp
extends CubeBody

## Lootable prop placed from zone data. The player holds E nearby to extract
## parts (and sometimes scrap) until its charges run out, then it darkens.

var data: PropData
var charges_left: int = 0
var depleted: bool = false
var elapsed: float = 0
var art: Texture2D

func _process(delta: float) -> void:
	elapsed += delta
	if not depleted: queue_redraw()

func _draw() -> void:
	var texture: Texture2D = art
	var extent: Vector2 = texture.get_size()
	var height: float = 38 if data.id == &"antenna" else (26 if data.id == &"battery" else extent.y)
	var width: float = height * extent.x / extent.y
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.2))
	draw_circle(Vector2.ZERO, width * 0.4, Color(0.03, 0.06, 0.09, 0.5))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(texture, Rect2(-width / 2, -height + 1, width, height), false, Color("53616d") if depleted else Color.WHITE)
	if not depleted:
		var glow: Color = Color("47dacb", 0.45 + sin(elapsed * 2) * 0.25)
		draw_line(Vector2(-width / 2, -height - 3), Vector2(-width / 2 + 5, -height - 3), glow, 1)
		for index: int in charges_left: draw_rect(Rect2(width / 2 + 3, -3 - index * 3, 2, 2), Color("ffce75"))

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path: String = "res://assets/world/salvage/%s.png" % data.id if data.id in [&"battery", &"antenna"] else "res://assets/world/props/%s.png" % data.id
	art = load(path)
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
