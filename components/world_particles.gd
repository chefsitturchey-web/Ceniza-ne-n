class_name WorldParticles
extends RefCounted
## Recursos pequenos compartidos. Sin ruido de textura ni filtrado lineal.
static var puff: Texture2D
static var light_texture: Texture2D

static func smoke_texture() -> Texture2D:
	if puff == null:
		var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y: int in 16:
			for x: int in 16:
				var radius: float = Vector2(x - 7.5, y - 7.5).length() / 7.5
				var alpha: float = floorf(clampf(1.0 - radius, 0, 1) * 5) / 5.0
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
		puff = ImageTexture.create_from_image(image)
	return puff

static func glow_texture() -> Texture2D:
	if light_texture == null:
		var gradient: Gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		var texture: GradientTexture2D = GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 64
		texture.height = 64
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1, 0.5)
		light_texture = texture
	return light_texture

static func smoke(depth: float = 1.0) -> Node2D:
	var gpu: GPUParticles2D = GPUParticles2D.new()
	gpu.amount = 18
	gpu.lifetime = 5.5
	gpu.preprocess = 3.0
	gpu.fixed_fps = 20
	gpu.local_coords = true
	gpu.texture = smoke_texture()
	gpu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gpu.visibility_rect = Rect2(-70, -140, 180, 180)
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(0.24, -1, 0)
	mat.spread = 18
	mat.initial_velocity_min = 6 * depth
	mat.initial_velocity_max = 11 * depth
	mat.gravity = Vector3(1.1 * depth, -0.4, 0)
	mat.angular_velocity_min = -9
	mat.angular_velocity_max = 9
	mat.scale_min = 0.65 * depth
	mat.scale_max = 1.0 * depth
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(0.65, 1.5))
	curve.add_point(Vector2(1, 2.0))
	var scale_curve: CurveTexture = CurveTexture.new()
	scale_curve.curve = curve
	mat.scale_curve = scale_curve
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.12, 0.65, 1])
	gradient.colors = PackedColorArray([Color(0.5, 0.57, 0.6, 0), Color(0.52, 0.59, 0.62, 0.65), Color(0.64, 0.69, 0.7, 0.3), Color(0.68, 0.72, 0.75, 0)])
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = gradient
	mat.color_ramp = ramp
	gpu.process_material = mat
	# Compatibility, web y Android usan el mismo perfil, sin compute shaders.
	if RenderingServer.get_current_rendering_method() == "gl_compatibility" or OS.has_feature("mobile") or OS.has_feature("web"):
		var cpu: CPUParticles2D = CPUParticles2D.new()
		cpu.convert_from_particles(gpu)
		cpu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gpu.free()
		return cpu
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 0.3
	mat.turbulence_influence_min = 0.02
	mat.turbulence_influence_max = 0.06
	return gpu

static func budget(normal: int) -> int:
	if not GamePreferences.current().particles: return 0
	return maxi(1, normal / 3) if GamePreferences.current().reduced_flashes else normal

static func configure(emitter: Node2D, active: bool, normal: int = 18) -> void:
	var count: int = budget(normal)
	var target: int = maxi(1, count)
	if emitter.get("amount") != target: emitter.set("amount", target)
	emitter.set("emitting", active and count > 0)
	emitter.visible = active and count > 0
