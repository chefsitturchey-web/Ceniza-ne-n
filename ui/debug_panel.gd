class_name GameDebugPanel
extends Control
var tools: Node
var status: Label
var context_label: Label
var inspector: RichTextLabel
var tabs: TabContainer
var first: Button
var hp: SpinBox
var damage: SpinBox
var spawn_count: SpinBox
var day_number: SpinBox
var speed_choice: OptionButton
var boss_choice: OptionButton
var loadout_choice: OptionButton
var toggles: Dictionary = {}
var selectors: Dictionary = {}

func _ready() -> void:
	size = Vector2(640, 360)
	theme = Theme.new()
	theme.default_font = ThemeDB.fallback_font
	theme.default_font_size = 13
	var shade: ColorRect = ColorRect.new()
	shade.size = size
	shade.color = Color("08111c", 0.98)
	add_child(shade)
	var title: Label = text_label(self, "LABORATORIO · F1", 19)
	title.position = Vector2(16, 8)
	title.add_theme_color_override("font_color", Color("47dacb"))
	var close_button: Button = action_button(self, "Cerrar [Esc]", "close")
	close_button.position = Vector2(498, 9)
	close_button.size.x = 126
	context_label = text_label(self, "", 12)
	context_label.position = Vector2(16, 34)
	context_label.add_theme_color_override("font_color", Color("8299a8"))
	tabs = TabContainer.new()
	tabs.position = Vector2(12, 56)
	tabs.size = Vector2(616, 252)
	add_child(tabs)
	build_bosses(page("Jefes"))
	build_player(page("Jugador"))
	build_colony(page("Colonia"))
	build_inspector(page("Inspección"))
	status = text_label(self, "Abre un jefe o una colonia de práctica. Tu guardado se conserva.", 12)
	status.position = Vector2(16, 315)
	status.size = Vector2(608, 40)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("ffce75"))

func page(caption: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = caption
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 9)
	scroll.add_child(margin)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 7)
	margin.add_child(rows)
	return rows

func text_label(parent: Node, text: String, font_size: int = 13) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func row(parent: Node) -> HBoxContainer:
	var line: HBoxContainer = HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	parent.add_child(line)
	return line

func action_button(parent: Node, caption: String, action: String) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(90, 25)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: tools.run_action(action))
	parent.add_child(button)
	return button

func select(parent: Node, entries: Array[String], field: String, initial: int = 0) -> OptionButton:
	var options: OptionButton = OptionButton.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry: String in entries: options.add_item(entry)
	options.select(initial)
	options.item_selected.connect(func(index: int) -> void: tools.set(field, index))
	parent.add_child(options)
	selectors[field] = options
	return options

func number(parent: Node, initial: float, minimum: float, maximum: float) -> SpinBox:
	var spinner: SpinBox = SpinBox.new()
	spinner.min_value = minimum
	spinner.max_value = maximum
	spinner.value = initial
	spinner.custom_minimum_size.x = 85
	parent.add_child(spinner)
	return spinner

func toggle(parent: Node, caption: String, field: String) -> void:
	var button: CheckButton = CheckButton.new()
	button.text = caption
	button.button_pressed = tools.get(field)
	button.toggled.connect(func(active: bool) -> void: tools.set_toggle(field, active))
	parent.add_child(button)
	toggles[field] = button

func build_bosses(rows: VBoxContainer) -> void:
	var line: HBoxContainer = row(rows)
	boss_choice = select(line, ["1 · Recaudador", "2 · Santa Caldera", "3 · Coro Sumergido", "4 · El Prefecto", "5 · Madre Cero"], "selected_boss")
	first = action_button(line, "Entrar", "boss_launch")
	action_button(line, "Reiniciar", "boss_restart")
	line = row(rows)
	text_label(line, "Equipo de prueba")
	loadout_choice = select(line, ["Conservar equipo", "Inicial", "Intermedio", "Máximo"], "loadout")
	action_button(line, "Aplicar equipo", "loadout")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	rows.add_child(grid)
	for pair: Array in [["Fase 1", "phase_one"], ["Fase 2", "phase_two"], ["Abrir núcleo", "expose"], ["Ataque especial", "special"], ["Convocar escoltas", "summon"], ["Limpiar peligros", "clear"], ["Derrotar jefe", "defeat"], ["Volver a mi escena", "return"]]: action_button(grid, pair[0], pair[1])
	line = row(rows)
	text_label(line, "Vida del jefe %")
	hp = number(line, 100, 1, 100)
	action_button(line, "Aplicar vida", "boss_health")
	text_label(rows, "Entrar conserva la escena de fondo; volver la restaura sin dar recompensas.", 12)

