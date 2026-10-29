class_name GameDebug
extends CanvasLayer
## Laboratorio local. Abrirlo no altera la partida; aplicar cambios a una colonia
## desconecta su persistencia hasta recargarla. Las arenas de prueba son hermanas.
const HELP_FIELDS: Array[String] = ["god_mode", "infinite_stamina", "freeze_ai", "draw_debug", "core_god", "freeze_cycle"]
var enabled: bool = false
var opened: bool = false
var was_paused: bool = false
var previous_focus: Control
var panel: GameDebugPanel
var geometry: GameDebugGeometry
var badge: Button
var god_mode: bool = false
var infinite_stamina: bool = false
var freeze_ai: bool = false
var draw_debug: bool = false
var core_god: bool = false
var freeze_cycle: bool = false
var selected_boss: int = 0
var selected_zone: int = 0
var selected_enemy: int = 0
var selected_ally: int = 0
var selected_tier: int = 2
var spawn_side: int = 0
var teleport_target: int = 0
var loadout: int = 0
var speed_index: int = 2
var practice_launch: bool = false
var preview: RecaudadorArena
var suspended: Dictionary = {}
var preview_settings: Dictionary = {}
var preview_paused: bool = false
var frozen: Dictionary = {}
var notices: Array[String] = []
var refresh_left: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	enabled = OS.is_debug_build() or "--debug-tools" in OS.get_cmdline_user_args()
	if not enabled:
		set_process(false)
		set_process_input(false)
		return
	geometry = GameDebugGeometry.new()
	geometry.tools = self
	add_child(geometry)
	panel = GameDebugPanel.new()
	panel.tools = self
	add_child(panel)
	panel.hide()
	badge = Button.new()
	badge.position = Vector2(505, 338)
	badge.size = Vector2(131, 20)
	badge.theme = panel.theme
	badge.add_theme_font_size_override("font_size", 11)
	badge.text = "Depuración [F1]"
	badge.focus_mode = Control.FOCUS_NONE
	badge.pressed.connect(open_panel)
	add_child(badge)

func active_arena() -> RecaudadorArena:
	if is_instance_valid(preview) and not preview.is_queued_for_deletion(): return preview
	for child: Node in get_tree().root.get_children():
		if child is RecaudadorArena and not child.is_queued_for_deletion(): return child
	return null

func active_district() -> District:
	for child: Node in get_tree().root.get_children():
		if child is District and not child.is_queued_for_deletion(): return child
	return null

func actor() -> CharacterBody2D:
	var arena: RecaudadorArena = active_arena()
	if arena != null: return arena.player
	var district: District = active_district()
	return district.player if district != null else null

func open_panel() -> void:
	if not enabled or opened: return
	was_paused = get_tree().paused
	previous_focus = get_viewport().gui_get_focus_owner()
	opened = true
	GamePreferences.current().debug_modal = true
	get_tree().paused = true
	panel.show()
	badge.hide()
	var arena: RecaudadorArena = active_arena()
	if arena != null: selected_boss = arena.zone_index
	panel.refresh()
	panel.first.grab_focus()
	refresh_info()

func close_panel() -> void:
	if not opened: return
	opened = false
	panel.hide()
	badge.show()
	GamePreferences.current().debug_modal = false
	GamePreferences.current().debug_closed_frame = Engine.get_process_frames() + 1
	GamePreferences.current().block_gameplay_input()
	get_tree().paused = was_paused
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if not enabled or not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_F1:
			if opened: close_panel()
			else: open_panel()
		KEY_ESCAPE:
			if not opened: return
			close_panel()
		KEY_F2: set_toggle("god_mode", not god_mode)
		KEY_F3: set_toggle("freeze_ai", not freeze_ai)
		KEY_F4: set_toggle("draw_debug", not draw_debug)
		_: return
	get_viewport().set_input_as_handled()

func isolate(district: District) -> void:
	if district == null or district.session.debug_practice: return
	district.session.persistence_enabled = false
	district.session.save_system = null
	district.session.debug_practice = true

