extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/validation/latest/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/validation/latest"))
	var preferences: GamePreferences = GamePreferences.current()
	var old_values: Dictionary = preferences.values.duplicate()
	var shifted: Array[float] = []
	for scroll: float in [DistrictDepth.FAR_SCROLL, DistrictDepth.ARCHITECTURE_SCROLL, DistrictDepth.NEAR_SCROLL]:
		shifted.append(DistrictDepth.origin(100, 0, 640, scroll) - DistrictDepth.origin(0, 0, 640, scroll) - 100)
	verify(absf(shifted[0]) < absf(shifted[1]) and absf(shifted[1]) < absf(shifted[2]), "Tres planos tienen velocidades distintas respecto a la cámara")
	for index: int in 5:
		var world: District = load(CampaignRoute.SCENES[index]).instantiate()
		(world.get_node("Session") as SessionController).persistence_enabled = false
		root.add_child(world)
		world.story.present_dialogue = false
		world.session.set_process(false)
		world.player.set_physics_process(false)
		world.experience.present_choices = false
		world.view.set_process(false)
		var id: String = world.zone.id
		var image: Image = world.view.district_background.get_image()
		var clear_pixels: int = 0
		for y: int in range(0, int(image.get_height() * 0.6), 16):
			for x: int in range(0, image.get_width(), 16):
				if image.get_pixel(x, y).a < 0.01: clear_pixels += 1
		verify(clear_pixels > 20 and image.get_used_rect().size.y > 200, "La arquitectura conserva edificios y deja ver el plano lejano: " + id)
		verify(FileAccess.file_exists("res://assets/world/backgrounds/sources/" + ["periphery_alive_v2", "foundry", "flooded", "citadel", "network"][index] + ".ase"), "Fuente editable de la máscara: " + id)
		world.view._process(1.0)
		var previous: float = world.view.time
		world.view.set_process(true)
		paused = true
		await create_timer(0.04, true).timeout
		verify(world.view.time == previous, "La pausa detiene humo, paños y maquinaria: " + id)
		paused = false
		world.view.set_process(false)
		world.player.position.x = -140
		var camera: Camera2D = world.player.get_node("Camera2D")
		camera.reset_smoothing()
		world.view.time = 3.0
		world.view.queue_redraw()
		await picture("capas_" + id)
		var start_position: Vector2 = world.player.position
		preferences.values.particles = false
		preferences.values.reduced_flashes = true
		world.view._process(0.4)
		await picture("capas_accesibles_" + id)
		verify(world.player.position == start_position, "La presentación no desplaza al jugador ni altera la física: " + id)
		preferences.values = old_values.duplicate()
		world.free()
		await process_frame
	for index: int in 6:
		var texture: Texture2D = BossBattleHud.BOSS_FRAMES[index] if index < 5 else BossBattleHud.PLAYER_FRAME
		var image: Image = texture.get_image()
		var window: Rect2i = Rect2i(80, 44, 836, 18) if index < 5 else Rect2i(32, 14, 336, 14)
		var clear: bool = true
		for y: int in range(window.position.y, window.end.y):
			for x: int in range(window.position.x, window.end.x):
				if image.get_pixel(x, y).a > 0: clear = false
		verify(clear and image.get_used_rect().has_area(), "El marco pintado no cubre la vida y conserva sus ornamentos: %d" % index)
	print("Profundidad y marcos: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