func build_player(rows: VBoxContainer) -> void:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	rows.add_child(grid)
	toggle(grid, "Invulnerabilidad [F2]", "god_mode")
	toggle(grid, "Resistencia infinita", "infinite_stamina")
	toggle(grid, "Congelar enemigos [F3]", "freeze_ai")
	toggle(grid, "Colisiones y rutas [F4]", "draw_debug")
	toggle(grid, "Núcleo invulnerable", "core_god")
	toggle(grid, "Congelar reloj de colonia", "freeze_cycle")
	var line: HBoxContainer = row(rows)
	text_label(line, "Velocidad")
	speed_choice = select(line, ["0,25×", "0,5×", "1×", "1,5×", "2×"], "speed_index", 2)
	speed_choice.item_selected.connect(func(index: int) -> void: tools.set_speed(index))
	action_button(line, "Curar / reparar", "heal")
	line = row(rows)
	text_label(line, "Daño de hoja")
	damage = number(line, 50, 1, 2000)
	action_button(line, "Aplicar daño", "damage")
	action_button(rows, "Desactivar ayudas y velocidad normal", "reset")

func build_colony(rows: VBoxContainer) -> void:
	var line: HBoxContainer = row(rows)
	select(line, ["Periferia", "Fundición", "Barrio inundado", "Ciudadela", "Núcleo de la red"], "selected_zone")
	action_button(line, "Nueva colonia de práctica", "colony_launch")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	rows.add_child(grid)
	for pair: Array in [["+500 chatarra", "scrap"], ["+100 experiencia", "xp"], ["Terminar edificios", "build"], ["Día", "day"], ["Noche / oleada", "night"], ["Preparar tren", "train"]]: action_button(grid, pair[0], pair[1])
	line = row(rows)
	text_label(line, "Día nº")
	day_number = number(line, 1, 1, 99)
	select(line, ["Nivel 1", "Nivel 2", "Nivel 3"], "selected_tier", 2)
	action_button(line, "Nivel de estructuras", "tier")
	line = row(rows)
	select(line, ["Constructor", "Recuperador", "Civil", "Tirador", "Guardián", "Técnico", "Médico"], "selected_ally")
	action_button(line, "Añadir aliado", "ally")
	line = row(rows)
	select(line, ["Errante", "Corredor", "Blindado", "Saltador", "Artillero", "Saboteador", "Ariete"], "selected_enemy")
	select(line, ["Izquierda", "Derecha"], "spawn_side")
	spawn_count = number(line, 1, 1, 10)
	action_button(line, "Crear enemigos", "spawn")
	line = row(rows)
	select(line, ["Núcleo", "Taller", "Frente izquierdo", "Frente derecho", "Estación"], "teleport_target")
	action_button(line, "Teletransportar", "teleport")
	action_button(line, "Retirar enemigos", "clear_enemies")

func build_inspector(rows: VBoxContainer) -> void:
	inspector = RichTextLabel.new()
	inspector.custom_minimum_size = Vector2(560, 126)
	inspector.add_theme_font_size_override("normal_font_size", 12)
	rows.add_child(inspector)
	var line: HBoxContainer = row(rows)
	action_button(line, "Guardar informe JSON", "report")
	action_button(line, "Captura sin panel", "capture")
	action_button(line, "Menú principal", "menu")
	text_label(rows, "F1 panel · F2 invulnerabilidad · F3 congelar IA · F4 colisiones y rutas", 12)

func refresh() -> void:
	for field: String in toggles: (toggles[field] as CheckButton).set_pressed_no_signal(tools.get(field))
	for field: String in selectors: (selectors[field] as OptionButton).select(tools.get(field))
