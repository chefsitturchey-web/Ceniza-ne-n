class_name StoryDirector
extends Node2D
## Tres operaciones persistentes por distrito; el objetivo del HUD se deriva del mundo.
const RESCUE_X: float = -760
const RELAY_X: float = 1080
const TRAIN: Texture2D = preload("res://assets/expedition/train.png")
var district: District
var completed: Array[bool] = [false, false, false]
var relay_ordered: bool = false
var relay_progress: float = 0
var convoy_active: bool = false
var convoy_x: float = -1240
var convoy_health: float = 180
var ambush_triggered: bool = false
var damage_timer: float = 0
var journal: JournalPanel
var hud: CanvasLayer
var elapsed: float = 0
var novel: NovelPanel
var present_dialogue: bool = true
var seen_scenes: Array[String] = []
var dialogue_queue: Array[Dictionary] = []

func setup(world: District) -> void:
	district = world
	z_index = -1
	if not InputMap.has_action("journal"): InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	journal = JournalPanel.new()
	journal.story = self
	add_child(journal)
	novel = NovelPanel.new()
	novel.finished.connect(_dialogue_finished)
	add_child(novel)
	hud = CanvasLayer.new()
	hud.layer = 4
	add_child(hud)
	var button: Button = Button.new()
	button.position = Vector2(532, 28)
	button.size = Vector2(96, 22)
	button.text = "L · Diario"
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(journal.open_panel)
	hud.add_child(button)

func _process(_delta: float) -> void:
	hud.visible = not get_tree().paused and not district.expedition.active and not district.session.finished
	if present_dialogue and not dialogue_queue.is_empty() and not novel.opened and not get_tree().paused and not district.expedition.active and not district.session.finished:
		if Engine.get_process_frames() > GamePreferences.current().input_block_frame:
			novel.play(dialogue_queue.pop_front())

func queue_dialogue(section: String) -> void:
	if not present_dialogue: return
	var scene: Dictionary = VisualStory.scene(district.zone_index, section)
	if scene.id in seen_scenes: return
	for pending: Dictionary in dialogue_queue:
		if pending.id == scene.id: return
	dialogue_queue.append(scene)

func _dialogue_finished(scene_id: String) -> void:
	if scene_id not in seen_scenes: seen_scenes.append(scene_id)
	checkpoint()

