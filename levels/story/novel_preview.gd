extends Control
var novel: NovelPanel
var chapter: OptionButton
var section: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var background: ColorRect = ColorRect.new()
	background.size = Vector2(640, 360)
	background.color = Color("0b1322")
	add_child(background)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.position = Vector2(92, 68)
	rows.size = Vector2(456, 220)
	rows.add_theme_constant_override("separation", 14)
	add_child(rows)
	var title: Label = Label.new()
	title.text = "RECUERDOS DEL ENLACE"
	title.theme_type_variation = &"Title"
	rows.add_child(title)
	chapter = OptionButton.new()
	for data: Dictionary in CampaignStory.CHAPTERS: chapter.add_item(data.title)
	rows.add_child(chapter)
	section = OptionButton.new()
	for id: String in VisualStory.SECTIONS: section.add_item(VisualStory.TITLES[id])
	rows.add_child(section)
	var play: Button = Button.new()
	play.text = "Ver escena"
	play.pressed.connect(play_selected)
	rows.add_child(play)
	var note: Label = Label.new()
	note.text = "Galería de práctica. No guarda en la campaña."
	note.add_theme_font_size_override("font_size", 10)
	rows.add_child(note)
	novel = NovelPanel.new()
	add_child(novel)
	call_deferred("play_selected")

func play_selected() -> void:
	novel.play(VisualStory.scene(chapter.selected, VisualStory.SECTIONS[section.selected]))
