class_name WorldAtmosphere
extends Node2D
## Pool de tres teselas: los emisores comparten exactamente el parallax del arte.
var view: DistrictView
var arena_mode: bool = false
var theme_id: String = "periphery"
var chimneys: Array[Node2D] = []
var vents: Array[Node2D] = []
var clock: float = 0
var redraw_clock: float = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for index: int in (15 if not arena_mode else 0):
		var emitter: Node2D = WorldParticles.smoke(0.9)
		emitter.name = "Chimney%d" % index
		add_child(emitter)
		chimneys.append(emitter)
	for index: int in 3:
		var emitter: Node2D = WorldParticles.smoke(0.45)
		emitter.name = "PipeSteam%d" % index
		emitter.modulate = Color(0.7, 0.92, 1, 0.5)
		add_child(emitter)
		vents.append(emitter)

func _process(delta: float) -> void:
	clock += delta
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0
	if not arena_mode and view != null:
		theme_id = view.zone.id if view.zone != null else "periphery"
		var width: float = 512 if theme_id == "periphery" else 640
		var height: float = 288 if theme_id == "periphery" else 360
		var top: float = GameRules.FLOOR_Y - (216 if theme_id == "periphery" else 360)
		var mouths: Array = [Vector2(180.0 / 1672, 73.0 / 941), Vector2(640.0 / 1672, 122.0 / 941), Vector2(1068.0 / 1672, 140.0 / 941), Vector2(1415.0 / 1672, 170.0 / 941)]
		if theme_id == "foundry": mouths = BackdropLife.ANCHORS.foundry
		elif theme_id == "network": mouths = BackdropLife.ANCHORS.network.slice(0, 2)
		elif theme_id != "periphery": mouths = []
		var first: int = floori(camera_x * DistrictDepth.ARCHITECTURE_SCROLL / width)
		for index: int in chimneys.size():
			var tile: int = first - 1 + index / 5
			var mouth_index: int = index % 5
			var emitter: Node2D = chimneys[index]
			var active: bool = mouth_index < mouths.size()
			if active:
				var mouth: Vector2 = mouths[mouth_index]
				var x: float = (1 - mouth.x if posmod(tile, 2) == 1 else mouth.x) * width
				emitter.position = Vector2(DistrictDepth.origin(camera_x, tile, width, DistrictDepth.ARCHITECTURE_SCROLL) + x, top + mouth.y * height)
				active = absf(emitter.position.x - camera_x) < 620
				# Deriva lenta; el CPU recibe una brisa equivalente a turbulencia leve.
				if emitter is CPUParticles2D: emitter.gravity.x = 0.7 + sin(clock * 0.4 + index) * 0.35
			WorldParticles.configure(emitter, active)
	for index: int in vents.size():
		var emitter: Node2D = vents[index]
		if arena_mode:
			emitter.position = Vector2(42 + index * 278, 75)
		else:
			var tile: int = floori(camera_x * DistrictDepth.NEAR_SCROLL / 720) - 1 + index
			emitter.position = Vector2(DistrictDepth.origin(camera_x, tile, 720, DistrictDepth.NEAR_SCROLL) + 201, 254)
		WorldParticles.configure(emitter, fposmod(clock + index * 2.7, 11) < 6, 9)
	redraw_clock += delta
	if redraw_clock >= 0.05:
		redraw_clock = 0
		queue_redraw()

func _draw() -> void:
	if not GamePreferences.current().particles: return
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: float = camera.get_screen_center_position().x if camera != null else 320
	var night: float = float(view.light.lamps) if view != null else 0.8
	# Dos bancos de bruma con movimiento y profundidad distintos, alfa muy baja.
	for layer: int in (1 if GamePreferences.current().reduced_flashes else 2):
		for index: int in 7:
			var x: float = center - 470 + fposmod(index * 151 + clock * (3 + layer * 2) - center * (0.08 + layer * 0.05), 1050)
			var y: float = (205 if not arena_mode else 300) + layer * 36 + sin(clock * 0.12 + index) * 6
			draw_texture_rect(WorldParticles.smoke_texture(), Rect2(Vector2(x, y).round(), Vector2(175, 32)), false, Color(0.57, 0.7, 0.77, 0.045 + night * 0.035))
	# Polvo suspendido en los conos reales de las farolas; chispas intermitentes.
	if view != null:
		for entry: Array in DistrictView.PROPS:
			if entry[0] != DistrictView.LAMP or absf(float(entry[1]) - center) > 480: continue
			var bulb: Vector2 = Vector2(float(entry[1]) + DistrictView.LAMP.get_width() * 0.5 - 4, GameRules.FLOOR_Y - DistrictView.LAMP.get_height() + 4)
			for index: int in WorldParticles.budget(12):
				var phase: float = clock * 0.17 + index * 2.3
				var at: Vector2 = bulb + Vector2(sin(phase) * 13, 8 + fposmod(index * 7 - clock * 3, 34))
				draw_rect(Rect2(at.round(), Vector2.ONE), Color(1, 0.82, 0.53, night * 0.45))
			if not GamePreferences.current().reduced_flashes and fposmod(clock + float(entry[1]) * 0.01, 13) < 0.32:
				for spark: int in 4:
					var t: float = fposmod(clock * 2 + spark * 0.04, 0.6)
					var at: Vector2 = bulb + Vector2((spark - 2) * t * 15, t * t * 65)
					draw_rect(Rect2(at.round(), Vector2(1, 2)), Color(1, 0.72, 0.33, 0.8 - t))