func replay(index: int, section: String) -> bool:
	if index > district.zone_index or novel.opened: return false
	return novel.play(VisualStory.scene(index, section), true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") and not event.is_echo():
		journal.open_panel()
		get_viewport().set_input_as_handled()

func ready_to_travel() -> bool: return completed.all(func(flag: bool) -> bool: return flag)

func soldiers() -> int:
	var result: int = 0
	for ally: FieldAlly in get_tree().get_nodes_in_group(GameRules.ALLIES):
		if ally.hp > 0 and ally.role in ["ranger", "guardian"]: result += 1
	return result

func objective() -> String:
	if ready_to_travel():
		var closed: int = 0
		var portals: Array = district.civic.gates + district.expedition.repeaters
		for portal: EnemyRepeater in portals:
			if portal.health.current <= 0: closed += 1
		if closed < portals.size(): return "Entradas cerradas: %d/%d - F asaltar, F retirada" % [closed, portals.size()]
		if not district.civic.stabilized(): return "Estabiliza: resiste una noche y genera energía"
		if not district.expedition.station.train_arrived: return "Entradas cerradas - espera el tren en la estación"
		return "Tren listo - E en estación; jefe: " + district.zone.boss_title
	var built: int = 0
	for site: ConstructionSite in district.construction.sites:
		if site.hp > 0: built += 1
	if built < 4: return "Construye las cuatro defensas centrales - mantener E"
	if district.expansion.energy_bonus() == 0: return "Estabiliza: construye un generador cerca (+/-360)"
	if district.core.tier < 2: return "Mejora el núcleo con E: desbloquea apoyo y defensas Nv.2"
	if soldiers() < 2: return "Cuartel + reclutas + fusil y escudo en el taller"
	if not completed[0]: return "Rescata la baliza occidental (izq. 760) - E" if district.civic.safe_to_build(RESCUE_X) else "F: asalta la brecha izquierda para llegar al rescate"
	if not completed[1]:
		return "Contrata un técnico: irá al relé oriental (1080)" if relay_ordered else "Abre el frente y encarga el relé (der. 1080) - E"
	if not completed[2]:
		if convoy_health <= 0: return "Recupera el transporte averiado - E cuesta 25"
		return "Escolta el transporte al núcleo - F retira tropas" if convoy_active else "Activa el transporte occidental (izq. 1240) - E"
	return "Consulta el objetivo en el diario (L)"

func target_at(x: float) -> int:
	if not completed[0] and absf(x - RESCUE_X) < 25: return -400
	if not completed[1] and absf(x - RELAY_X) < 25: return -401
	if not completed[2] and absf(x - convoy_x) < 35: return -402
	return GameRules.NO_TARGET

func describe(target: int) -> Dictionary:
	match target:
		-400: return {"text": "Rescatar supervivientes y recuperar baliza", "cost": 0}
		-401: return {"text": "Técnico reparando relé: %d%%" % int(relay_progress / 6 * 100) if relay_ordered else "Encargar relé: necesita un técnico", "cost": -1 if relay_ordered else 30}
	return {"text": "Reparar transporte" if convoy_health <= 0 else ("Escolta: acércate con tropas" if convoy_active else "Activar transporte: primero rescate y relé"), "cost": 25 if convoy_health <= 0 else 0}

func interact(target: int) -> bool:
	if district.cycle.phase != "DÍA" or district.player.health <= 0: return false
	var x: float = RESCUE_X if target == -400 else (RELAY_X if target == -401 else convoy_x)
	if not district.civic.safe_to_build(x):
		district.presenter.show_notice("Cierra la brecha que bloquea esta operación")
		return false
	match target:
		-400:
			if completed[0]: return false
			complete(0)
			district.bank.deposit(15)
		-401:
			if completed[1] or relay_ordered or district.expansion.energy_bonus() == 0 or not district.bank.spend(30): return false
			relay_ordered = true
			district.presenter.show_notice("Relé encargado: compra herramientas técnicas en el taller")
		-402:
			if completed[2] or not completed[0] or not completed[1]: return false
			if convoy_health <= 0:
				if not district.bank.spend(25): return false
				convoy_health = 180
			elif convoy_active: return false
			convoy_active = true
			# Emboscada única: reparar el convoy no repite enemigos ni recompensas.
			if not ambush_triggered:
				ambush_triggered = true
				for offset: float in [-100.0, 120.0]:
					var data: EnemyData = load("res://data/enemies/errante.tres").duplicate() as EnemyData
					data.reward = 0
					var enemy: SiegeEnemy = district.director.spawn_enemy(-1, data, district.cycle.day)
					enemy.position.x = convoy_x + offset
				district.civic.advance_side = 0
		_:
			return false
	checkpoint()
	return true

func complete(index: int) -> void:
	if completed[index]: return
	completed[index] = true
	district.experience.gain(10 + index * 5)
	district.presenter.show_notice(["Supervivientes a salvo - L: diario", "Relé recuperado - L: diario", "Transporte a salvo - L: diario"][index])
	district.sound.play_cue("upgrade")
	queue_dialogue(["rescue", "relay", "convoy"][index])
	checkpoint()

func checkpoint() -> void:
	if district.session.save_system != null: district.session.save_system.save_game()

func tick(delta: float) -> void:
	elapsed += delta
	if convoy_active and convoy_health > 0 and not completed[2]:
		var escorted: bool = false
		for ally: FieldAlly in get_tree().get_nodes_in_group(GameRules.ALLIES):
			if ally.role in ["ranger", "guardian"] and ally.hp > 0 and absf(ally.position.x - convoy_x) < 260: escorted = true
		if escorted and district.player.health > 0 and absf(district.player.position.x - convoy_x) < 180:
			convoy_x = move_toward(convoy_x, 0, delta * 48)
		damage_timer = maxf(0, damage_timer - delta)
		if damage_timer == 0 and district.defenses.nearest_enemy(convoy_x, 65) != null:
			convoy_health = maxf(0, convoy_health - 18)
			damage_timer = 1
		if convoy_x >= -1:
			convoy_active = false
			district.bank.deposit(40)
			complete(2)
	queue_redraw()

func work_relay(delta: float) -> void:
	if not relay_ordered or completed[1]: return
	relay_progress = minf(6, relay_progress + delta)
	if relay_progress >= 6: complete(1)

func snapshot() -> Dictionary:
	return {"completed": completed.duplicate(), "relay_ordered": relay_ordered, "relay_progress": relay_progress, "convoy_active": convoy_active, "convoy_x": convoy_x, "convoy_health": convoy_health, "ambush_triggered": ambush_triggered, "seen_scenes": seen_scenes.duplicate()}

func restore(data: Dictionary) -> void:
	seen_scenes.assign(data.get("seen_scenes", []))
	dialogue_queue.clear()
	completed.assign(data.get("completed", [false, false, false]))
	relay_ordered = data.get("relay_ordered", false)
	relay_progress = float(data.get("relay_progress", 0))
	convoy_active = data.get("convoy_active", false)
	convoy_x = float(data.get("convoy_x", -1240))
	convoy_health = float(data.get("convoy_health", 180))
	ambush_triggered = data.get("ambush_triggered", convoy_active or convoy_x > -1240)
	if data.has("seen_scenes"):
		queue_dialogue("opening")
		for index: int in range(3):
			if completed[index]: queue_dialogue(["rescue", "relay", "convoy"][index])

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not data.get("seen_scenes", []) is Array or data.get("seen_scenes", []).size() > 40: return false
	var unique: Array[String] = []
	for key: Variant in data.get("seen_scenes", []):
		if not key is String or not VisualStory.valid_key(key) or key in unique: return false
		unique.append(key)
	if not data.get("ambush_triggered", false) is bool: return false
	if not data.get("completed") is Array or data.completed.size() != 3: return false
	for flag: Variant in data.completed:
		if not flag is bool: return false
	for key: String in ["relay_ordered", "convoy_active"]:
		if not data.get(key) is bool: return false
	if not ExpansionSystem.number(data.get("relay_progress"), 0, 6) or not ExpansionSystem.number(data.get("convoy_x"), -1240, 0) or not ExpansionSystem.number(data.get("convoy_health"), 0, 180): return false
	if data.completed[1] and data.relay_progress < 6: return false
	if data.completed[2] and (not data.completed[0] or not data.completed[1] or data.convoy_x < -1 or data.convoy_health <= 0): return false
	if data.convoy_active and (not data.completed[0] or not data.completed[1] or data.completed[2]): return false
	return true

func _draw() -> void:
	var rescue: Rect2 = ArtScale.source(GameArt.CIVIC, 0)
	draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(rescue, 44, Vector2(RESCUE_X, GameRules.FLOOR_Y)), rescue, Color.WHITE if not completed[0] else Color("53616d"))
	draw_texture_rect(EnemyRepeater.TEXTURE, Rect2(RELAY_X - 14, 212, 28, 48), false, Color("47dacb") if completed[1] else Color("8299a8"))
	if relay_ordered and not completed[1]:
		draw_rect(Rect2(RELAY_X - 20, 202, 40 * relay_progress / 6, 3), Color("ffce75"))
	if not completed[2]:
		draw_texture_rect(TRAIN, Rect2(convoy_x - 50, GameRules.FLOOR_Y - 31, 100, 31), false, Color.WHITE if convoy_health > 0 else Color("53616d"))
		draw_rect(Rect2(convoy_x - 25, 208, 50, 3), Color("182639"))
		draw_rect(Rect2(convoy_x - 25, 208, convoy_health / 180 * 50, 3), Color("47dacb"))
		for wheel: int in [-1, 1]:
			draw_arc(Vector2(convoy_x + wheel * 27, GameRules.FLOOR_Y - 4), 4, elapsed * 3 if convoy_active else 0, (elapsed * 3 if convoy_active else 0) + PI, 12, Color("8299a8"), 1)