func consume_practice_launch(node: Node) -> bool:
	if not enabled or not practice_launch or not node is District: return false
	practice_launch = false
	isolate(node)
	node.story.present_dialogue = false
	GamePreferences.current().briefing_requested = false
	return true

func set_toggle(field: String, active: bool) -> void:
	if field not in HELP_FIELDS: return
	set(field, active)
	var arena: RecaudadorArena = active_arena()
	if field != "draw_debug" and active and (arena == null or not arena.debug_practice): isolate(active_district())
	apply_cheats()
	panel.refresh()
	var captions: Dictionary = {"god_mode": "Invulnerabilidad", "infinite_stamina": "Resistencia infinita", "freeze_ai": "IA congelada", "draw_debug": "Colisiones y rutas", "core_god": "Núcleo invulnerable", "freeze_cycle": "Reloj congelado"}
	notice("%s: %s" % [captions[field], "activado" if active else "desactivado"])

func set_speed(index: int) -> void:
	speed_index = clampi(index, 0, 4)
	var next_speed: float = [0.25, 0.5, 1.0, 1.5, 2.0][speed_index]
	var arena: RecaudadorArena = active_arena()
	if Engine.time_scale != next_speed and (arena == null or not arena.debug_practice): isolate(active_district())
	Engine.time_scale = next_speed

func _process(delta: float) -> void:
	if not enabled: return
	apply_cheats()
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = 0.2
		refresh_info()

func apply_cheats() -> void:
	var arena: RecaudadorArena = active_arena()
	var district: District = active_district() if arena == null else null
	var player: CharacterBody2D = arena.player if arena != null else (district.player if district != null else null)
	if god_mode or infinite_stamina or freeze_ai or core_god or freeze_cycle or Engine.time_scale != 1:
		if arena == null or not arena.debug_practice: isolate(active_district())
	if player is TopdownPlayer: player.debug_invincible = god_mode
	elif player is Player: player.health_component.debug_invincible = god_mode
	if player != null and infinite_stamina: player.stamina = 100
	if district != null:
		district.core.health_component.debug_invincible = core_god
		district.cycle.debug_frozen = freeze_cycle
	var targets: Array[Node] = []
	if freeze_ai:
		if arena != null and not arena.ending:
			targets.append(arena.boss)
			for index: int in range(arena.dynamics.sentinels.size()):
				if is_instance_valid(arena.dynamics.sentinels[index]): targets.append(arena.dynamics.sentinels[index])
		elif district != null:
			for enemy: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES):
				if district.is_ancestor_of(enemy): targets.append(enemy)
	for node: Variant in frozen.keys():
		if not is_instance_valid(node): frozen.erase(node)
		elif node not in targets:
			node.set_physics_process(false if arena != null and arena.ending and arena.is_ancestor_of(node) else frozen[node])
			frozen.erase(node)
	for node: Node in targets:
		if not frozen.has(node): frozen[node] = node.is_physics_processing()
		node.set_physics_process(false)

func notice(message: String) -> void:
	notices.append(message)
	if notices.size() > 12: notices.pop_front()
	panel.status.text = message

func suspend(node: Node) -> void:
	var snapshot: Dictionary = {"process": node.process_mode}
	if node is CanvasItem or node is CanvasLayer:
		snapshot["visible"] = node.visible
		node.hide()
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		snapshot["audio"] = node.stream_paused
		node.stream_paused = true
	suspended[node] = snapshot
	for child: Node in node.get_children(): suspend(child)
	node.process_mode = Node.PROCESS_MODE_DISABLED

