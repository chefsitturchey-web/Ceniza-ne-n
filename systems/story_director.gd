class_name StoryDirector
extends Node2D
## Tres operaciones persistentes por distrito; el objetivo del HUD se deriva del mundo.
var rescue_x: float = -760
var relay_x: float = 1080
const TRAIN: Texture2D = preload("res://assets/world/expedition/train.png")
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

## Botón del diario arriba a la derecha; HudStack lo baja bajo el cartel de la guía.
var journal_button: Button

func setup(world: District) -> void:
	district = world
	var layout: Dictionary = FrontierLayout.profile(world.zone_index)
	rescue_x = layout.rescue
	relay_x = layout.relay
	convoy_x = layout.convoy
	z_index = -1
	if not InputMap.has_action("journal"): InputSetup.add_action("journal", KEY_L, JOY_BUTTON_RIGHT_SHOULDER)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	journal = JournalPanel.new()
	journal.story = self
	add_child(journal)
	novel = NovelPanel.new()
	novel.finished.connect(_dialogue_finished)
	novel.panel_opened.connect(func() -> void:
		if district != null: district.sound.set_ducked(true))
	novel.panel_closed.connect(func() -> void:
		if district != null: district.sound.set_ducked(false))
	add_child(novel)
	hud = CanvasLayer.new()
	hud.layer = 4
	add_child(hud)
	var button: Button = Button.new()
	journal_button = button
	button.position = Vector2(532, 28)
	button.size = Vector2(96, 22)
	InputGlyphs.bind(button, "{journal} - Diario")
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(journal.open_panel)
	hud.add_child(button)
	# Esquina derecha también en pantallas anchas, respetando el notch.
	var place: Callable = func() -> void:
		button.position.x = ScreenFit.visible_size(self).x - 108 - float(ScreenFit.safe_margins(self).right)
	get_viewport().size_changed.connect(place)
	place.call()

func _process(_delta: float) -> void:
	hud.visible = not get_tree().paused and not district.expedition.active and not district.session.finished and not TouchOverlay.showing()
	if present_dialogue and not district.expedition.active and not district.session.finished:
		queue_milestones()
	if present_dialogue and not dialogue_queue.is_empty() and not novel.opened and not get_tree().paused and not district.expedition.active and not district.session.finished:
		if Engine.get_process_frames() > GamePreferences.current().input_block_frame:
			novel.play(dialogue_queue.pop_front())

## Reconstruye pendientes tambien al cargar partidas anteriores.
func queue_milestones() -> void:
	queue_dialogue("opening")
	if district.core.tier > 0: queue_dialogue("foundation")
	if district.frontier.plots.any(func(plot: ClearanceSite) -> bool: return plot.cleared): queue_dialogue("expansion")
	for index: int in range(3):
		if completed[index]: queue_dialogue(["rescue", "relay", "convoy"][index])

func queue_dialogue(section: String) -> void:
	if not present_dialogue: return
	var id: String = "%d:%s" % [district.zone_index, section]
	if id in seen_scenes or (novel != null and novel.opened and novel.scene_data.id == id): return
	for pending: Dictionary in dialogue_queue:
		if pending.id == id: return
	dialogue_queue.append(VisualStory.scene(district.zone_index, section))

func _dialogue_finished(scene_id: String) -> void:
	if scene_id not in seen_scenes: seen_scenes.append(scene_id)
	checkpoint()

func replay(index: int, section: String) -> bool:
	if index > district.zone_index or novel.opened: return false
	return novel.play(VisualStory.scene(index, section), true)

func _unhandled_input(event: InputEvent) -> void:
	if GamePreferences.current().debug_input_blocked(): return
	if event.is_action_pressed("journal") and not event.is_echo():
		journal.open_panel()
		get_viewport().set_input_as_handled()

func ready_to_travel() -> bool: return completed.all(func(flag: bool) -> bool: return flag)

func soldiers() -> int:
	var result: int = 0
	for ally: FieldAlly in get_tree().get_nodes_in_group(GameRules.ALLIES):
		if ally.hp > 0 and ally.role in ["ranger", "guardian"]: result += 1
	return result

