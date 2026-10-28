class_name JournalPanel
extends CanvasLayer
var story: StoryDirector
var opened: bool = false
var page: RichTextLabel
var previous: Button
var next: Button
var chapter_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 32
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(640, 360)
	shade.color = Color("0b1322", 0.98)
	add_child(shade)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.position = Vector2(32, 15)
	rows.size = Vector2(576, 330)
	rows.add_theme_constant_override("separation", 10)
	add_child(rows)
	var title: Label = Label.new()
	title.text = "DIARIO DEL ENLACE"
	title.theme_type_variation = &"Title"
	rows.add_child(title)
	page = RichTextLabel.new()
	page.bbcode_enabled = true
	page.custom_minimum_size = Vector2(576, 246)
	page.add_theme_font_size_override("normal_font_size", 12)
	page.add_theme_constant_override("normal_line_separation", 5)
	rows.add_child(page)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	rows.add_child(buttons)
	previous = Button.new()
	previous.text = "Anterior"
	previous.pressed.connect(func() -> void: chapter_index -= 1; refresh())
	buttons.add_child(previous)
	next = Button.new()
	next.text = "Siguiente"
	next.pressed.connect(func() -> void: chapter_index += 1; refresh())
	buttons.add_child(next)
	var close: Button = Button.new()
	close.text = "Volver · L / Esc"
	close.pressed.connect(close_panel)
	buttons.add_child(close)
	hide()

func refresh() -> void:
	var data: Dictionary = CampaignStory.chapter(chapter_index)
	var current: bool = chapter_index == story.district.zone_index
	page.text = "[color=#47dacb]" + data.title + "[/color]\n\n" + data.voice + ": " + data.opening
	if current: page.text += "\n\n[color=#ffce75]OBJETIVO: " + story.objective() + "[/color]"
	for index: int in range(3):
		if not current or story.completed[index]: page.text += "\n\n" + String(data[["rescue", "relay", "convoy"][index]])
	if not current: page.text += "\n\n" + data.ending
	page.scroll_to_line(0)
	previous.disabled = chapter_index <= 0
	next.disabled = chapter_index >= story.district.zone_index

func open_panel() -> void:
	if get_tree().paused or story.district.expedition.active or story.district.session.finished: return
	chapter_index = story.district.zone_index
	refresh()
	opened = true
	show()
	get_tree().paused = true
	if not previous.disabled: previous.grab_focus()
	else: next.get_parent().get_child(2).grab_focus()

func close_panel() -> void:
	if not opened: return
	opened = false
	hide()
	get_tree().paused = false
	GamePreferences.current().block_gameplay_input()

func _input(event: InputEvent) -> void:
	if opened and (event.is_action_pressed("journal") or event.is_action_pressed("pause")) and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
