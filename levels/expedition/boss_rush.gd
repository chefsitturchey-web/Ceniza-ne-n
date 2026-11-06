class_name BossRush
extends Node
## Boss Rush: los cinco jefes seguidos en el orden de la campaña. Reutiliza la arena de
## jefes sin configurarla desde una colonia, así que nunca lee ni escribe la partida guardada.
## Entre combates cura parte de la vida; al final muestra tiempo, golpes y mejor marca.
signal run_finished(victory: bool)
const ARENA: PackedScene = preload("res://levels/expedition/recaudador_arena.tscn")
const THEME: Theme = preload("res://ui/theme.tres")
const MENU: String = "res://ui/main_menu.tscn"
## Vida que se recupera entre jefes (fracción de la vida máxima).
const HEAL: float = 0.5
## Equipo de la ruta: el filo mejora tras cada jefe, como en la campaña.
const DAMAGE_STEP: int = 15
## Mejor tiempo en un archivo propio, separado de partida.json y de opciones.cfg.
static var record_path: String = "user://boss_rush.cfg"
var index: int = 0
var elapsed: float = 0
var hits: int = 0
var health: int = Player.MAX_HEALTH
var stage: String = "fight"
var victory: bool = false
var new_record: bool = false
var arena: RecaudadorArena
var overlay: CanvasLayer = CanvasLayer.new()
var timer_label: Label
var panel: Control
var focus_button: Button

static func best_time() -> float:
	var config: ConfigFile = ConfigFile.new()
	if config.load(record_path) != OK: return 0.0
	var value: Variant = config.get_value("boss_rush", "best_time", 0.0)
	return float(value) if (value is float or value is int) and is_finite(float(value)) and float(value) > 0 else 0.0

static func store_best(seconds: float) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("boss_rush", "best_time", seconds)
	var pending: String = record_path + ".tmp"
	if config.save(pending) != OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(record_path)) == OK

static func format_time(seconds: float) -> String:
	var total: int = int(seconds * 10)
	return "%02d:%02d.%d" % [total / 600, (total / 10) % 60, total % 10]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	overlay.layer = 20
	add_child(overlay)
	timer_label = Label.new()
	timer_label.name = "RushTimer"
	# Bajo el panel de vida del jugador, sin tapar su texto.
	timer_label.position = Vector2(14, 52)
	timer_label.size = Vector2(220, 18)
	timer_label.add_theme_font_override("font", ThemeDB.fallback_font)
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.add_theme_color_override("font_color", Color("dcf6ee"))
	timer_label.add_theme_constant_override("outline_size", 4)
	timer_label.add_theme_color_override("font_outline_color", Color("08111c"))
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(timer_label)
	ScreenFit.fit_layer(overlay)
	start_fight(0)

func start_fight(number: int) -> void:
	index = number
	stage = "fight"
	arena = ARENA.instantiate() as RecaudadorArena
	arena.zone_index = number
	arena.rush = true
	arena.player.health = health
	arena.player.attack_damage += DAMAGE_STEP * number
	arena.resolved.connect(_on_resolved)
	arena.menu_requested.connect(return_to_menu)
	add_child(arena)
	move_child(overlay, -1)
	update_timer()

func _process(delta: float) -> void:
	if stage == "fight" and is_instance_valid(arena) and not get_tree().paused and not arena.ending and not arena.novel.opened:
		elapsed += delta
	update_timer()

func update_timer() -> void:
	timer_label.visible = stage == "fight"
	timer_label.text = "BOSS RUSH %d/%d   %s" % [index + 1, CampaignRoute.COUNT, format_time(elapsed)]

func _on_resolved(won: bool) -> void:
	if stage != "fight": return
	hits += arena.hit_count
	var remaining: int = arena.player.health
	var title: String = arena.zone.boss_title
	close_arena()
	if not won:
		show_results(false, title)
	elif index >= CampaignRoute.COUNT - 1:
		show_results(true, title)
	else:
		var before: int = remaining
		health = mini(Player.MAX_HEALTH, remaining + int(Player.MAX_HEALTH * HEAL))
		show_transition(title, before)