func launch_boss(index: int) -> void:
	if not enabled or index < 0 or index >= 5: return
	var source: CharacterBody2D = actor()
	var gear: Dictionary = {}
	if source != null:
		for field: String in ["speed", "attack_damage", "attack_range", "attack_cooldown", "neural_regen"]: gear[field] = source.get(field)
		gear["drone_rank"] = source.drone_rank if source is TopdownPlayer else active_district().defenses.drone_rank
		if source is Player: gear.attack_damage += source.neural_damage
		var source_arena: RecaudadorArena = active_arena()
		gear["modules"] = source_arena.modules.snapshot() if source_arena != null else active_district().modules.snapshot()
	if not is_instance_valid(preview):
		preview_paused = was_paused if opened else get_tree().paused
		preview_settings = {"speed_index": speed_index, "time_scale": Engine.time_scale}
		for field: String in HELP_FIELDS: preview_settings[field] = get(field)
		close_panel()
		for child: Node in get_tree().root.get_children():
			if child is District or child is RecaudadorArena or child is MainMenu: suspend(child)
	else: preview.queue_free()
	close_panel()
	get_tree().paused = false
	selected_boss = index
	preview = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
	preview.zone_index = index
	preview.debug_practice = true
	if gear.has("modules"):
		for field: String in ["speed", "attack_damage", "attack_range", "attack_cooldown", "neural_regen", "drone_rank"]: preview.player.set(field, gear[field])
		preview.player.module_state = gear.modules
	preview.practice_exit_requested.connect(return_from_boss)
	preview.practice_retry_requested.connect(func() -> void: launch_boss(selected_boss))
	get_tree().root.add_child(preview)
	if loadout != 0: apply_loadout(preview)
	apply_cheats()
	notice("Práctica: %s. F1 permite cambiar fase, equipo o volver." % preview.zone.boss_title)

func return_from_boss() -> void:
	if not is_instance_valid(preview): return
	close_panel()
	preview.queue_free()
	preview = null
	for node: Variant in suspended:
		if not is_instance_valid(node): continue
		var snapshot: Dictionary = suspended[node]
		node.process_mode = snapshot.process
		if snapshot.has("visible"): node.visible = snapshot.visible
		if snapshot.has("audio"): node.stream_paused = snapshot.audio
	suspended.clear()
	for field: String in HELP_FIELDS: set(field, preview_settings.get(field, false))
	speed_index = int(preview_settings.get("speed_index", 2))
	Engine.time_scale = float(preview_settings.get("time_scale", 1.0))
	preview_settings.clear()
	get_tree().paused = preview_paused
	apply_cheats()
	open_panel()
	notice("Escena restaurada. El combate de práctica no da recompensas ni modifica el guardado.")

func launch_colony(index: int) -> void:
	if not enabled or index < 0 or index >= 5: return
	if is_instance_valid(preview): return_from_boss()
	close_panel()
	practice_launch = true
	CampaignRoute.pending.clear()
	CampaignRoute.resume_path = ""
	GamePreferences.current().briefing_requested = false
	get_tree().paused = false
	get_tree().change_scene_to_file(CampaignRoute.SCENES[index])

func apply_loadout(arena: RecaudadorArena) -> void:
	if loadout == 0: return
	var gear: ModuleSystem = arena.modules
	var rank: int = [1, 1, 3, 5][loadout]
	for id: String in gear.levels:
		gear.levels[id] = rank if id in ["drone", "tesla"] or loadout == 3 else 0
		gear.evolved[id] = loadout == 3
		gear.timers[id] = 0
	gear.equipped.assign(["drone"] if loadout == 1 else ["drone", "tesla"])
	if loadout == 1: gear.levels.tesla = 0
	for id: String in ModuleSystem.PASSIVE_IDS:
		gear.passives[id] = loadout > 1 and id in ["optic", "battery", "condenser", "recovery"]
		gear.passive_levels[id] = rank if gear.passives[id] else 0
	arena.player.attack_damage = [50, 50, 80, 150][loadout]
	arena.player.attack_cooldown = 0.25 if loadout == 3 else 0.4
	arena.player.drone_rank = 3 if loadout == 3 else 0
	arena.player.neural_regen = 15 if loadout == 3 else 0

