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

## Encima del objetivo si se ve; en el borde y de lado si está fuera de pantalla.
## Junto al objetivo se apaga: ya aparece el aviso de interacción y no tapa al jugador.
func _draw_arrow(width: float, color: Color) -> void:
	var to_canvas: Transform2D = guide.world.get_global_transform_with_canvas()
	var target: Vector2 = guide.target()
	var player: Vector2 = guide.world.player.position
	var gap: float = absf(target.x - player.x)
	if gap < 26: return
	if gap < 60: color.a *= (gap - 26) / 34.0
	var point: Vector2 = to_canvas * (target + Vector2(0, -78))
	var bob: float = roundf(sin(clock * 5) * 3)
	if point.x < 30 or point.x > width - 30:
		var right: bool = point.x > width - 30
		var head: Vector2 = to_canvas * (player + Vector2(0, -40))
		var at: Vector2 = Vector2(width - 18 + bob if right else 18 - bob, clampf(head.y, 60, 280))
		surface.draw_set_transform(at.round(), -PI / 2 if right else PI / 2)
		surface.draw_texture_rect(ARROW, Rect2(-8, -10, 16, 20), false, color)
		surface.draw_set_transform(Vector2.ZERO)
		return
	point = Vector2(roundf(point.x - 8), clampf(point.y, 44, 270) + bob)
	surface.draw_texture_rect(ARROW, Rect2(point, Vector2(16, 20)), false, color)

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
	_draw_arrow(width, color)
	if flash > 0 and last_reward > 0:
		surface.draw_string(FONT, Vector2(width / 2 - 60, 92), "+%d chatarra" % last_reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("47dacb"))