func close_arena() -> void:
	if is_instance_valid(arena):
		arena.queue_free()
	arena = null
	get_tree().paused = false

func build_panel(heading: String, color: Color) -> VBoxContainer:
	if is_instance_valid(panel): panel.queue_free()
	panel = Control.new()
	panel.name = "RushPanel"
	panel.size = Vector2(640, 360)
	panel.theme = THEME
	overlay.add_child(panel)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("050c17")
	shade.size = Vector2(640, 360)
	panel.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.size = Vector2(640, 360)
	panel.add_child(center)
	var frame: PanelContainer = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuSkin.panel())
	frame.custom_minimum_size = Vector2(340, 0)
	center.add_child(frame)
	var inner: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 18 if side in ["left", "right"] else 14)
	frame.add_child(inner)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	inner.add_child(rows)
	var marker: Label = Label.new()
	marker.text = "BOSS RUSH"
	marker.add_theme_font_size_override("font_size", 10)
	marker.add_theme_color_override("font_color", Color("47dacb"))
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(marker)
	var title: Label = Label.new()
	title.text = heading
	title.theme_type_variation = &"Title"
	title.add_theme_color_override("font_color", color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(title)
	return rows

func line(rows: VBoxContainer, text: String, color: Color = Color("dcf6ee")) -> Label:
	var row: Label = Label.new()
	row.text = text
	row.add_theme_font_override("font", ThemeDB.fallback_font)
	row.add_theme_font_size_override("font_size", 12)
	row.add_theme_color_override("font_color", color)
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(row)
	return row

func button(rows: VBoxContainer, text: String, action: Callable) -> Button:
	var entry: Button = Button.new()
	entry.text = text
	entry.custom_minimum_size = Vector2(0, 24)
	entry.pressed.connect(action)
	MenuSkin.button(entry)
	UiSound.attach(entry)
	rows.add_child(entry)
	return entry

func show_transition(defeated: String, before: int) -> void:
	stage = "transition"
	update_timer()
	var rows: VBoxContainer = build_panel(defeated + " DERROTADO", Color("ffce75"))
	var next: ZoneData = CampaignRoute.zone(index + 1)
	line(rows, "Siguiente: %s (%d/%d)" % [next.boss_title, index + 2, CampaignRoute.COUNT], Color("47dacb"))
	line(rows, "Tiempo: %s   Golpes recibidos: %d" % [format_time(elapsed), hits])
	line(rows, "Vida reparada: %d a %d   Filo mejorado: +%d daño" % [before, health, DAMAGE_STEP], Color("8299a8"))
	focus_button = button(rows, "Siguiente combate", continue_run)
	button(rows, "Abandonar y volver al menú", return_to_menu)
	focus_button.grab_focus()

func continue_run() -> void:
	if stage != "transition": return
	if is_instance_valid(panel): panel.queue_free()
	panel = null
	start_fight(index + 1)

func show_results(won: bool, last_title: String) -> void:
	stage = "results"
	victory = won
	update_timer()
	var best: float = best_time()
	new_record = won and (best <= 0 or elapsed < best)
	if new_record:
		store_best(elapsed)
		best = elapsed
	var rows: VBoxContainer = build_panel("BOSS RUSH COMPLETADO" if won else "SEÑAL PERDIDA", Color("ffce75") if won else Color("dd6482"))
	if not won: line(rows, "Caíste ante %s." % last_title, Color("dd6482"))
	line(rows, "Jefes derrotados: %d/%d" % [index + (1 if won else 0), CampaignRoute.COUNT])
	line(rows, "Tiempo total: %s" % format_time(elapsed))
	line(rows, "Golpes recibidos: %d" % hits)
	if new_record: line(rows, "NUEVO RÉCORD", Color("ffce75"))
	line(rows, "Mejor tiempo: %s" % (format_time(best) if best > 0 else "sin marca"), Color("8299a8"))
	focus_button = button(rows, "Volver al menú", return_to_menu)
	button(rows, "Reintentar", retry)
	focus_button.grab_focus()
	run_finished.emit(won)

func retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	close_arena()
	ScreenFade.change_scene(get_tree(), MENU)
