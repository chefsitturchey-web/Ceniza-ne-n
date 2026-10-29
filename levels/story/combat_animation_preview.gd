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
	camera_choice.add_item("Cenital · combate")
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
		sprite.scale = Vector2.ONE
		sprite.position = Vector2(x + 102, y + 68) + CombatSpriteLibrary.offset_for(IDS[index])
		add_child(sprite)
		actors.append(sprite)
		var label: Label = Label.new()
		label.text = "PORTADOR · CENITAL" if index == 0 else IDS[index].to_upper() + " · 1:1"
		label.position = Vector2(x + 8, y + 127)
		add_child(label)
		if index == 0: hero_label = label
	guardian = AnimatedSprite2D.new()
	guardian.sprite_frames = UnitSpriteLibrary.frames("guardian")
	guardian.position = Vector2(163, 115) + UnitSpriteLibrary.OFFSET
	guardian.visible = false
	guardian.play(&"reposo")
	add_child(guardian)
	camera_choice.item_selected.connect(change_camera)
	state_choice.item_selected.connect(func(_index: int) -> void: play_all())
	direction_choice.item_selected.connect(func(_index: int) -> void: play_all())
	play_all()

func change_camera(index: int) -> void:
	camera_choice.select(index)
	var id: String = "portador" if index == 1 else "portador_cenital"
	actors[0].sprite_frames = CombatSpriteLibrary.frames(id)
	actors[0].position = Vector2(110, 115) + CombatSpriteLibrary.offset_for(id)
	hero_label.text = "PORTADOR + GUARDIÁN · 1:1" if index == 1 else "PORTADOR · CENITAL"
	guardian.visible = index == 1
	play_all()

func play_all() -> void:
	var clip: StringName = StringName(STATES[state_choice.selected] + "_" + DIRECTIONS[direction_choice.selected])
	for sprite: AnimatedSprite2D in actors:
		sprite.frame = 0
		sprite.play(clip)
