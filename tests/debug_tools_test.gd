extends SceneTree
const SAVE: String = "user://debug_checkpoint_test.json"
var checks: int = 0
var failures: int = 0
var capture: bool = false
var debug: GameDebug

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	debug._input(event)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/debug/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/debug"))
	debug = root.get_node("DebugTools") as GameDebug
	verify(debug.enabled and debug.panel.tabs.get_tab_count() == 4, "Autoload ofrece cuatro páginas de herramientas")
	var menu: MainMenu = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	key(KEY_F1)
	verify(debug.opened and paused and GamePreferences.current().debug_modal, "F1 abre y pausa desde menú")
	key(KEY_F1)
	verify(not debug.opened and not paused and not GamePreferences.current().debug_modal, "F1 cierra y devuelve pausa anterior")
	var actual_key: InputEventKey = InputEventKey.new()
	actual_key.physical_keycode = KEY_F1
	actual_key.keycode = KEY_F1
	actual_key.pressed = true
	await process_frame
	Input.parse_input_event(actual_key)
	await process_frame
	verify(debug.opened, "F1 también llega a través del sistema real de entrada")
	var release_key: InputEventKey = actual_key.duplicate() as InputEventKey
	release_key.pressed = false
	Input.parse_input_event(release_key)
	var escape_key: InputEventKey = InputEventKey.new()
	escape_key.physical_keycode = KEY_ESCAPE
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	Input.parse_input_event(escape_key)
	await process_frame
	verify(not debug.opened, "Esc real cierra solo el laboratorio")
	var release_escape: InputEventKey = escape_key.duplicate() as InputEventKey
	release_escape.pressed = false
	Input.parse_input_event(release_escape)
	paused = true
	debug.open_panel()
	debug.close_panel()
	verify(paused, "Abrir desde otra pausa no la elimina")
	paused = false
	for index: int in range(5):
		debug.open_panel()
		debug.launch_boss(index)
		var arena: RecaudadorArena = debug.preview
		arena.player.set_physics_process(false)
		arena.boss.set_physics_process(false)
		arena.modules.set_physics_process(false)
		arena.set_process(false)
		verify(arena.zone_index == index and arena.debug_practice and not debug.opened, "Acceso directo al jefe %d" % index)
		verify(menu.process_mode == Node.PROCESS_MODE_DISABLED and not menu.visible and (menu.music.stream_paused or not menu.music.playing), "Escena y audio originales suspendidos: %d" % index)
		debug.open_panel()
		debug.run_action("phase_two")
		verify(arena.boss.phase == 2 and arena.boss.health == arena.boss.max_health / 2, "Fase 2 real: %d" % index)
		debug.run_action("phase_one")
		verify(arena.boss.phase == 1 and arena.boss.health == arena.boss.max_health, "Restaurar fase 1: %d" % index)
		debug.panel.hp.value = 25
		debug.run_action("boss_health")
		verify(arena.boss.health == arena.boss.max_health / 4, "Porcentaje de vida: %d" % index)
		debug.set_toggle("god_mode", true)
		arena.player.take_damage(1000)
		verify(arena.player.health == 100 and not arena.ending, "Invulnerabilidad impide morir: %d" % index)
		debug.set_toggle("infinite_stamina", true)
		arena.player.stamina = 0
		debug.apply_cheats()
		verify(arena.player.stamina == 100, "Resistencia se restituye: %d" % index)
		debug.loadout = 3
		debug.run_action("loadout")
		verify(arena.modules.levels.drone == 5 and arena.modules.evolved.tesla and arena.modules.equipped.size() == 2, "Equipo máximo conserva límite de ranuras: %d" % index)
		debug.panel.damage.value = 345
		debug.run_action("damage")
		verify(arena.player.attack_damage == 345, "Daño editable: %d" % index)
		debug.run_action("expose")
		verify(arena.boss.core_exposed, "Exposición compatible con jefe %d" % index)
		debug.run_action("special")
		debug.run_action("summon")
		verify(arena.dynamics.summons.size() <= 2, "Refuerzos conservan límite: %d" % index)
		debug.run_action("clear")
		verify(arena.dynamics.summons.is_empty(), "Limpieza retira llegadas pendientes: %d" % index)
		if index == 2: verify((arena.boss as CoroSumergido).active_links() == 3, "Limpiar peligros no destruye las antenas del Coro")
		debug.set_speed(0)
		verify(Engine.time_scale == 0.25, "Cámara lenta: %d" % index)
		debug.set_toggle("draw_debug", true)
		if index == 0:
			debug.close_panel()
			await process_frame
			verify(debug.geometry.visible, "Vista de colisiones activa mientras se juega")
			await picture("rutas")
			debug.open_panel()
		await picture("jefe_%d" % index)
		debug.return_from_boss()
		verify(debug.opened and menu.process_mode == Node.PROCESS_MODE_ALWAYS and menu.visible and not menu.music.stream_paused, "Volver restaura escena y audio: %d" % index)
		verify(not debug.god_mode and Engine.time_scale == 1, "Ayudas de práctica no se propagan a escena original: %d" % index)
		debug.close_panel()
		await process_frame
	debug.loadout = 0
	menu.free()
	current_scene = null
	GamePreferences.current().briefing_requested = false
	var world: District = load("res://levels/main.tscn").instantiate()
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	current_scene = world
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.neural.kills = 18
	world.neural.install("blade")
	world.neural.install("blade")
	world.neural.install("drone")
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = SAVE
	world.session.add_child(save)
	world.session.save_system = save
	world.session.persistence_enabled = true
	verify(save.save_game(), "Checkpoint de prueba válido antes de usar herramientas")
	var original: String = FileAccess.get_file_as_string(SAVE)
	debug.open_panel()
	verify(world.session.save_system == save and world.session.persistence_enabled, "Abrir el panel conserva persistencia y contenido")
	debug.run_action("phase_two")
	verify(world.session.save_system == save, "Acción incompatible no interviene la colonia")
	debug.launch_boss(4)
	verify(debug.preview.player.attack_damage == world.player.attack_damage + world.player.neural_damage and debug.preview.player.drone_rank == world.defenses.drone_rank, "Conservar equipo incluye daño neuronal y rango de dron")
	debug.open_panel()
	debug.run_action("defeat")
	verify(debug.preview.ending and world.bank.scrap == 90, "Victoria de práctica no recompensa la colonia de fondo")
	debug.preview.return_to_menu()
	verify(debug.preview == null and world.session.save_system == save and world.bank.scrap == 90, "Salir del jefe restaura colonia y su persistencia original")
	verify(FileAccess.get_file_as_string(SAVE) == original, "Probar y derrotar jefe no toca el checkpoint")
	debug.close_panel()
	world.story.novel.play(VisualStory.scene(0, "opening"))
	debug.open_panel()
	var escape: InputEventAction = InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	world.story.novel._input(escape)
	verify(world.story.novel.opened, "Esc del laboratorio no cierra la novela debajo")
	debug.close_panel()
	world.story.novel.close_panel()
	paused = false
	debug.open_panel()
	debug.panel.tabs.current_tab = 2
	debug.run_action("scrap")
	verify(world.bank.scrap == 590 and world.session.save_system == null and world.session.debug_practice, "Intervenir aísla guardado antes de cambiar recursos")
	world.session.on_phase_changed("DÍA", 2)
	verify(FileAccess.get_file_as_string(SAVE) == original, "Cambio de fase no sobrescribe checkpoint después del truco")
	debug.set_toggle("god_mode", true)
	debug.set_toggle("core_god", true)
	world.player.take_damage(9999)
	world.core.take_damage(9999)
	verify(world.player.health == 100 and world.core.health == world.core.health_component.maximum, "Invulnerabilidad de jugador y núcleo")
	debug.set_toggle("freeze_cycle", true)
	var remaining: float = world.cycle.phase_remaining
	world.cycle.update_phase(1000)
	verify(world.cycle.phase_remaining == remaining, "Reloj congelado sin cambiar duración configurada")
	debug.run_action("build")
	verify(world.core.tier == 3 and world.construction.sites[0].hp > 0 and world.expansion.sites[2].hp == 180, "Construcción instantánea con base y servicios")
	debug.selected_tier = 1
	debug.run_action("tier")
	verify(world.core.tier == 2 and world.construction.sites[0].tier == 2 and world.construction.sites[0].hp == world.construction.sites[0].max_hp, "Nivel elegido sincroniza diseño y salud de defensas")
	debug.selected_ally = 3
	debug.run_action("ally")
	verify(world.expansion.sites[0].staff_count() == 1, "Crear aliado respeta su hogar")
	debug.selected_ally = 2
	debug.run_action("ally")
	verify(world.civic.villagers.size() == 1, "Crear civil sin profesión")
	debug.panel.spawn_count.value = 2
	debug.selected_enemy = 2
	debug.run_action("spawn")
	verify(get_nodes_in_group(GameRules.ENEMIES).size() == 2, "Crear enemigos del tipo y cantidad elegidos")
	debug.set_toggle("freeze_ai", true)
	for enemy: Node in get_nodes_in_group(GameRules.ENEMIES): verify(not enemy.is_physics_processing(), "IA congelada preserva actor")
	debug.set_toggle("freeze_ai", false)
	for enemy: Node in get_nodes_in_group(GameRules.ENEMIES): verify(enemy.is_physics_processing(), "Descongelar restaura procesamiento")
	debug.run_action("clear_enemies")
	await process_frame
	verify(get_nodes_in_group(GameRules.ENEMIES).is_empty(), "Retirar enemigos no deja actores")
	debug.run_action("train")
	verify(world.expedition.all_destroyed() and world.expedition.station.train_arrived and world.story.ready_to_travel(), "Preparar tren completa requisitos de práctica")
	debug.teleport_target = 1
	debug.run_action("teleport")
	verify(world.player.position.x == -600, "Teletransporte a destino elegido")
	debug.run_action("xp")
	verify(world.experience.level > 1 and world.experience.pending > 0, "Experiencia concede niveles y elecciones reales")
	debug.run_action("report")
	verify(FileAccess.file_exists("user://debug/informe.json") and JSON.parse_string(FileAccess.get_file_as_string("user://debug/informe.json")) is Dictionary, "Informe JSON legible en carpeta de usuario")
	verify(FileAccess.get_file_as_string(SAVE) == original, "Todas las herramientas conservan checkpoint original")
	await picture("colonia")
	debug.run_action("reset")
	verify(not debug.god_mode and not world.player.health_component.debug_invincible and not world.cycle.debug_frozen and Engine.time_scale == 1, "Reset desactiva ayudas sin reactivar guardado intervenido")
	debug.close_panel()
	debug.launch_colony(3)
	await process_frame
	await process_frame
	world = current_scene as District
	verify(world != null and world.zone_index == 3 and world.session.debug_practice and world.session.save_system == null and not debug.practice_launch, "Nueva colonia consume modo práctica antes de inicializar guardado")
	debug.open_panel()
	debug.panel.tabs.current_tab = 1
	await picture("laboratorio")
	debug.close_panel()
	world.free()
	current_scene = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	await process_frame
	verify(debug.suspended.is_empty() and not debug.opened and not paused, "Salir no deja pausa ni referencias suspendidas")
	print("Laboratorio de depuración: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
