class_name LevelChoicePanel
extends CanvasLayer
var experience: ExperienceSystem
var opened: bool = false
var chest: bool = false
var rows: VBoxContainer
var heading: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 35
	var shade: MenuBackdrop = MenuBackdrop.new()
	shade.size = Vector2(640, 360)
	add_child(shade)
	var frame: Panel = Panel.new()
	frame.position = Vector2(18, 10)
	frame.size = Vector2(604, 340)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", MenuSkin.panel())
	add_child(frame)
	rows = VBoxContainer.new()
	rows.theme = preload("res://ui/theme.tres")
	rows.position = Vector2(48, 24)
	rows.size = Vector2(544, 312)
	rows.add_theme_constant_override("separation", 12)
	add_child(rows)
	hide()

func open_choices(is_chest: bool) -> void:
	opened = true
	chest = is_chest
	get_tree().paused = true
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	heading = Label.new()
	heading.text = "COFRE DE ÉLITE" if chest else "NIVEL %d · ELIGE UNA MEJORA" % experience.level
	heading.theme_type_variation = &"Title"
	rows.add_child(heading)
	for option: Dictionary in experience.options(chest):
		var button: Button = Button.new()
		button.icon = GameArt.icon(option.id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 44)
		button.add_theme_constant_override("h_separation", 14)
		button.text = option.title + "\n" + option.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(540, 70)
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(select.bind(option))
		UiSound.attach(button)
		rows.add_child(button)
	var hint: Label = Label.new()
	hint.text = "Colonia: enlaces a tropas · Jefes: armas propias · 4 pasivas"
	hint.add_theme_font_size_override("font_size", 10)
	rows.add_child(hint)
	show()
	rows.get_child(1).grab_focus()

func select(option: Dictionary) -> void:
	if not opened or not experience.choose(option, chest): return
	opened = false
	hide()
	get_tree().paused = false
	GamePreferences.current().block_gameplay_input()
	if experience.district.session.save_system != null:
		experience.district.session.save_system.save_game()
