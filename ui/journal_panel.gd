class_name JournalPanel
extends CanvasLayer
var story: StoryDirector
var opened: bool = false
var closed_frame: int = -1
var page: RichTextLabel
var previous: Button
var next: Button
var chapter_index: int = 0
var scene_picker: OptionButton
var scene_sections: Array[String] = []

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
	page.custom_minimum_size = Vector2(576, 210)
	page.add_theme_font_size_override("normal_font_size", 12)
	page.add_theme_constant_override("normal_line_separation", 5)
	rows.add_child(page)
	var scenes: HBoxContainer = HBoxContainer.new()
	scenes.add_theme_constant_override("separation", 12)
	rows.add_child(scenes)
	scene_picker = OptionButton.new()
	scene_picker.custom_minimum_size = Vector2(280, 25)
	scenes.add_child(scene_picker)
	var replay_button: Button = Button.new()
	replay_button.text = "Ver conversación"
	replay_button.pressed.connect(replay_scene)
	UiSound.attach(replay_button)
	scenes.add_child(replay_button)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	rows.add_child(buttons)
	previous = Button.new()
	previous.text = "Anterior"
	previous.pressed.connect(func() -> void: chapter_index -= 1; refresh())
	UiSound.attach(previous)
	buttons.add_child(previous)
	next = Button.new()
	next.text = "Siguiente"
	next.pressed.connect(func() -> void: chapter_index += 1; refresh())
	UiSound.attach(next)
	buttons.add_child(next)
	var close: Button = Button.new()
	close.text = "Volver · L / Esc"
	close.pressed.connect(close_panel)
	UiSound.attach(close)
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
	scene_sections.assign(["opening"])
	for index: int in range(3):
		if not current or story.completed[index]: scene_sections.append(["rescue", "relay", "convoy"][index])
	if not current: scene_sections.append_array(["encounter", "ending"])
	scene_picker.clear()
	for section: String in scene_sections: scene_picker.add_item(VisualStory.TITLES[section])

func replay_scene() -> void:
	if story.novel.opened or scene_picker.selected < 0: return
	hide()
	if story.replay(chapter_index, scene_sections[scene_picker.selected]):
		story.novel.finished.connect(func(_id: String) -> void:
			if opened:
				show()
				scene_picker.grab_focus(), CONNECT_ONE_SHOT)
	else: show()

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
	closed_frame = Engine.get_process_frames()
	hide()
	get_tree().paused = false
	GamePreferences.current().block_gameplay_input()

func _input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if story.novel.opened: return
	if opened and (event.is_action_pressed("journal") or event.is_action_pressed("pause")) and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
