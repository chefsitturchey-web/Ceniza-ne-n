class_name ClinicPanel
extends CanvasLayer
## Panel contextual; abrirlo detiene el tiempo y cerrarlo devuelve el control.
var district: Node2D
var opened: bool = false
var closed_frame: int = -1
var panel: PanelContainer
var status: Label
var buttons: Array[Button] = []
var module_rows: Dictionary = {}
var tabs: TabContainer
var passive_buttons: Dictionary = {}
const TITLES: Array[String] = ["FILO DE INDUCCIÓN", "DRON PERFORADOR", "CAPACITOR SINÁPTICO"]
const DETAILS: Array[String] = ["+10 daño de hoja por rango; solo jefes", "+4 daño de dron ante jefes; intervalo -10%", "+5 resistencia por segundo y por rango"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.9)
	shade.size = Vector2(640, 360)
	add_child(shade)
	panel = PanelContainer.new()
	panel.theme = preload("res://ui/theme.tres")
	panel.position = Vector2(66, 35)
	panel.size = Vector2(508, 290)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)
	var title: Label = Label.new()
	title.text = "CLÍNICA DE ENLACE"
	title.theme_type_variation = &"Title"
	rows.add_child(title)
	status = Label.new()
	rows.add_child(status)
	tabs = TabContainer.new()
	tabs.custom_minimum_size.y = 166
	rows.add_child(tabs)
	var implants: VBoxContainer = VBoxContainer.new()
	implants.name = "Implantes"
	implants.add_theme_constant_override("separation", 6)
	tabs.add_child(implants)
	for index: int in range(NeuralSystem.IDS.size()):
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_install.bind(NeuralSystem.IDS[index]))
		implants.add_child(button)
		buttons.append(button)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Equipo"
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var equipment_rows: VBoxContainer = VBoxContainer.new()
	equipment_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(equipment_rows)
	for data: ModuleData in ModuleSystem.DATA:
		var title_label: Label = Label.new()
		title_label.add_theme_color_override("font_color", Color("47dacb"))
		equipment_rows.add_child(title_label)
		var detail: Label = Label.new()
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size.x = 410
		equipment_rows.add_child(detail)
		var actions: GridContainer = GridContainer.new()
		actions.columns = 2
		equipment_rows.add_child(actions)
		var controls: Dictionary = {"title": title_label, "detail": detail}
		for pair: Array in [["upgrade", "Mejorar · 1 punto"], ["equip", "Equipar"], ["passive", data.passive_title], ["evolve", "Evolucionar"]]:
			var button: Button = Button.new()
			button.text = pair[1]
			button.pressed.connect(_equipment_action.bind(data.id, pair[0]))
			actions.add_child(button)
			controls[pair[0]] = button
		module_rows[data.id] = controls
	var passive_grid: GridContainer = GridContainer.new()
	passive_grid.columns = 2
	equipment_rows.add_child(passive_grid)
	for id: String in ModuleSystem.PASSIVE_IDS:
		var toggle: Button = Button.new()
		toggle.pressed.connect(_toggle_passive.bind(id))
		passive_grid.add_child(toggle)
		passive_buttons[id] = toggle
	var close: Button = Button.new()
	close.text = "Volver  [Esc / Start]"
	close.pressed.connect(close_panel)
	rows.add_child(close)
	hide()

func open_panel() -> bool:
	if opened or district.cycle.phase != "DÍA" or district.session.finished or district.player.health <= 0 or get_tree().paused:
		return false
	opened = true
	get_tree().paused = true
	show()
	refresh()
	if tabs.current_tab == 0:
		buttons[0].grab_focus()
	else:
		tabs.get_tab_bar().grab_focus()
	return true

func refresh() -> void:
	var neural: NeuralSystem = district.neural
	status.text = "Nv. %d · Datos %d/%d · Núcleos %d\nLas mejoras se eligen al subir de nivel." % [district.experience.level, district.experience.xp, district.experience.needed(), district.modules.cores]
	for index: int in range(buttons.size()):
		var rank: int = neural.ranks[NeuralSystem.IDS[index]]
		buttons[index].disabled = true
		buttons[index].text = "%s   %d/3\n%s%s" % [TITLES[index], rank, DETAILS[index], "  [MÁX.]" if rank == 3 else ""]
	for data: ModuleData in ModuleSystem.DATA:
		var gear: ModuleSystem = district.modules
		var controls: Dictionary = module_rows[data.id]
		controls.title.text = "%s · Nv. %d/5%s" % [data.evolution if gear.evolved[data.id] else data.title, gear.levels[data.id], " · EQUIPADO" if data.id in gear.equipped else ""]
		controls.detail.text = data.description + "\nReceta: Nv.5 + " + data.passive_title + " + 1 núcleo → " + data.evolution
		controls.upgrade.text = "Desbloquear · 1" if gear.levels[data.id] == 0 else "Mejorar · 1"
		controls.upgrade.disabled = true
		controls.upgrade.hide()
		controls.equip.text = "Retirar" if data.id in gear.equipped else "Equipar"
		controls.equip.disabled = gear.levels[data.id] == 0 or (data.id not in gear.equipped and gear.equipped.size() >= 2) or (data.id in gear.equipped and gear.equipped.size() == 1)
		controls.passive.text = data.passive_title + (" ✓" if gear.passives[data.passive] else " · 1")
		controls.passive.disabled = true
		controls.passive.hide()
		controls.evolve.text = "Evolucionado" if gear.evolved[data.id] else "Evolucionar"
		controls.evolve.disabled = not gear.can_evolve(data.id)
	for id: String in passive_buttons:
		var gear: ModuleSystem = district.modules
		passive_buttons[id].text = ModuleSystem.PASSIVE_TITLES[id] + " · %d · " % gear.passive_rank(id) + ("ON" if gear.passives[id] else "OFF")
		passive_buttons[id].disabled = gear.passive_rank(id) == 0 or (not gear.passives[id] and gear.passive_count() >= 4)

func _toggle_passive(id: String) -> void:
	if district.modules.toggle_passive(id):
		district.neural.apply_modules()
		_save_purchase()
	refresh()

func _equipment_action(id: String, action: String) -> void:
	var result: bool = false
	match action:
		"upgrade": result = district.neural.upgrade_module(id)
		"equip": result = district.modules.equip(id)
		"passive": result = district.neural.install_passive(ModuleSystem.definition(id).passive)
		"evolve": result = district.modules.evolve(id)
	if result:
		district.neural.changed.emit()
		_save_purchase()
	refresh()

func _install(id: String) -> void:
	if district.neural.install(id):
		_save_purchase()
	refresh()

func _save_purchase() -> void:
	district.sound.play_cue("upgrade")
	if district.session.save_system != null:
		district.session.save_system.save_game()

func close_panel() -> void:
	if not opened:
		return
	opened = false
	closed_frame = Engine.get_process_frames()
	GamePreferences.current().block_gameplay_input()
	hide()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if opened and event.is_action_pressed("pause") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
