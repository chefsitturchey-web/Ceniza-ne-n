extends Control
## Galería explícita: no crea colonias, enemigos ni archivos de guardado.
const TITLES: Array[String] = ["Tirador", "Guardián", "Técnico", "Médica", "Constructor", "Recuperador", "Superviviente", "Artillero", "Saboteador"]
var people: Array[PersonVisual] = []
var states: OptionButton
var flip: CheckButton
var elapsed: float = 0
var freeze: CheckButton

func _ready() -> void:
	var background: ColorRect = ColorRect.new()
	background.size = Vector2(640, 360)
	background.color = Color("0b1322")
	add_child(background)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(14, 10)
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	states = OptionButton.new()
	for state: String in UnitSpriteLibrary.frames("ranger").get_animation_names(): states.add_item(state)
	states.item_selected.connect(func(_index: int) -> void: play_selected())
	row.add_child(states)
	flip = CheckButton.new()
	flip.text = "Mirar a la izquierda"
	flip.toggled.connect(func(_value: bool) -> void: play_selected())
	row.add_child(flip)
	freeze = CheckButton.new()
	freeze.text = "Pausar"
	freeze.toggled.connect(func(value: bool) -> void:
		for person: PersonVisual in people:
			if value: person.sprite.pause()
			else: person.sprite.play())
	row.add_child(freeze)
	for index: int in range(UnitSpriteLibrary.ROLES.size()):
		var column: int = index % 3
		var line: int = index / 3
		var ground: ColorRect = ColorRect.new()
		ground.position = Vector2(12 + column * 210, 112 + line * 93)
		ground.size = Vector2(196, 2)
		ground.color = Color("304356")
		add_child(ground)
		var person: PersonVisual = PersonVisual.new()
		add_child(person)
		person.position = Vector2(110 + column * 210, 112 + line * 93)
		person.scale = Vector2(2, 2)
		person.setup_person(UnitSpriteLibrary.ROLES[index])
		people.append(person)
		var label: Label = Label.new()
		label.position = Vector2(12 + column * 210, 116 + line * 93)
		label.size = Vector2(196, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = TITLES[index]
		label.add_theme_font_size_override("font_size", 12)
		add_child(label)
	var note: Label = Label.new()
	note.position = Vector2(16, 338)
	note.text = "Galería de animación · LibreSprite · no modifica la partida"
	note.add_theme_font_size_override("font_size", 11)
	add_child(note)
	play_selected()

func play_selected() -> void:
	for person: PersonVisual in people:
		person.choose(states.get_item_text(states.selected))
		person.sprite.set_frame_and_progress(0, 0)
		person.sprite.flip_h = flip.button_pressed
		if freeze.button_pressed: person.sprite.pause()
	elapsed = 0

func _process(delta: float) -> void:
	if freeze == null or freeze.button_pressed: return
	elapsed += delta
	if elapsed > 2.0: play_selected()