func expose(boss: Recaudador) -> void:
	if boss is CoroSumergido:
		boss.exposure_left = 6
		boss.waves.clear()
		boss.marks.clear()
	elif boss is MadreCero:
		boss.exposure = 7
		boss.marks.clear()
	elif boss is SantaCaldera or boss is ElPrefecto:
		if boss is SantaCaldera: boss.heat_areas.clear()
		boss.change_state(Recaudador.State.RECOVER, 4)
	else: boss.stun()

func run_action(action: String) -> void:
	if not enabled: return
	if action == "close": close_panel(); return
	if action == "boss_launch": launch_boss(selected_boss); return
	if action == "return": return_from_boss(); return
	if action == "colony_launch": launch_colony(selected_zone); return
	if action == "report": save_report(); return
	if action == "capture": capture_screen(); return
	if action == "reset":
		for field: String in HELP_FIELDS: set(field, false)
		set_speed(2)
		apply_cheats()
		panel.refresh()
		notice("Ayudas desactivadas. Para recuperar el estado guardado, vuelve al menú y continúa.")
		return
	if action == "menu":
		if is_instance_valid(preview): return_from_boss()
		close_panel()
		for field: String in HELP_FIELDS: set(field, false)
		Engine.time_scale = 1
		speed_index = 2
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		return
	var arena: RecaudadorArena = active_arena()
	var district: District = active_district()
	if action == "boss_restart":
		launch_boss(arena.zone_index if arena != null else selected_boss)
		return
	if action in ["heal", "damage"]:
		var player: CharacterBody2D = actor()
		if player == null: notice("Primero entra en una arena o colonia."); return
		if arena != null and arena.ending: notice("Reinicia el jefe para volver a combatir."); return
		if arena == null or not arena.debug_practice: isolate(district)
		if action == "damage": player.attack_damage = int(panel.damage.value)
		else:
			player.health = 100
			player.stamina = 100
			if district != null and arena == null:
				district.core.health = district.core.health_component.maximum
				district.player.respawn_remaining = 0
				district.player.enabled = true
				district.session.finished = false
				district.session.won = false
				district.player.refresh_state()
		notice("Jugador actualizado.")
	elif action in ["phase_one", "phase_two", "boss_health", "expose", "special", "summon", "clear", "defeat", "loadout"]:
		if arena == null: notice("Primero entra en un jefe."); return
		if arena.ending: notice("Reinicia el encuentro para aplicar cambios."); return
		if not arena.debug_practice: isolate(district)
		var boss: Recaudador = arena.boss
		match action:
			"phase_one", "phase_two":
				boss.phase = 1 if action == "phase_one" else 2
				boss.health = boss.max_health if boss.phase == 1 else boss.max_health / 2
				boss.phase_changed.emit(boss.phase)
			"boss_health": boss.health = maxi(1, roundi(boss.max_health * panel.hp.value / 100))
			"expose": expose(boss)
			"defeat":
				expose(boss)
				boss.receive_hit(arena.player.position, boss.max_health)
			"loadout": apply_loadout(arena)
			"summon": arena.dynamics.request_reinforcements()
			"clear":
				arena.dynamics.clear_encounter()
				arena.dynamics.summon_cooldown = 20
				for child: Node in arena.world.get_children():
					if child is RecaudadorBullet: child.queue_free()
				if boss is CoroSumergido: boss.waves.clear(); boss.marks.clear()
				elif boss is MadreCero: boss.marks.clear()
				elif boss is SantaCaldera: boss.heat_areas.clear(); boss.change_state(Recaudador.State.RECOVER, 3)
			"special":
				if boss is SantaCaldera: boss.prepare_heat(true)
				elif boss is CoroSumergido: boss.add_marks()
				elif boss is MadreCero: boss.pulse = 0
				elif boss is ElPrefecto:
					boss.chained_thrust = false
					boss.charge_direction = (arena.player.position - boss.position).normalized()
					boss.change_state(Recaudador.State.CHARGE_WINDUP, 1)
				else: boss.charges_left = 1; boss.begin_charge()
		var descriptions: Dictionary = {"phase_one": "fase 1", "phase_two": "fase 2", "boss_health": "vida", "expose": "núcleo expuesto", "defeat": "derrotado", "loadout": "equipo aplicado", "summon": "refuerzos avisados", "clear": "peligros retirados", "special": "ataque preparado"}
		notice("Jefe actualizado: %s. Cierra F1 para continuar." % descriptions.get(action, action))
	else:
		if district == null or arena != null: notice("Esta acción necesita una colonia activa."); return
		isolate(district)
		colony_action(district, action)
	refresh_info()

