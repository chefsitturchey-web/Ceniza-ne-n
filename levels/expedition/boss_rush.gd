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
const RANKING_SIZE: int = 10
const MAX_NAME: int = 12
var index: int = 0
var elapsed: float = 0
var hits: int = 0
var health: int = Player.MAX_HEALTH
var stage: String = "fight"
var victory: bool = false
var new_record: bool = false
## Puesto del último intento en el ranking (-1 si no entró).
var place: int = -1
var arena: RecaudadorArena
var overlay: CanvasLayer = CanvasLayer.new()
var timer_label: Label
var panel: Control
var focus_button: Button
var name_edit: LineEdit
var ranking_rows: VBoxContainer
var online_rows: VBoxContainer
var online_sent: bool = false
## Tema de cierre heredado de la arena para que no se corte al liberarla.
var outcome_player: AudioStreamPlayer = AudioStreamPlayer.new()

static func best_time() -> float:
	var entries: Array[Dictionary] = ranking()
	return float(entries[0].time) if not entries.is_empty() else 0.0

## Ranking local: los 10 mejores tiempos con nombre. Lee también el récord antiguo sin nombre.
static func ranking() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var config: ConfigFile = ConfigFile.new()
	if config.load(record_path) != OK: return result
	var stored: Variant = config.get_value("boss_rush", "ranking", [])
	if stored is Array:
		for entry: Variant in stored:
			if entry is Dictionary and entry.has("time") and (entry.time is float or entry.time is int) and is_finite(float(entry.time)) and float(entry.time) > 0:
				result.append({"name": str(entry.get("name", "Portador")).left(MAX_NAME), "time": float(entry.time), "hits": int(entry.get("hits", 0))})
	var legacy: Variant = config.get_value("boss_rush", "best_time", 0.0)
	if result.is_empty() and (legacy is float or legacy is int) and is_finite(float(legacy)) and float(legacy) > 0:
		result.append({"name": "Portador", "time": float(legacy), "hits": 0})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)
	return result

static func last_name() -> String:
	var config: ConfigFile = ConfigFile.new()
	if config.load(record_path) != OK: return "Portador"
	return str(config.get_value("boss_rush", "name", "Portador")).left(MAX_NAME)

## Inserta un tiempo y devuelve su puesto (0 = primero) o -1 si no entra en el ranking.
static func submit(player: String, seconds: float, hit_count: int) -> int:
	var clean: String = player.strip_edges().left(MAX_NAME)
	if clean.is_empty(): clean = "Portador"
	var entries: Array[Dictionary] = ranking()
	var entry: Dictionary = {"name": clean, "time": seconds, "hits": hit_count}
	entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)
	var place: int = entries.find(entry)
	entries.resize(mini(entries.size(), RANKING_SIZE))
	if place >= RANKING_SIZE: return -1
	var config: ConfigFile = ConfigFile.new()
	config.set_value("boss_rush", "ranking", entries)
	config.set_value("boss_rush", "name", clean)
	config.set_value("boss_rush", "best_time", float(entries[0].time))
	var pending: String = record_path + ".tmp"
	if config.save(pending) != OK: return -1
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(record_path)) != OK: return -1
	return place

static func store_best(seconds: float) -> bool:
	return submit(last_name(), seconds, 0) >= 0

static func format_time(seconds: float) -> String:
	var total: int = int(seconds * 10)
	return "%02d:%02d.%d" % [total / 600, (total / 10) % 60, total % 10]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	overlay.layer = 20
	add_child(overlay)
	outcome_player.bus = &"Music"
	add_child(outcome_player)
	timer_label = Label.new()
	timer_label.name = "RushTimer"
	# Bajo el panel de vida del jugador, sin tapar su texto.
	timer_label.position = Vector2(14, 52)
	timer_label.size = Vector2(220, 18)
	timer_label.add_theme_font_override("font", TextMarks.FONT)
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.add_theme_color_override("font_color", Color("dcf6ee"))
	timer_label.add_theme_constant_override("outline_size", 4)
	timer_label.add_theme_color_override("font_outline_color", Color("08111c"))
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(timer_label)
	TextMarks.attach(timer_label)
	ScreenFit.fit_layer(overlay)
	# Victorias ganadas sin conexión se envían ahora si ya hay red.
	OnlineRanking.flush(get_tree())
	start_fight(0)

func start_fight(number: int) -> void:
	index = number
	stage = "fight"
	outcome_player.stop()
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
	carry_outcome()
	close_arena()
	if not won:
		show_results(false, title)
	elif index >= CampaignRoute.COUNT - 1:
		show_results(true, title)
	else:
		var before: int = remaining
		health = mini(Player.MAX_HEALTH, remaining + int(Player.MAX_HEALTH * HEAL))
		show_transition(title, before)