## Objetivo con la tecla o el botón del dispositivo activo.
func objective() -> String:
	return InputGlyphs.fill(objective_steps())

func objective_steps() -> String:
	if district.core.tier > 0 and district.cycle.phase == "AVISO": return "Se acerca la noche: vuelve tras las murallas"
	if district.core.tier > 0 and district.cycle.phase == "NOCHE": return "Noche: resiste hasta el amanecer junto al núcleo"
	# Sin constructores ninguna obra avanza: es el primer bloqueo a resolver.
	if not district.colony.workers.any(func(worker: ColonyWorker) -> bool: return worker.role == &"builder"):
		if district.civic.tools[0] == 0: return "Sin constructores: compra un martillo en el taller (izq. 600) - {interact}"
		if district.civic.villagers.is_empty(): return recruit_step()
		return "Un superviviente recoge el martillo en el taller"
	for site: ExpansionOutpost in district.expansion.sites:
		if site.hp > 0 and site.spec.id == "barracks" and site.staff_count() > 0 and not district.expansion.powered(site):
			return "El cuartel no tiene energía: apaga una torreta con {toggle_power} o construye otro generador"
	if district.core.tier > 0 and district.cycle.phase == "DÍA" and district.cycle.phase_remaining < 60:
		var core: ColonyCore = district.core
		if core.tier == 2 and not core.ordered and core.upgrade_blocker().is_empty() and district.bank.scrap >= core.upgrade_cost() and district.bank.parts + district.bank.stored_parts >= core.parts_cost():
			return "Anochece en %d s: mejora el núcleo a Nv.3 - {interact}" % ceili(district.cycle.phase_remaining)
		for site: ConstructionSite in district.construction.sites.slice(0, 4):
			if site.ordered or site.hp <= 0: continue
			var cost: int = site.data.repair_cost if site.hp < site.max_hp else (site.tier * 25 if site.tier < district.core.tier else -1)
			if cost >= 0 and district.bank.scrap >= cost:
				return "Anochece en %d s: %s %s - {interact}" % [ceili(district.cycle.phase_remaining), "repara" if site.hp < site.max_hp else "refuerza", "la muralla" if site.data.blocks_enemies else "la torreta"]
	if ready_to_travel():
		var closed: int = 0
		var portals: Array = district.civic.gates + district.expedition.repeaters
		for portal: EnemyRepeater in portals:
			if portal.health.current <= 0: closed += 1
		if closed < portals.size(): return "Entradas cerradas: %d/%d - {escort} asaltar, {escort} retirada" % [closed, portals.size()]
		if not district.civic.stabilized(): return "Estabiliza: resiste una noche y genera energía"
		if not district.expedition.station.train_arrived: return "Entradas cerradas - espera el tren en la estación"
		return "Tren listo - {interact} en estación; jefe: " + district.zone.boss_title
	if district.core.tier == 0:
		if district.core.ordered: return "Levanta el núcleo: espera a los constructores"
		return "Recupera 12 piezas junto a la llegada; {interact}: levantar núcleo"
	var built: int = 0
	for site: ConstructionSite in district.construction.sites:
		if site.hp > 0 and site.data.blocks_enemies: built += 1
	if built < 2: return "Construye las dos murallas centrales - mantén {interact}"
	if district.expansion.energy_bonus() == 0:
		var power: String = outpost_step("generator", "generador")
		return power if not power.is_empty() else "El generador necesita energía: revisa el consumo"
	if district.core.tier < 2:
		if district.bank.parts + district.bank.stored_parts < district.core.parts_cost(): return "Reúne %d piezas para el núcleo Nv.2 (restos del distrito)" % district.core.parts_cost()
		return "Mejora el núcleo con {interact}: desbloquea torretas y apoyo"
	var turrets: int = 0
	for site: ConstructionSite in district.construction.sites.slice(0, 4):
		if site.kind == &"turret" and (site.hp > 0 or site.ordered): turrets += 1
	if turrets < 2: return "Construye las dos torretas centrales antes de la noche - mantén {interact}"
	if soldiers() < 2: return soldier_step()
	var exposed: String = protection_step()
	if not exposed.is_empty(): return exposed
	if not completed[0]: return "Rescata la baliza (izq. %d) - {interact}" % int(absf(rescue_x)) if district.civic.safe_to_build(rescue_x) else "{escort}: asalta la brecha izquierda para llegar al rescate"
	if not completed[1]:
		if not district.civic.safe_to_build(relay_x): return "{escort}: asalta la brecha derecha para llegar al relé"
		if not relay_ordered: return "Encarga el relé (der. %d) - {interact}" % int(relay_x)
		for ally: FieldAlly in get_tree().get_nodes_in_group(GameRules.ALLIES):
			if ally.role == "technician" and ally.hp > 0: return "El técnico repara el relé oriental: protégelo"
		if district.civic.tools[4] == 0: return "Compra una herramienta técnica en el taller (izq. 600) - {interact}"
		if district.civic.villagers.is_empty(): return recruit_step()
		return "Un superviviente recoge la herramienta técnica en el taller"
	if not completed[2]:
		if not district.civic.safe_to_build(convoy_x): return "{escort}: asalta la brecha izquierda para llegar al transporte"
		if convoy_health <= 0: return "Recupera el transporte averiado - {interact} cuesta 25"
		return "Escolta el transporte al núcleo - {escort} retira tropas" if convoy_active else "Activa el transporte (izq. %d) - {interact}" % int(absf(convoy_x))
	return "Consulta el objetivo en el diario ({journal})"