func colony_action(world: District, action: String) -> void:
	match action:
		"scrap": world.bank.deposit(500)
		"xp": world.experience.gain(100)
		"build":
			world.core.restore({"tier": 3, "ordered": false, "progress": 0})
			world.core.health = world.core.health_component.maximum
			for site: ConstructionSite in world.construction.sites + world.civic.walls: site.complete_work()
			for site: ExpansionOutpost in world.expansion.sites: site.hp = 180; site.ordered = false; site.progress = 0
			world.expansion.refresh_energy()
		"day", "night":
			world.cycle.day = int(panel.day_number.value)
			world.cycle.phase = "DÍA" if action == "day" else "NOCHE"
			world.cycle.phase_remaining = world.cycle.config.day_duration if action == "day" else world.cycle.config.night_duration
			if action == "night": world.director.start(world.cycle.day)
			world.cycle.phase_changed.emit(world.cycle.phase, world.cycle.day)
		"tier":
			var tier: int = selected_tier + 1
			world.core.restore({"tier": tier, "ordered": false, "progress": 0})
			world.core.health = world.core.health_component.maximum
			for site: ConstructionSite in world.construction.sites + world.civic.walls:
				site.tier = tier
				site.upgrade_pending = false
				site.health_component.maximum = site.data.health * tier
				site.complete_work()
		"train":
			world.story.completed.assign([true, true, true])
			world.story.relay_ordered = true
			world.story.relay_progress = 6
			world.cycle.day = maxi(2, world.cycle.day)
			world.cycle.phase = "DÍA"
			world.cycle.phase_remaining = world.cycle.config.day_duration
			for site: ConstructionSite in world.construction.sites: site.complete_work()
			world.expansion.sites[2].hp = 180
			for portal: EnemyRepeater in world.civic.gates + world.expedition.repeaters: portal.restore(true)
			world.expedition.station.restore(true, true)
		"ally":
			var role: String = ["builder", "collector", "civilian", "ranger", "guardian", "technician", "medic"][selected_ally]
			if role in ["builder", "collector"]: world.colony.add_worker(StringName(role))
			elif role == "civilian": world.civic.villagers.append({"x": world.player.position.x, "side": -1.0 if world.player.position.x < 0 else 1.0})
			else:
				var building: String = {"ranger": "barracks", "guardian": "barracks", "technician": "generator", "medic": "medical"}[role]
				var hired: bool = false
				for site: ExpansionOutpost in world.expansion.sites:
					if site.spec.id == building and site.hp > 0 and site.staff_count() < site.staff_capacity():
						site.hire(role)
						hired = true
						break
				if not hired: notice("Primero termina el edificio de apoyo y deja una plaza libre."); return
		"spawn":
			var id: String = ["errante", "corredor", "blindado", "saltador", "artillero", "saboteador", "ariete"][selected_enemy]
			var side: float = -1 if spawn_side == 0 else 1
			for index: int in range(int(panel.spawn_count.value)):
				var enemy: SiegeEnemy = world.director.spawn_enemy(side, load("res://data/enemies/%s.tres" % id))
				enemy.position.x = clampf(world.player.position.x + side * (180 + index * 30), -GameRules.MAP_HALF_WIDTH + 40, GameRules.MAP_HALF_WIDTH - 40)
		"clear_enemies":
			for enemy: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES):
				if world.is_ancestor_of(enemy): enemy.queue_free()
		"teleport":
			var destinations: Array[float] = [0, -600, -world.civic.frontier(-1), world.civic.frontier(1), world.expedition.station.position.x]
			world.player.position = Vector2(destinations[teleport_target], GameRules.FLOOR_Y)
			world.player.velocity = Vector2.ZERO
			world.player.get_node("Camera2D").reset_smoothing()
		_: notice("Acción no disponible."); return
	world.presenter.publish()
	var descriptions: Dictionary = {"scrap": "chatarra añadida", "xp": "experiencia añadida", "build": "edificios terminados", "day": "día activado", "night": "oleada nocturna iniciada", "tier": "nivel de estructuras aplicado", "train": "tren preparado", "ally": "habitante añadido", "spawn": "enemigos creados", "clear_enemies": "enemigos retirados", "teleport": "teletransporte completado"}
	notice("Práctica sin guardar: %s." % descriptions.get(action, action))

