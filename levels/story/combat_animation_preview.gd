extends Control
const IDS: Array[String] = ["portador_cenital", "recaudador", "caldera", "coro", "prefecto", "madre"]
const STATES: Array[String] = ["idle", "walk", "windup", "attack", "shoot", "charge", "exposed", "hurt", "death", "dodge"]
const DIRECTIONS: Array[String] = ["south", "east", "north", "west"]
var actors: Array[AnimatedSprite2D] = []
var state_choice: OptionButton
var direction_choice: OptionButton
var camera_choice: OptionButton
var hero_label: Label
var guardian: AnimatedSprite2D
var turn_preview: CheckButton
var turn_clock: float = 0
var focus_index: int = -1
var focus_backdrop: ColorRect
var focus_sprite: AnimatedSprite2D
var focus_label: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 12
	var backdrop: ColorRect = ColorRect.new()
	backdrop.size = Vector2(640, 360)
	backdrop.color = Color("0b1322")
	add_child(backdrop)
	camera_choice = OptionButton.new()
	camera_choice.position = Vector2(12, 8)
	camera_choice.size.x = 220
	camera_choice.add_item("Superior 3/4 · combate")
	camera_choice.add_item("Lateral · colonia + aliado")
	add_child(camera_choice)
	state_choice = OptionButton.new()
	state_choice.position = Vector2(245, 8)
	state_choice.size.x = 165
	for label: String in ["Reposo", "Caminar", "Preparación", "Ataque", "Disparo", "Carga", "Vulnerable", "Daño", "Muerte", "Esquiva"]: state_choice.add_item(label)
	state_choice.select(1)
	add_child(state_choice)
	direction_choice = OptionButton.new()
	direction_choice.position = Vector2(420, 8)
	direction_choice.size.x = 150
	for label: String in ["Sur", "Este", "Norte", "Oeste"]: direction_choice.add_item(label)
	add_child(direction_choice)
	var hint: Label = Label.new()
	hint.text = "1–6: detalle ampliado · 0: conjunto · las tarjetas conservan la escala del mundo"
	hint.position = Vector2(12, 32)
	hint.add_theme_font_size_override("font_size", 9)
	add_child(hint)
	turn_preview = CheckButton.new()
	turn_preview.text = "Giro"
	turn_preview.position = Vector2(578, 8)
	add_child(turn_preview)
	for index: int in range(IDS.size()):
		var x: float = 8 + (index % 3) * 210
		var y: float = 47 + (index / 3) * 153
		var card: Panel = Panel.new()
		card.position = Vector2(x, y)
		card.size = Vector2(204, 148)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("14222f")
		style.border_width_bottom = 1
		style.border_color = Color("304356")
		card.add_theme_stylebox_override("panel", style)
		add_child(card)
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = CombatSpriteLibrary.frames(IDS[index])
		sprite.scale = Vector2.ONE * CombatSpriteLibrary.scale_for(IDS[index])
		sprite.position = Vector2(x + 102, y + 90) + CombatSpriteLibrary.offset_for(IDS[index]) * sprite.scale
		add_child(sprite)
		actors.append(sprite)
		var label: Label = Label.new()
		label.text = "PORTADOR · 3/4" if index == 0 else IDS[index].to_upper() + " · 1:1"
		label.position = Vector2(x + 8, y + 127)
		add_child(label)
		if index == 0: hero_label = label
	guardian = AnimatedSprite2D.new()
	guardian.sprite_frames = UnitSpriteLibrary.frames("guardian")
	guardian.position = Vector2(163, 115) + UnitSpriteLibrary.OFFSET
	guardian.visible = false
	guardian.play(&"reposo")
	add_child(guardian)
	focus_backdrop = ColorRect.new()
	focus_backdrop.position = Vector2(8, 47)
	focus_backdrop.size = Vector2(624, 305)
	focus_backdrop.color = Color("14222f")
	focus_backdrop.z_index = 10
	focus_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_backdrop.hide()
	add_child(focus_backdrop)
	focus_sprite = AnimatedSprite2D.new()
	focus_sprite.z_index = 11
	focus_sprite.hide()
	add_child(focus_sprite)
	focus_label = Label.new()
	focus_label.position = Vector2(24, 56)
	focus_label.z_index = 12
	focus_label.hide()
	add_child(focus_label)
	camera_choice.item_selected.connect(change_camera)
	state_choice.item_selected.connect(func(_index: int) -> void: play_all())
	direction_choice.item_selected.connect(func(_index: int) -> void: play_all())
	play_all()

func change_camera(index: int) -> void:
	camera_choice.select(index)
	var id: String = "portador" if index == 1 else "portador_cenital"
	actors[0].sprite_frames = CombatSpriteLibrary.frames(id)
	actors[0].scale = Vector2.ONE * CombatSpriteLibrary.scale_for(id)
	actors[0].position = Vector2(110, 152 if index == 1 else 137) + CombatSpriteLibrary.offset_for(id) * actors[0].scale
	guardian.position = Vector2(163, 152) + UnitSpriteLibrary.OFFSET
	hero_label.text = "PORTADOR + GUARDIÁN · 1:1" if index == 1 else "PORTADOR · 3/4"
	guardian.visible = index == 1
	play_all()

func _process(delta: float) -> void:
	if focus_index >= 0:
		var source: AnimatedSprite2D = actors[focus_index]
		var id: String = "portador" if focus_index == 0 and camera_choice.selected == 1 else IDS[focus_index]
		focus_sprite.sprite_frames = source.sprite_frames
		focus_sprite.animation = source.animation
		focus_sprite.frame = source.frame
		focus_sprite.scale = Vector2.ONE * CombatSpriteLibrary.scale_for(id) * (4 if focus_index == 0 else 3)
		focus_sprite.position = Vector2(320, 290) + CombatSpriteLibrary.offset_for(id) * focus_sprite.scale
	if turn_preview == null or not turn_preview.button_pressed: return
	turn_clock += delta
	if turn_clock >= 0.9:
		turn_clock = 0
		direction_choice.select((direction_choice.selected + 1) % DIRECTIONS.size())
		play_all()

func show_detail(index: int) -> void:
	focus_index = index
	focus_backdrop.visible = index >= 0
	focus_sprite.visible = index >= 0
	focus_label.visible = index >= 0
	if index >= 0: focus_label.text = IDS[index].to_upper() + " · DETALLE (0 para volver)"
	_process(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6: show_detail(int(event.keycode - KEY_1))
		elif event.keycode == KEY_0: show_detail(-1)

func play_all() -> void:
	var clip: StringName = StringName(STATES[state_choice.selected] + "_" + DIRECTIONS[direction_choice.selected])
	for sprite: AnimatedSprite2D in actors:
		sprite.frame = 0
		sprite.play(clip)