## Como en Kingdom, una instalación más allá de las murallas centrales pide extender el muro.
func protection_step() -> String:
	var guard: Dictionary = protection_target()
	if guard.is_empty(): return ""
	var wall: ConstructionSite = guard.wall
	return "Protege %s: construye la muralla exterior (%s %d) - {interact}" % [guard.title, "izq." if wall.x < 0 else "der.", int(absf(wall.x))]

## Muralla exterior más cercana que cubriría una instalación expuesta, o vacío.
func protection_target() -> Dictionary:
	for site: ExpansionOutpost in district.expansion.sites:
		if site.hp <= 0 or absf(site.position.x) <= central_reach(): continue
		var side: float = signf(site.position.x)
		var guard: ConstructionSite
		var covered: bool = false
		for wall: ConstructionSite in district.civic.walls:
			if signf(wall.x) != side or absf(wall.x) <= absf(site.position.x): continue
			if wall.hp > 0 or wall.ordered: covered = true
			elif guard == null or absf(wall.x) < absf(guard.x): guard = wall
		if not covered and guard != null and district.civic.safe_to_build(guard.x) and not district.frontier.blocked(guard.x):
			return {"wall": guard, "title": String(site.spec.title).to_lower()}
	return {}

func central_reach() -> float:
	var reach: float = 0
	for site: ConstructionSite in district.construction.sites.slice(0, 4):
		if site.data.blocks_enemies: reach = maxf(reach, absf(site.x))
	return reach

## Divide "formar soldados" en el paso concreto que falta y dónde hacerlo.
func soldier_step() -> String:
	var step: String = outpost_step("barracks", "cuartel")
	return weapons_step() if step.is_empty() else step

## Paso pendiente de la instalación más cercana de ese tipo; vacío si ya funciona.
func outpost_step(id: String, title: String) -> String:
	var nearest: ExpansionOutpost
	for site: ExpansionOutpost in district.expansion.sites:
		if site.spec.id != id: continue
		if site.hp > 0: return ""
		if site.ordered: return "Los constructores levantan el " + title
		if district.civic.safe_to_build(site.position.x) and (nearest == null or absf(site.position.x) < absf(nearest.position.x)): nearest = site
	var place: String = "%s %d" % ["izq." if nearest.position.x < 0 else "der.", int(absf(nearest.position.x))]
	if district.frontier.blocked(nearest.position.x): return "Despeja la parcela del %s (%s) - {interact}" % [title, place]
	return "Construye el %s (%s) - {interact}" % [title, place]

func weapons_step() -> String:
	var pending: int = district.civic.tools[2] + district.civic.tools[3]
	if soldiers() + pending < 2: return "Compra fusiles en el taller (izq. 600) - soldados %d/2" % soldiers()
	if district.civic.villagers.size() < pending: return recruit_step()
	return "Los reclutas recogen sus armas en el taller"

