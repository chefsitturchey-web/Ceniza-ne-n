extends SceneTree
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var prefs: GamePreferences = GamePreferences.current()
	var old: Dictionary = prefs.values.duplicate()
	for index: int in 5:
		var view: DistrictView = DistrictView.new()
		view.zone = CampaignRoute.zone(index)
		view.set_process(false)
		root.add_child(view)
		# Esta prueba solo necesita el fondo; evita el dibujo de combate sin defensas.
		view.hide()
		var backdrop: Node2D = view.get_node("AnimatedBackdrop")
		var mask: Image = backdrop.masks[view.zone.id].get_image()
		verify(mask.get_size() == Vector2i(view.district_background.get_size()), "Mascara medida sobre la capa: " + view.zone.id)
		var kinds: Dictionary = {}
		for y: int in mask.get_height():
			for x: int in mask.get_width():
				var kind: int = roundi(mask.get_pixel(x, y).r * 255 / 16)
				if kind > 0: kinds[kind] = true
		verify(kinds.size() >= 3, "Varios elementos animados reales por distrito")
		if index == 3: verify(kinds.has(1) and kinds.has(2), "Ciudadela anima cascadas y agua")
		if index == 0: verify(kinds.has(7), "Ventiladores de Periferia enmascarados")
		prefs.values.particles = true
		prefs.values.reduced_flashes = false
		view.time = 2.5
		backdrop._process(0)
		verify(backdrop.active and backdrop.shader_material.get_shader_parameter("enabled") == 1.0, "Animacion activa")
		verify(backdrop.shader_material.get_shader_parameter("clock") == 2.5, "Tiempo del fondo enviado al shader")
		prefs.values.particles = false
		backdrop._process(0)
		verify(not backdrop.active and backdrop.shader_material.get_shader_parameter("enabled") == 0.0 and WorldParticles.budget(24) == 0, "Sin particulas se apagan shader y detalles")
		prefs.values.reduced_flashes = true
		backdrop._process(0)
		verify(backdrop.shader_material.get_shader_parameter("steady") == 1.0, "Shader respeta destellos reducidos")
		view.free()
	prefs.values = old
	print("PASS: fondos animados; fallos: %d" % failures)
	quit(1 if failures else 0)
