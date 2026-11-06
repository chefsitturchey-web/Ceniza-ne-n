class_name FirstStepsHud
extends CanvasLayer
var guide: FirstSteps
var surface: Control
var clock: float = 0
var flash: float = 0
var last_reward: int = 0
const FONT: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const ARROW: Texture2D = preload("res://assets/ui/icons/guide_arrow.svg")
const KEY: Texture2D = preload("res://assets/ui/icons/guide_key.svg")
const TOUCH: Texture2D = preload("res://assets/ui/icons/guide_touch.svg")
const WAIT: Texture2D = preload("res://assets/ui/icons/noche.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 7
	surface = Control.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(surface)
	surface.draw.connect(_draw_hint)
	guide.completed.connect(func(_step: int, reward: int) -> void:
		flash = 0.5
		last_reward = reward
		guide.world.play("upgrade"))

func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0, flash - delta)
	visible = guide.enabled and not guide.world.session.debug_practice and (guide.step < FirstSteps.COUNT or flash > 0) and not get_tree().paused and not guide.world.expedition.active and not guide.world.session.finished
	if visible: surface.queue_redraw()

func _draw_hint() -> void:
	var width: float = ScreenFit.visible_size(self).x
	var color: Color = Color("ffce75")
	if flash > 0.35 and not GamePreferences.current().reduced_flashes: color = Color.WHITE
	if guide.idle >= 8 and not GamePreferences.current().reduced_flashes:
		color.a = 0.55 + 0.45 * absf(sin(clock * 5))
	surface.draw_rect(Rect2(8, 7, width - 16, 23), Color("0b1322"))
	var touch: bool = TouchOverlay.showing()
	var waiting: bool = guide.waiting()
	surface.draw_texture_rect(WAIT if waiting else (TOUCH if touch else KEY), Rect2(12, 10, 20, 16), false, color)
	var action: String = ("move_left" if guide.target().x < guide.world.player.position.x else "move_right") if guide.step == 0 else "interact"
	var key: String = KeyRemap.key_name(int(KeyRemap.binding(action).key))
	if not touch and not waiting: surface.draw_string(FONT, Vector2(16, 22), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	surface.draw_string(FONT, Vector2(39, 23), guide.caption(), HORIZONTAL_ALIGNMENT_LEFT, width - 48, 12, color)
	var point: Vector2 = guide.world.get_global_transform_with_canvas() * (guide.target() + Vector2(0, -65))
	point.x = clampf(point.x, 20, width - 36)
	point.y = clampf(point.y, 65, 270)
	point.y += roundf(sin(clock * 5) * 4)
	surface.draw_texture_rect(ARROW, Rect2(point, Vector2(16, 20)), false, color)
	if flash > 0 and last_reward > 0:
		surface.draw_string(FONT, Vector2(width / 2 - 60, 92), "+%d chatarra" % last_reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("47dacb"))
