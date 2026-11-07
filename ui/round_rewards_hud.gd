class_name RoundRewardsHud
extends CanvasLayer
var progress: RoundEngagement
var goal_label: Label
var combo_label: Label
var toast: Label
var toast_left: float = 0
var combo_left: float = 0
var notices: Array[String] = []
var result_panel: PanelContainer
var present_results: bool = true
var result_open: bool = false
var star_row: HBoxContainer
const STAR: Texture2D = preload("res://assets/ui/icons/reward_star.svg")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	goal_label = label(Vector2(10, 35), 10)
	combo_label = label(Vector2(280, 65), 30)
	combo_label.add_theme_font_override("font", preload("res://assets/fonts/Micro5-Regular.ttf"))
	toast = label(Vector2(160, 115), 12)
	progress.combo_changed.connect(func(multiplier: int) -> void:
		combo_label.text = "x%d" % multiplier if multiplier > 1 else ""
		combo_left = 0.8)
	progress.achievement_unlocked.connect(func(title: String) -> void: notices.append(title))
	progress.result_ready.connect(func(stats: Dictionary) -> void: show_result.call_deferred(stats))
	progress.goal_changed.connect(func() -> void: goal_label.text = progress.goal())
	goal_label.text = progress.goal()

func label(at: Vector2, font_size: int) -> Label:
	var item: Label = Label.new()
	item.theme = preload("res://ui/theme.tres")
	item.position = at
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color("ffce75"))
	add_child(item)
	return item

func _process(delta: float) -> void:
	var playing: bool = progress.enabled and not progress.world.session.debug_practice and not get_tree().paused and not progress.world.expedition.active and not progress.world.session.finished
	goal_label.visible = playing and progress.night_active
	combo_label.visible = playing
	toast.visible = playing
	if not playing: return
	combo_left = maxf(0, combo_left - delta)
	combo_label.modulate.a = minf(1, combo_left * 4)
	toast_left = maxf(0, toast_left - delta)
	if toast_left == 0 and not notices.is_empty():
		toast.text = "Logro: " + notices.pop_front()
		toast_left = 2.2
		progress.world.play("upgrade")
	toast.modulate.a = minf(1, toast_left * 3)

func show_result(stats: Dictionary) -> void:
	if not present_results or not progress.enabled or result_open or not is_inside_tree(): return
	if progress.world.expedition.active: return
	# Esperar a que cualquier menú ya abierto termine sin robarle la pausa.
	if get_tree().paused:
		get_tree().create_timer(0.15).timeout.connect(func() -> void: show_result(stats))
		return
	result_open = true
	get_tree().paused = true
	result_panel = PanelContainer.new()
	result_panel.theme = preload("res://ui/theme.tres")
	result_panel.position = Vector2((ScreenFit.visible_size(self).x - 320) / 2, 70)
	result_panel.custom_minimum_size = Vector2(320, 210)
	add_child(result_panel)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 9)
	result_panel.add_child(rows)
	var title: Label = Label.new()
	title.text = "AMANECER" if stats.dawn else ("VICTORIA" if stats.victory else "OTRA OPORTUNIDAD")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)
	star_row = HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(star_row)
	for index: int in 3:
		var star: TextureRect = TextureRect.new()
		star.texture = STAR
		star.custom_minimum_size = Vector2(24, 24)
		star.modulate = Color.WHITE if index < int(stats.stars) else Color("304356")
		star_row.add_child(star)
	var summary: Label = Label.new()
	summary.text = "Bajas %d   Cadena %d\nChatarra +%d   Récord %d" % [stats.kills, stats.combo, stats.scrap, stats.record]
	if stats.goal: summary.text += "\nMeta cumplida: +25"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(summary)
	var retry: Button = Button.new()
	retry.text = "Otra vez"
	retry.custom_minimum_size.y = 34
	retry.pressed.connect(progress.world.session.restart)
	rows.add_child(retry)
	retry.grab_focus()
	if stats.dawn:
		var next: Button = Button.new()
		next.text = "Seguir"
		next.pressed.connect(close_result)
		rows.add_child(next)
		# El amanecer conserva el avance; Otra vez carga ese checkpoint.
		next.grab_focus()

func close_result() -> void:
	if not result_open: return
	result_open = false
	result_panel.queue_free()
	get_tree().paused = false
	GamePreferences.current().block_gameplay_input()
