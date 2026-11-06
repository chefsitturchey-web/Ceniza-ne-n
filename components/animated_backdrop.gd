extends Node2D
## Tres lienzos persistentes separan cielo, arte animado y detalles sin copiar texturas.
const MOTION: Shader = preload("res://components/backdrop_motion.gdshader")
var view: DistrictView
var shader_material: ShaderMaterial = ShaderMaterial.new()
var zone_id: String = ""
var sky: Node2D = Node2D.new()
var details: Node2D = Node2D.new()
var masks: Dictionary = {}
var active: bool = true
var tick: float = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id: String in ["periphery", "foundry", "flooded", "citadel", "network"]:
		# Mascaras lossless sin source_color: se leen como datos, no como luz.
		masks[id] = load("res://assets/world/backgrounds/masks/%s.png" % id) as Texture2D
	shader_material.shader = MOTION
	material = shader_material
	sky.show_behind_parent = true
	add_child(sky)
	sky.draw.connect(_draw_sky)
	add_child(details)
	details.draw.connect(_draw_details)
	_process(0)

func _process(delta: float) -> void:
	var id: String = view.zone.id if view.zone != null else "periphery"
	if id != zone_id:
		zone_id = id
		shader_material.set_shader_parameter("motion_mask", masks[id])
		shader_material.set_shader_parameter("fans", PackedVector4Array([Vector4(191.5, 319.5, 17, 0.9), Vector4(852.5, 333.5, 17, -0.8)]))
		shader_material.set_shader_parameter("fall_light", Vector3(1, 0.72, 0.27) if id == "foundry" else Vector3(0.77, 0.9, 0.97))
	active = WorldParticles.budget(1) > 0
	shader_material.set_shader_parameter("enabled", float(active))
	shader_material.set_shader_parameter("clock", floorf(view.time * 12) / 12)
	shader_material.set_shader_parameter("night", float(view.light.lamps))
	shader_material.set_shader_parameter("steady", float(GamePreferences.current().reduced_flashes))
	tick += delta
	if tick >= 0.05 or delta == 0:
		tick = 0
		queue_redraw()
		sky.queue_redraw()
		details.queue_redraw()

func camera_x() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	return camera.get_screen_center_position().x if camera != null else 0.0

func _draw_sky() -> void:
	# Bandas de color discretas en lugar de gradiente borroso.
	for band: int in 32:
		sky.draw_rect(Rect2(-GameRules.MAP_HALF_WIDTH - 400, -420 + band * 22, GameRules.MAP_HALF_WIDTH * 2 + 800, 22), view.light.sky_top.lerp(view.light.sky_bottom, band / 31.0))
	DistrictDepth.draw_far(sky, camera_x(), view.time, zone_id, view.light.sky_bottom)

func _draw() -> void:
	DistrictDepth.draw_architecture(self, view.district_background, camera_x(), view.time, zone_id, false)

func _draw_details() -> void:
	DistrictDepth.draw_architecture(details, view.district_background, camera_x(), view.time, zone_id, true, false)
