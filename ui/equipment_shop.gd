class_name EquipmentShop
extends CanvasLayer
## Catalog purchases reserve real stock; civilians still travel to collect it.
var district: District
var opened: bool = false
var closed_frame: int = -1
var previous_pause: bool = false
var stock: Label
var detail: RichTextLabel
var purchase: Button
var choices: Array[Button] = []
var selected: int = 0
var clock: float = 0
var glow: ColorRect
var catalog_icons: Texture2D
const LABELS: Array[String] = ["Constructor", "Recuperador", "Tirador", "Guardián", "Técnico", "Médico", "Pala", "Trampa"]
const DESCRIPTIONS: Array[String] = [
	"CONSTRUCTOR\nConstruye, mejora y despeja obstáculos. No necesita un puesto militar.",
	"RECUPERADOR\nRecoge suministros y piezas. Amplía la economía de tu colonia.",
	"TIRADOR\nFusil de defensa y asalto a portales. Los tiradores se reparten entre ambos frentes. Necesita una plaza de cuartel.",
	"GUARDIÁN\nProtege a los tiradores con su escudo y combate cuerpo a cuerpo. Necesita una plaza de cuartel.",
	"TÉCNICO\nRepara el generador y trabaja en los relés de la historia. Necesita un generador operativo.",
	"MÉDICO\nCura al Portador y a sus aliados cercanos. Necesita un puesto médico operativo.",
	"PALA\nEquipo personal del Portador. Permite dar sepultura a los caídos y reducir la presión de la invasión.",
	"TRAMPA\nArma una trampa del perímetro contra las ratas. Requiere un emplazamiento libre."
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 38
	var shade: MenuBackdrop = MenuBackdrop.new()
	shade.size = Vector2(640, 360)
	add_child(shade)
	var panel: Panel = Panel.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.position = Vector2(24, 18)
	panel.size = Vector2(592, 324)
	panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	add_child(panel)
	var title: Label = Label.new()
	title.text = "EL ARSENAL / TALLER DE LA COLONIA"
	title.position = Vector2(18, 13)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("d9bd82"))
	panel.add_child(title)
	stock = Label.new()
	stock.position = Vector2(18, 39)
	stock.add_theme_font_size_override("font_size", 11)
	panel.add_child(stock)
	var grid: GridContainer = GridContainer.new()
	grid.position = Vector2(18, 66)
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)
	catalog_icons = load("res://assets/ui/icons/equipment_catalog.svg")
	for index: int in 8:
		var item: Button = Button.new()
		item.custom_minimum_size = Vector2(142, 40)
		var symbol: AtlasTexture = AtlasTexture.new()
		symbol.atlas = catalog_icons
		symbol.region = Rect2(index * 32, 0, 32, 32)
		item.icon = symbol
		item.expand_icon = true
		item.add_theme_constant_override("icon_max_width", 20)
		item.add_theme_font_size_override("font_size", 10)
		item.text = LABELS[index]
		item.pressed.connect(func() -> void: select_item(index))
		MenuSkin.button(item)
		grid.add_child(item)
		choices.append(item)
	detail = RichTextLabel.new()
	detail.position = Vector2(326, 72)
	detail.size = Vector2(245, 145)
	detail.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	detail.add_theme_font_size_override("normal_font_size", 14)
	detail.add_theme_color_override("default_color", Color("dce5e4"))
	detail.scroll_active = true
	panel.add_child(detail)
	purchase = Button.new()
	purchase.position = Vector2(326, 230)
	purchase.size = Vector2(245, 34)
	purchase.pressed.connect(buy)
	MenuSkin.button(purchase)
	panel.add_child(purchase)
	var hint: Label = Label.new()
	hint.position = Vector2(18, 258)
	hint.text = "Profesiones: los civiles recogen\nsu equipo en este taller."
	hint.add_theme_font_size_override("font_size", 10)
	panel.add_child(hint)
	var back: Button = Button.new()
	back.position = Vector2(420, 280)
	back.size = Vector2(150, 27)
	back.text = "Volver  / Esc"
	back.pressed.connect(close_panel)
	panel.add_child(back)
	glow = ColorRect.new()
	glow.position = Vector2(326, 61)
	glow.size = Vector2(245, 1)
	glow.color = Color("47dacb")
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(glow)
	hide()

func open_panel() -> bool:
	if opened or get_tree().paused or district.core.tier == 0: return false
	previous_pause = get_tree().paused
	opened = true
	get_tree().paused = true
	show()
	select_item(selected)
	choices[selected].grab_focus()
	return true

func select_item(index: int) -> void:
	selected = index
	refresh()

func refresh() -> void:
	stock.text = "%d CHATARRA    /    %d PIEZAS    /    %d CIVILES SIN PROFESIÓN" % [district.bank.scrap, district.bank.parts + district.bank.stored_parts, district.civic.villagers.size()]
	var description: Dictionary = district.civic.describe(-320 - selected) if selected < 6 else district.workshop.describe(-700 - (selected - 6))
	detail.text = DESCRIPTIONS[selected] + "\n\n" + description.text
	var cost: int = CivicSystem.COSTS[selected] if selected < 6 else int(district.workshop.recipes[selected - 6].scrap)
	var parts: int = 0 if selected < 6 else int(district.workshop.recipes[selected - 6].parts)
	purchase.text = "Comprar / %d chatarra" % cost if parts == 0 else "Fabricar / %d + %d piezas" % [cost, parts]
	purchase.disabled = bool(description.get("locked", false)) or district.bank.scrap < cost or district.bank.parts + district.bank.stored_parts < parts
	if selected < 6: purchase.disabled = purchase.disabled or district.civic.tools[selected] >= 4
	elif selected == 6: purchase.disabled = purchase.disabled or district.workshop.shovel_ready
	else: purchase.disabled = purchase.disabled or not district.trap_system.has_unarmed()
	for index: int in choices.size(): choices[index].add_theme_color_override("font_color", Color("ffce75") if index == selected else Color("c0d0d4"))

func buy() -> void:
	if purchase.disabled: return
	var success: bool = district.civic.interact(-320 - selected) if selected < 6 else district.workshop.interact(-700 - (selected - 6))
	if success:
		district.sound.play_cue("upgrade", -10)
		district.expansion.checkpoint()
	refresh()

func close_panel() -> void:
	if not opened: return
	opened = false
	closed_frame = Engine.get_process_frames()
	get_tree().paused = previous_pause
	GamePreferences.current().block_gameplay_input()
	hide()

func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("pause") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not opened: return
	clock += delta
	glow.modulate.a = 0.65 if GamePreferences.current().reduced_flashes else 0.65 + sin(clock * 2) * 0.2