## La arena se libera al resolverse y con ella su música: el tema de victoria o derrota
## sigue sonando aquí desde el mismo punto para escucharse completo.
func carry_outcome() -> void:
	var source: AudioStreamPlayer = arena.sound.outcome
	if not source.playing: return
	outcome_player.stream = source.stream
	outcome_player.volume_db = source.volume_db
	outcome_player.play(source.get_playback_position())

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
	row.add_theme_font_override("font", TextMarks.FONT)
	row.add_theme_font_size_override("font_size", 12)
	row.add_theme_color_override("font_color", color)
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(row)
	TextMarks.attach(row)
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
	place = submit(last_name(), elapsed, hits) if won else -1
	var rows: VBoxContainer = build_panel("BOSS RUSH COMPLETADO" if won else "SEÑAL PERDIDA", Color("ffce75") if won else Color("dd6482"))
	if not won: line(rows, "Caíste ante %s." % last_title, Color("dd6482"))
	line(rows, "Jefes %d/%d   Tiempo %s   Golpes %d" % [index + (1 if won else 0), CampaignRoute.COUNT, format_time(elapsed), hits])
	if new_record: line(rows, "NUEVO RÉCORD", Color("ffce75"))
	if place >= 0:
		# El nombre se puede cambiar aquí mismo; se guarda al pulsar Intro o al salir.
		var name_row: HBoxContainer = HBoxContainer.new()
		name_row.alignment = BoxContainer.ALIGNMENT_CENTER
		rows.add_child(name_row)
		var caption: Label = Label.new()
		caption.text = "Puesto %d. Tu nombre:" % (place + 1)
		caption.add_theme_font_override("font", TextMarks.FONT)
		caption.add_theme_font_size_override("font_size", 10)
		name_row.add_child(caption)
		name_edit = LineEdit.new()
		name_edit.text = last_name()
		name_edit.max_length = MAX_NAME
		name_edit.custom_minimum_size = Vector2(110, 0)
		name_edit.text_submitted.connect(func(_text: String) -> void: rename_entry(); show_ranking_rows())
		name_row.add_child(name_edit)
	ranking_rows = VBoxContainer.new()
	ranking_rows.add_theme_constant_override("separation", 0)
	rows.add_child(ranking_rows)
	show_ranking_rows()
	online_rows = VBoxContainer.new()
	online_rows.add_theme_constant_override("separation", 0)
	rows.add_child(online_rows)
	show_online_rows()
	focus_button = button(rows, "Volver al menú", return_to_menu)
	button(rows, "Reintentar", retry)
	focus_button.grab_focus()
	run_finished.emit(won)

## Ranking de los 5 mejores; la marca propia sale en dorado.
func show_ranking_rows() -> void:
	if not is_instance_valid(ranking_rows): return
	for child: Node in ranking_rows.get_children(): child.queue_free()
	var entries: Array[Dictionary] = ranking()
	if entries.is_empty():
		line(ranking_rows, "Ranking vacío: termina el Boss Rush para entrar", Color("8299a8"))
		return
	for position: int in mini(5, entries.size()):
		var entry: Dictionary = entries[position]
		var row: Label = line(ranking_rows, "%d. %s  %s  (%d golpes)" % [position + 1, entry.name, format_time(entry.time), entry.hits], Color("ffce75") if position == place else Color("9fb4c4"))
		row.add_theme_font_size_override("font_size", 10)

## Top online (los 3 primeros). Sin conexión solo avisa; el modo se juega igual.
func show_online_rows() -> void:
	line(online_rows, "Top online: conectando...", Color("8299a8")).add_theme_font_size_override("font_size", 10)
	OnlineRanking.fetch_top(self, func(entries: Variant) -> void:
		if not is_instance_valid(online_rows): return
		for child: Node in online_rows.get_children(): child.queue_free()
		var text: String = "Top online: sin conexión"
		var color: Color = Color("8299a8")
		if entries is Array:
			if entries.is_empty(): text = "Top online: aún vacío"
			else:
				var parts: PackedStringArray = []
				for position: int in mini(3, entries.size()):
					parts.append("%d. %s %s" % [position + 1, str(entries[position].name), format_time(float(entries[position].seconds))])
				text = "Top online: " + "   ".join(parts)
				color = Color("47dacb")
		line(online_rows, text, color).add_theme_font_size_override("font_size", 10))

## Envía la victoria al ranking online una sola vez, con el nombre final.
func send_online() -> void:
	if not victory or online_sent: return
	online_sent = true
	OnlineRanking.queue(get_tree(), last_name(), elapsed, hits)

## Cambia el nombre de la marca recién conseguida.
func rename_entry() -> void:
	if place < 0 or not is_instance_valid(name_edit): return
	var entries: Array[Dictionary] = ranking()
	if place >= entries.size(): return
	var clean: String = name_edit.text.strip_edges().left(MAX_NAME)
	if clean.is_empty() or clean == entries[place].name: return
	entries[place].name = clean
	var config: ConfigFile = ConfigFile.new()
	config.set_value("boss_rush", "ranking", entries)
	config.set_value("boss_rush", "name", clean)
	config.set_value("boss_rush", "best_time", float(entries[0].time))
	var pending: String = record_path + ".tmp"
	if config.save(pending) == OK:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(record_path))

func retry() -> void:
	rename_entry()
	send_online()
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	rename_entry()
	send_online()
	close_arena()
	ScreenFade.change_scene(get_tree(), MENU)
