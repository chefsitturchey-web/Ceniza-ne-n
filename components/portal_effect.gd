class_name PortalEffect
extends Node2D
## El portal enemigo se activa al pedir refuerzos; no es una puerta de viaje.
var surface: Sprite2D = Sprite2D.new()
var lamp: PointLight2D = PointLight2D.new()
var hum: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var shader_material: ShaderMaterial = ShaderMaterial.new()
var clock: float = 0
var pulse: float = 0
var active: bool = true
static var hum_stream: AudioStreamWAV

static func sound() -> AudioStreamWAV:
	if hum_stream == null:
		hum_stream = AudioStreamWAV.new()
		hum_stream.format = AudioStreamWAV.FORMAT_16_BITS
		hum_stream.mix_rate = 11025
		hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		hum_stream.loop_end = 11025
		var bytes: PackedByteArray = PackedByteArray()
		bytes.resize(22050)
		for index: int in 11025:
			var t: float = float(index) / 11025
			var sample: float = sin(TAU * 55 * t) * 0.35 + sin(TAU * 110 * t) * 0.15 + sin(TAU * 165 * t) * 0.06
			bytes.encode_s16(index * 2, int(sample * 10000))
		hum_stream.data = bytes
	return hum_stream

func _ready() -> void:
	position = Vector2(0, -36)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shader_material.shader = preload("res://components/portal_vortex.gdshader")
	surface.texture = WorldParticles.smoke_texture()
	surface.scale = Vector2(2.6, 3.6)
	surface.material = shader_material
	add_child(surface)
	lamp.texture = WorldParticles.glow_texture()
	lamp.texture_scale = 1.6
	lamp.color = Color("47dacb")
	lamp.shadow_enabled = false
	add_child(lamp)
	hum.stream = sound()
	hum.bus = &"SFX"
	hum.volume_db = -23
	hum.max_distance = 380
	add_child(hum)
	if DisplayServer.get_name() != "headless": hum.play()

func trigger() -> void:
	pulse = 1
	var district: District = get_parent().get_parent() as District
	if district != null and district.impact != null and absf(global_position.x - district.player.global_position.x) < 420:
		district.impact.burst(global_position, Color("47dacb"), 35)
		district.impact.kick(2.5)

func _process(delta: float) -> void:
	clock += delta
	shader_material.set_shader_parameter("world_time", clock)
	pulse = move_toward(pulse, 0, delta * 2.2)
	var prefs: GamePreferences = GamePreferences.current()
	surface.visible = active
	shader_material.set_shader_parameter("pulse", pulse)
	shader_material.set_shader_parameter("reduced", prefs.reduced_flashes)
	lamp.enabled = active
	lamp.energy = 0.55 if prefs.reduced_flashes else 0.65 + sin(clock * 2.4) * 0.08 + sin(clock * 11.3) * 0.025 + pulse * 0.35
	if not active and hum.playing: hum.stop()
	if active and not hum.playing and DisplayServer.get_name() != "headless": hum.play()
	queue_redraw()

func _draw() -> void:
	if not active: return
	for index: int in WorldParticles.budget(24):
		var t: float = fposmod(clock * 0.3 + index * 0.618, 1)
		var angle: float = index * 2.4 - t * 4.5
		var at: Vector2 = Vector2(cos(angle) * 30, sin(angle) * 39) * (1 - t)
		draw_rect(Rect2(at.round(), Vector2.ONE), Color(0.4, 0.95, 0.87, sin(t * PI) * 0.8))
