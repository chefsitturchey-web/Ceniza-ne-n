extends SceneTree

var checks: int = 0
var failures: int = 0
var launched: Array[bool] = []
const SETTINGS: String = "user://opciones_test.cfg"
const CHECKPOINT: String = "user://menu_partida_test.json"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func write_checkpoint(text: String) -> void:
	var file: FileAccess = FileAccess.open(CHECKPOINT, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run_checks() -> void:
	var prefs: GamePreferences = GamePreferences.current() as GamePreferences
	var previous_path: String = prefs.config_path
	var previous_values: Dictionary = prefs.values.duplicate()
	prefs.config_path = SETTINGS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CHECKPOINT))
	prefs.load_settings()
	verify(prefs.values == GamePreferences.DEFAULTS, "Valores por defecto sin archivo")
	verify(not prefs.update_value("music", -1) and not prefs.update_value("master", NAN), "Rechaza volúmenes fuera de rango")
	verify(not prefs.update_value("window_size", 99) and not prefs.update_value("particles", "sí"), "Rechaza preferencias de tipo incorrecto")
	verify(prefs.update_value("music", 0.4) and prefs.update_value("sfx", 0.7), "Guarda volúmenes independientes")
	var music_bus: int = AudioServer.get_bus_index("Music")
	verify(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), float(prefs.base_volumes.Music) + linear_to_db(0.4)), "Atenúa sobre el volumen original del bus")
	verify(prefs.update_value("master", 0.0) and AudioServer.is_bus_mute(0), "Cero silencia el bus general")
	prefs.update_value("master", 1.0)
	prefs.values = GamePreferences.DEFAULTS.duplicate()
	prefs.load_settings()
	verify(is_equal_approx(prefs.values.music, 0.4) and is_equal_approx(prefs.values.sfx, 0.7), "Las opciones sobreviven una recarga")
	var malformed: ConfigFile = ConfigFile.new()
	malformed.set_value("preferences", "music", "corrupto")
	malformed.set_value("preferences", "particles", false)
	malformed.set_value("preferences", "window_size", -1)
	malformed.save(SETTINGS)
	prefs.load_settings()
	verify(prefs.values.music == 1.0 and prefs.values.window_size == 0 and not prefs.particles, "Valores inválidos usan defaults; conserva opciones válidas")
	prefs.values = GamePreferences.DEFAULTS.duplicate()
	prefs.apply_all(false)
	var menu: MainMenu = load("res://ui/main_menu.tscn").instantiate() as MainMenu
	menu.checkpoint_path = CHECKPOINT
	menu.navigation_enabled = false
	root.add_child(menu)
	menu.launch_requested.connect(func(fresh: bool) -> void: launched.append(fresh))
	verify(menu.continue_button.disabled, "Continuar desactivado sin guardado")
	menu._continue_game()
	verify(launched.is_empty(), "No intenta continuar sin guardado")
	menu.options.open_panel()
	verify(paused and menu.options.opened, "Opciones del menú pausan el fondo")
	menu.options.sliders.music.slider.value = 35
	verify(is_equal_approx(prefs.values.music, 0.35), "Slider modifica el canal correcto")
	menu.options.close_panel()
	verify(not paused, "Cerrar opciones devuelve el menú activo")
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	await process_frame
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = CHECKPOINT
	world.session.add_child(save)
	verify(save.save_game(), "Preparar checkpoint válido sin tocar la partida real")
	menu.refresh_checkpoint()
	verify(not menu.continue_button.disabled, "Continuar detecta un checkpoint compatible")
	var exact: String = FileAccess.get_file_as_string(CHECKPOINT)
	menu._continue_game()
	verify(launched == [false] and FileAccess.get_file_as_string(CHECKPOINT) == exact, "Continuar no modifica el archivo")
	menu.request_new_game()
	verify(menu.confirm.visible and FileAccess.get_file_as_string(CHECKPOINT) == exact, "Nueva partida pide elección dentro del juego sin borrar nada")
	menu.confirm.hide()
	menu._launch(true)
	verify(launched == [false, true] and not FileAccess.file_exists(CHECKPOINT), "Nueva partida libera el slot después del archivo")
	verify(FileAccess.get_file_as_string(CHECKPOINT + ".anterior") == exact, "La copia anterior conserva todos los bytes")
	write_checkpoint("{roto")
	menu.refresh_checkpoint()
	verify(menu.continue_button.disabled and FileAccess.get_file_as_string(CHECKPOINT) == "{roto", "Un archivo ilegible no se elimina al abrir el menú")
	paused = true
	world.options.open_panel()
	world.options.close_panel()
	world.session._process(0)
	verify(paused, "Cerrar opciones desde pausa no reanuda la colonia")
	paused = false
	var before: int = DebrisEmitter.live_count
	prefs.update_value("particles", false)
	world.player.visual.effects.emit_dust(world.player.position, 4)
	verify(DebrisEmitter.live_count == before, "Desactivar partículas evita crear nodos decorativos")
	prefs.update_value("particles", true)
	world.free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		menu.refresh_checkpoint()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/menu-principal.png")
		menu.options.open_panel()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/opciones.png")
		menu.options.close_panel()
	menu.free()
	prefs.config_path = previous_path
	prefs.values = previous_values
	prefs.apply_all(false)
	for path: String in [SETTINGS, CHECKPOINT, CHECKPOINT + ".anterior"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await process_frame
	print("Menú y opciones: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