func recruit_step() -> String:
	if district.civic.population() >= district.civic.capacity: return "Población al máximo: amplía el refugio junto al núcleo - {interact}"
	return "Recluta supervivientes en un campamento (izq./der. 1340) - {interact}"

func target_at(x: float) -> int:
	if not completed[0] and absf(x - rescue_x) < 25: return -400
	if not completed[1] and absf(x - relay_x) < 25: return -401
	if not completed[2] and absf(x - convoy_x) < 35: return -402
	return GameRules.NO_TARGET

func describe(target: int) -> Dictionary:
	match target:
		-400: return {"text": "Rescatar supervivientes y recuperar baliza", "cost": 0}
		-401: return {"text": "Técnico reparando relé: %d%%" % int(relay_progress / 6 * 100) if relay_ordered else "Encargar relé: necesita un técnico", "cost": -1 if relay_ordered else 30}
	return {"text": "Reparar transporte" if convoy_health <= 0 else ("Escolta: acércate con tropas" if convoy_active else "Activar transporte: primero rescate y relé"), "cost": 25 if convoy_health <= 0 else 0}

func interact(target: int) -> bool:
	if district.cycle.phase != "DÍA" or district.player.health <= 0: return false
	var x: float = rescue_x if target == -400 else (relay_x if target == -401 else convoy_x)
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
			# La emboscada espera a la escolta (tick): los soldados tardan en cruzar el distrito.
			district.civic.advance_side = 0
			if not ambush_triggered: district.presenter.show_notice("Transporte listo: espera a que llegue la escolta")
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
		if escorted and not ambush_triggered:
			# Emboscada única: reparar el convoy no repite enemigos ni recompensas.
			ambush_triggered = true
			district.presenter.show_notice("¡Emboscada! La escolta protege el transporte")
			for offset: float in [-160.0, 200.0]:
				var data: EnemyData = load("res://data/enemies/errante.tres").duplicate() as EnemyData
				data.reward = 0
				var enemy: SiegeEnemy = district.director.spawn_enemy(-1, data, district.cycle.day)
				enemy.position.x = convoy_x + offset
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
	if not ExpansionSystem.number(data.get("relay_progress"), 0, 6) or not ExpansionSystem.number(data.get("convoy_x"), -GameRules.MAP_HALF_WIDTH, 0) or not ExpansionSystem.number(data.get("convoy_health"), 0, 180): return false
	if data.completed[1] and data.relay_progress < 6: return false
	if data.completed[2] and (not data.completed[0] or not data.completed[1] or data.convoy_x < -1 or data.convoy_health <= 0): return false
	if data.convoy_active and (not data.completed[0] or not data.completed[1] or data.completed[2]): return false
	return true

func _draw() -> void:
	var rescue: Rect2 = ArtScale.source(GameArt.CIVIC, 0)
	draw_texture_rect_region(GameArt.CIVIC, ArtScale.grounded(rescue, 44, Vector2(rescue_x, GameRules.FLOOR_Y)), rescue, Color.WHITE if not completed[0] else Color("53616d"))
	draw_texture_rect(EnemyRepeater.TEXTURE, Rect2(relay_x - 14, 212, 28, 48), false, Color("47dacb") if completed[1] else Color("8299a8"))
	if relay_ordered and not completed[1]:
		draw_rect(Rect2(relay_x - 20, 202, 40 * relay_progress / 6, 3), Color("ffce75"))
	if not completed[2]:
		draw_texture_rect(TRAIN, Rect2(convoy_x - 50, GameRules.FLOOR_Y - 31, 100, 31), false, Color.WHITE if convoy_health > 0 else Color("53616d"))
		draw_rect(Rect2(convoy_x - 25, 208, 50, 3), Color("182639"))
		draw_rect(Rect2(convoy_x - 25, 208, convoy_health / 180 * 50, 3), Color("47dacb"))
		for wheel: int in [-1, 1]:
			draw_arc(Vector2(convoy_x + wheel * 27, GameRules.FLOOR_Y - 4), 4, elapsed * 3 if convoy_active else 0, (elapsed * 3 if convoy_active else 0) + PI, 12, Color("8299a8"), 1)
