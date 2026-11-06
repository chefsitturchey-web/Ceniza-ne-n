class_name FirstStepsHud
extends CanvasLayer
var guide: FirstSteps
var surface: Control
var caption_label: Label
var clock: float = 0
var flash: float = 0
var last_reward: int = 0
## Cartel: margen superior y alto. HudStack apila el resto debajo de banner_bottom().
const BANNER_TOP: float = 7.0
const BANNER_HEIGHT: float = 23.0
const FONT: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const ARROW: Texture2D = preload("res://assets/ui/icons/guide_arrow.svg")
const TOUCH: Texture2D = preload("res://assets/ui/icons/guide_touch.svg")
const WAIT: Texture2D = preload("res://assets/ui/icons/noche.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 7
	surface = Control.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(surface)
	caption_label = Label.new()
	caption_label.add_theme_font_override("font", FONT)
	caption_label.add_theme_font_size_override("font_size", 12)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(caption_label)
	surface.draw.connect(_draw_hint)
	guide.completed.connect(func(_step: int, reward: int) -> void:
		flash = 0.5
		last_reward = reward
		guide.world.play("upgrade"))
	guide.tip_completed.connect(func(_id: String, reward: int) -> void:
		if reward <= 0: return
		flash = 0.5
		last_reward = reward
		guide.world.play("upgrade"))

func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0, flash - delta)
	visible = guide.enabled and not guide.world.session.debug_practice and (guide.active() or flash > 0) and not get_tree().paused and not guide.world.expedition.active and not guide.world.session.finished
	if visible:
		layout_caption()
		surface.queue_redraw()

## Los remapeos largos y los consejos caben en varias lineas si hace falta.
func layout_caption() -> void:
	var text_x: float = 39
	if not TouchOverlay.showing() and not guide.key_action().is_empty():
		text_x = 19 + maxf(20, ceilf(FONT.get_string_size(InputGlyphs.action_name(guide.key_action()), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x) + 8)
	caption_label.position = Vector2(text_x, 10)
	caption_label.size.x = ScreenFit.visible_size(self).x - 8 - text_x
	caption_label.text = guide.caption()
	caption_label.size.y = 0

## Encima del objetivo si se ve; en el borde y de lado si está fuera de pantalla.
## Junto al objetivo se apaga: ya aparece el aviso de interacción y no tapa al jugador.
func _draw_arrow(width: float, color: Color) -> void:
	if guide.tip == "journal":
		var button: Button = guide.world.story.journal_button
		surface.draw_set_transform(button.position + Vector2(button.size.x / 2, button.size.y + 13), PI)
		surface.draw_texture_rect(ARROW, Rect2(-8, -10, 16, 20), false, color)
		surface.draw_set_transform(Vector2.ZERO)
		return
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

## Recuadro de tecla con el nombre dentro; devuelve su borde derecho.
func _draw_keycap(key: String, color: Color) -> float:
	var text_width: float = FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var box: Rect2 = Rect2(12, 10, maxf(20, ceilf(text_width) + 8), 16)
	surface.draw_rect(box, Color("0b1322"))
	surface.draw_rect(box.grow(-1), color, false, 2)
	surface.draw_string(FONT, Vector2(box.position.x + roundf((box.size.x - text_width) / 2), 22), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	return box.end.x

func banner_bottom() -> float:
	return maxf(BANNER_TOP + BANNER_HEIGHT, caption_label.position.y + caption_label.get_combined_minimum_size().y + 4)

func _draw_hint() -> void:
	var width: float = ScreenFit.visible_size(self).x
	var color: Color = Color("ffce75")
	if flash > 0.35 and not GamePreferences.current().reduced_flashes: color = Color.WHITE
	if guide.idle >= 8 and not GamePreferences.current().reduced_flashes:
		color.a = 0.55 + 0.45 * absf(sin(clock * 5))
	surface.draw_rect(Rect2(8, BANNER_TOP, width - 16, banner_bottom() - BANNER_TOP), Color("0b1322"))
	var touch: bool = TouchOverlay.showing()
	var action: String = guide.key_action()
	if action.is_empty():
		surface.draw_texture_rect(WAIT, Rect2(12, 10, 20, 16), false, color)
	elif touch:
		surface.draw_texture_rect(TOUCH, Rect2(12, 10, 20, 16), false, color)
	else:
		# Recuadro de tecla a la medida del nombre: "E", "Y", "RB" o "Cruceta arriba".
		_draw_keycap(InputGlyphs.action_name(action), color)
	caption_label.modulate = color
	_draw_arrow(width, color)
	if flash > 0 and last_reward > 0:
		var reward_y: float = maxf(92, guide.world.hud_stack.bottom + 16)
		var combo: Label = guide.world.rewards_hud.combo_label
		if HudStack.shown(combo): reward_y = maxf(reward_y, combo.position.y + combo.size.y + 16)
		surface.draw_string(FONT, Vector2(width / 2 - 60, reward_y), "+%d chatarra" % last_reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("47dacb"))