func snapshot() -> Dictionary:
	var result: Dictionary = {"fps": Engine.get_frames_per_second(), "time_scale": Engine.time_scale, "god_mode": god_mode, "freeze_ai": freeze_ai, "actions": notices.duplicate()}
	var arena: RecaudadorArena = active_arena()
	if arena != null:
		result["scene"] = arena.zone.boss_title
		result["practice"] = arena.debug_practice
		result["boss"] = {"health": arena.boss.health, "maximum": arena.boss.max_health, "phase": arena.boss.phase, "state": Recaudador.State.keys()[arena.boss.state], "timer": arena.boss.timer, "decision": arena.boss.last_decision, "history": arena.boss.tactics.history.duplicate(), "escorts": arena.dynamics.sentinels.size()}
		result["player"] = {"health": arena.player.health, "stamina": arena.player.stamina, "x": arena.player.position.x, "y": arena.player.position.y}
	else:
		var world: District = active_district()
		if world != null:
			result["scene"] = world.zone.title
			result["practice"] = world.session.debug_practice
			result["colony"] = {"day": world.cycle.day, "phase": world.cycle.phase, "scrap": world.bank.scrap, "population": world.civic.population(), "core": world.core.health}
		else: result["scene"] = "Menú / escena sin contexto jugable"
	return result

func refresh_info() -> void:
	var info: Dictionary = snapshot()
	panel.context_label.text = str(info.scene) + (" · PRÁCTICA SIN GUARDAR" if info.get("practice", false) else " · Abrir el panel no modifica el guardado")
	panel.inspector.text = JSON.stringify(info, "  ")
	var in_arena: bool = info.has("boss")
	badge.text = "F1" if in_arena else ("F1 · PRÁCTICA" if info.get("practice", false) else "Depuración [F1]")
	badge.tooltip_text = "Laboratorio de jefes · Depuración" if in_arena else ""
	badge.position = Vector2(603, 332) if in_arena else Vector2(505, 338)
	badge.size = Vector2(31, 20) if in_arena else Vector2(131, 20)

func save_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://debug"))
	var file: FileAccess = FileAccess.open("user://debug/informe.json", FileAccess.WRITE)
	if file == null: notice("No se pudo guardar el informe."); return
	file.store_string(JSON.stringify(snapshot(), "  "))
	file.close()
	notice("Informe: " + ProjectSettings.globalize_path("user://debug/informe.json"))

func capture_screen() -> void:
	if DisplayServer.get_name() == "headless": notice("La captura necesita una ventana gráfica."); return
	close_panel()
	badge.hide()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://debug"))
	var name: String = "user://debug/captura_" + Time.get_datetime_string_from_system().replace(":", "-") + ".png"
	var error: Error = get_viewport().get_texture().get_image().save_png(name)
	open_panel()
	notice("Captura: " + ProjectSettings.globalize_path(name) if error == OK else "No se pudo guardar la captura.")
