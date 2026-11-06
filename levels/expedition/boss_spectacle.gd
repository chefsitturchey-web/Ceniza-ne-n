class_name BossSpectacle
extends Node2D
## Puesta en escena de los jefes finales (El Prefecto y Madre Cero): presentación con
## tarjeta de nombre, destello e hit-stop al golpear, contorno de aviso en cada preparación,
## transformación visible en fase 2 y última guardia/protocolo, y una muerte dramática.
## Todo es cosmético: no cambia daño, tiempos de IA ni colisiones. Respeta
## GamePreferences.reduced_flashes (sin destellos de pantalla ni parpadeos) y particles.
const SHADER: Shader = preload("res://components/boss_sprite.gdshader")
const SILHOUETTE: Shader = preload("res://components/boss_silhouette.gdshader")
const THEME: Theme = preload("res://ui/theme.tres")
const TITLES: Dictionary = {
	"prefecto": ["EL PREFECTO", "Duelista de la Ciudadela"],
	"madre": ["MADRE CERO", "La red que todo lo sostiene"],
}
## Color de aviso (igual que las señales del suelo), color base y color de furia.
const PALETTE: Dictionary = {
	"prefecto": [Color("9dc9f0"), Color("ffce75"), Color("ff3b4e")],
	"madre": [Color("e888b0"), Color("47dacb"), Color("ed4fa0")],
}
var arena: RecaudadorArena
var boss: Recaudador
var id: String = "prefecto"
var sprite_material: ShaderMaterial = ShaderMaterial.new()
var front: Node2D = Node2D.new()
## Contorno: el cuadro actual dibujado como silueta un texel alrededor, detrás del sprite.
var halo: Node2D = Node2D.new()
## Luz propia del jefe: lo despega del suelo oscuro y se enciende con cada aviso.
var glow: PointLight2D = PointLight2D.new()
var overlay: Control = Control.new()
var screen_flash: ColorRect = ColorRect.new()
var bars: Array[ColorRect] = []
var card: Control = Control.new()
var card_title: Label
var card_subtitle: Label
var flash: float = 0
var flash_color: Color = Color.WHITE
var stage: int = 0 # 0 normal, 1 segunda fase, 2 última guardia o último protocolo
var clock: float = 0
var ember_clock: float = 0
var embers: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var base_zoom: Vector2 = Vector2.ONE
var rest: Vector2 = Vector2(320, 240)
var dying: bool = false
var death_clock: float = 0
var slow_active: bool = false
var previous_scale: float = 1
var intro_done: bool = false
var intro_started: bool = false

static func wants(target: Recaudador) -> bool:
	return target is ElPrefecto or target is MadreCero

func calm() -> bool: return GamePreferences.current().reduced_flashes

func _ready() -> void:
	boss = arena.boss
	id = "prefecto" if boss is ElPrefecto else "madre"
	rng.seed = 77 + arena.zone_index
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.z_index = 7
	front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.draw.connect(draw_front)
	add_child(front)
	sprite_material.shader = SHADER
	if boss.combat_visual != null:
		boss.combat_visual.sprite.material = sprite_material
		var silhouette: ShaderMaterial = ShaderMaterial.new()
		silhouette.shader = SILHOUETTE
		halo.material = silhouette
		halo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		halo.draw.connect(draw_halo)
		boss.combat_visual.add_child(halo)
		boss.combat_visual.move_child(halo, 0)
	boss.damaged.connect(_on_damaged)
	boss.hit_feedback.connect(func(blocked: bool) -> void:
		if blocked: pulse(0.55, PALETTE[id][0]))
	boss.phase_changed.connect(_on_phase)
	boss.died.connect(_on_died)
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	var light: GradientTexture2D = GradientTexture2D.new()
	light.gradient = gradient
	light.width = 128
	light.height = 128
	light.fill = GradientTexture2D.FILL_RADIAL
	light.fill_from = Vector2(0.5, 0.5)
	light.fill_to = Vector2(1, 0.5)
	glow.texture = light
	glow.texture_scale = 1.4
	glow.energy = 0.6
	add_child(glow)
	base_zoom = arena.camera.zoom
	rest = arena.camera.position
	build_overlay()

func build_overlay() -> void:
	overlay.size = Vector2(640, 360)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(overlay)
	# Debajo del HUD de combate y de los menús: solo cubre el campo de juego.
	arena.move_child(overlay, arena.combat_hud.get_index())
	for top: bool in [true, false]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color("02060c")
		bar.size = Vector2(640, 0)
		bar.position = Vector2(0, 0 if top else 360)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
		bars.append(bar)
	screen_flash.size = Vector2(640, 360)
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(screen_flash)
	card.size = Vector2(640, 64)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.modulate.a = 0
	overlay.add_child(card)
	var band: ColorRect = ColorRect.new()
	band.color = Color("050c17", 0.86)
	band.size = Vector2(640, 64)
	card.add_child(band)
	for y: int in [0, 63]:
		var line: ColorRect = ColorRect.new()
		line.color = PALETTE[id][1]
		line.size = Vector2(640, 1)
		line.position.y = y
		card.add_child(line)
	card_title = Label.new()
	card_title.theme = THEME
	card_title.theme_type_variation = &"Title"
	card_title.add_theme_font_size_override("font_size", 32)
	card_title.add_theme_color_override("font_color", PALETTE[id][1])
	card_title.add_theme_constant_override("outline_size", 4)
	card_title.add_theme_color_override("font_outline_color", Color("02060c"))
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.size = Vector2(640, 38)
	card_title.position.y = 4
	card.add_child(card_title)
	card_subtitle = Label.new()
	card_subtitle.theme = THEME
	card_subtitle.add_theme_color_override("font_color", Color("d8dee8"))
	card_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_subtitle.size = Vector2(640, 18)
	card_subtitle.position.y = 42
	card.add_child(card_subtitle)

## Tarjeta de nombre con barras de cine y acercamiento de cámara al jefe.
func intro() -> void:
	if intro_started: return
	intro_started = true
	card_title.text = TITLES[id][0]
	card_subtitle.text = TITLES[id][1]
	# Bajo el jefe encuadrado: el acercamiento lo deja en el centro de la pantalla.
	card.position.y = 236
	arena.camera.zoom = base_zoom * 1.4
	arena.camera.position = boss.position + Vector2(0, -20)
	arena.sound.play_cue("boss_phase", -3)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for index: int in bars.size():
		tween.tween_property(bars[index], "size:y", 28.0, 0.25)
		if index == 1: tween.tween_property(bars[index], "position:y", 332.0, 0.25)
	tween.tween_property(card, "modulate:a", 1.0, 0.2).set_delay(0.15)
	tween.tween_property(card_title, "position:x", 0.0, 0.35).from(-40.0).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(arena.camera, "zoom", base_zoom, 1.1).set_delay(1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(arena.camera, "position", rest, 1.1).set_delay(1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "modulate:a", 0.0, 0.35).set_delay(1.9)
	tween.tween_property(bars[0], "size:y", 0.0, 0.3).set_delay(2.0)
	tween.tween_property(bars[1], "size:y", 0.0, 0.3).set_delay(2.0)
	tween.tween_property(bars[1], "position:y", 360.0, 0.3).set_delay(2.0)
	tween.chain().tween_callback(func() -> void: intro_done = true)
	add_ring(boss.position, PALETTE[id][1], 70, 0.7)

func pulse(amount: float, color: Color) -> void:
	flash = maxf(flash, amount * (0.4 if calm() else 1.0))
	flash_color = color

func add_ring(at: Vector2, color: Color, radius: float, life: float = 0.5, delay: float = 0.0) -> void:
	if rings.size() >= 16: rings.pop_front()
	rings.append({"at": at, "color": color, "radius": radius, "life": life, "age": -delay})

func _on_damaged(amount: int, remaining: int) -> void:
	if amount <= 0: return
	pulse(1.0, Color.WHITE)
	add_ring(boss.position + Vector2(0, -24), PALETTE[id][1], 26, 0.3)
	# Pausa breve en cada golpe que entra; la de muerte ya la hace ImpactFeedback.
	if remaining > 0 and is_instance_valid(arena.impact): arena.impact.hit_stop(0.04)

func _on_phase(_number: int) -> void:
	var last: bool = (boss is ElPrefecto and (boss as ElPrefecto).last_guard) or (boss is MadreCero and (boss as MadreCero).last_protocol)
	stage = 2 if last else 1
	pulse(1.0, PALETTE[id][2])
	arena.sound.play_cue("overload", -2)
	arena.combat_effects.shake = maxf(arena.combat_effects.shake, 7.0 if last else 5.0)
	for index: int in 3: add_ring(boss.position, PALETTE[id][2], 60 + index * 30, 0.6, index * 0.12)
	if not calm():
		screen_flash.color = Color(PALETTE[id][2], 0.35)
		create_tween().tween_property(screen_flash, "color:a", 0.0, 0.45)
	var punch: Tween = create_tween()
	punch.tween_property(arena.camera, "zoom", base_zoom * 1.1, 0.08)
	punch.tween_property(arena.camera, "zoom", base_zoom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if last:
		arena.phase_notice.text = "ÚLTIMA GUARDIA" if boss is ElPrefecto else "ÚLTIMO PROTOCOLO"
	else:
		arena.phase_notice.text = "SEGUNDA FASE: " + ("EL PREFECTO DESENVAINA LA FURIA" if boss is ElPrefecto else "MADRE CERO DESPIERTA LA RED")
	arena.phase_notice.add_theme_color_override("font_color", PALETTE[id][2])

func _on_died() -> void:
	dying = true
	death_clock = 0
	pulse(1.0, Color.WHITE)
	arena.sound.play_cue("boss_phase", -1)
	# Cámara lenta breve en tiempo real; nunca pisa una velocidad de práctica distinta de 1.
	# El golpe final ya congeló el tiempo (hit-stop): la cámara lenta empieza al soltarlo.
	var stopped: bool = is_instance_valid(arena.impact) and arena.impact.stop_active
	var current: float = arena.impact.previous_scale if stopped else Engine.time_scale
	if not slow_active and is_equal_approx(current, 1.0):
		slow_active = true
		previous_scale = current
		if stopped: arena.impact.previous_scale = 0.3
		else: Engine.time_scale = 0.3
		get_tree().create_timer(1.2, true, false, true).timeout.connect(restore_time)
	var focus: Tween = create_tween().set_ignore_time_scale(true)
	focus.set_parallel(true)
	focus.tween_property(arena.camera, "zoom", base_zoom * 1.3, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	focus.tween_property(arena.camera, "position", boss.position + Vector2(0, -16), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	focus.chain().tween_interval(1.6)
	focus.chain().set_parallel(true)
	focus.tween_property(arena.camera, "zoom", base_zoom, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	focus.tween_property(arena.camera, "position", rest, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if not calm():
		screen_flash.color = Color(1, 1, 1, 0.75)
		create_tween().set_ignore_time_scale(true).tween_property(screen_flash, "color:a", 0.0, 0.6)
	for index: int in 4: add_ring(boss.position + Vector2(0, -20), PALETTE[id][1] if index % 2 == 0 else PALETTE[id][2], 50 + index * 35, 0.8, index * 0.1)
	# Tarjeta de victoria encima del cartel "DERROTADO" del combate.
	card_title.text = "VICTORIA"
	card_subtitle.text = TITLES[id][0] + " ha caído. La ruta queda libre."
	card_title.add_theme_color_override("font_color", Color("ffce75"))
	card.position.y = 74
	var reveal: Tween = create_tween().set_ignore_time_scale(true)
	reveal.tween_interval(0.9)
	reveal.tween_property(card, "modulate:a", 1.0, 0.25)
	reveal.parallel().tween_property(card_title, "position:x", 0.0, 0.4).from(-60.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_interval(2.4)
	reveal.tween_property(card, "modulate:a", 0.0, 0.5)

func restore_time() -> void:
	if not slow_active: return
	if is_equal_approx(Engine.time_scale, 0.3): Engine.time_scale = previous_scale
	slow_active = false

func _exit_tree() -> void:
	restore_time()
	if is_instance_valid(overlay): overlay.queue_free()

## Intensidad del contorno de aviso: 1 mientras el jefe prepara un golpe.
func telegraph() -> float:
	if boss.health <= 0: return 0.0
	if boss is MadreCero: return 1.0 if (boss as MadreCero).casting_time() < 0.65 else 0.0
	return 1.0 if boss.state in [Recaudador.State.CLAW_WINDUP, Recaudador.State.CHARGE_WINDUP, Recaudador.State.VOLLEY_WINDUP] else 0.0

func _process(delta: float) -> void:
	if arena.completed: card.hide() # La pantalla de resultado manda.
	if get_tree().paused: return
	clock += delta
	flash = move_toward(flash, 0, delta * 7)
	var outline: Color = Color(0, 0, 0, 0)
	var warning: float = telegraph()
	if warning > 0:
		var blink: float = 1.0 if calm() else 0.55 + 0.45 * absf(sin(clock * 14))
		outline = Color(PALETTE[id][0], blink)
	elif boss.core_exposed and boss.health > 0:
		outline = Color(PALETTE[id][1], 0.6 + 0.4 * absf(sin(clock * 5)))
	elif stage > 0 and boss.health > 0:
		outline = Color(PALETTE[id][2], 0.7 if stage == 1 else 1.0)
	elif boss.health > 0:
		# Contorno tenue permanente: el jefe se despega del suelo oscuro de la arena.
		outline = Color(PALETTE[id][1], 0.35)
	var tint: Color = Color(1.12, 1.1, 1.08)
	if stage == 1: tint = Color(1.08, 0.97, 0.95) if id == "prefecto" else Color(1.0, 0.95, 1.05)
	elif stage == 2: tint = Color(1.18, 0.88, 0.85) if id == "prefecto" else Color(1.05, 0.9, 1.04)
	sprite_material.set_shader_parameter("flash", flash)
	sprite_material.set_shader_parameter("flash_color", flash_color)
	# La luz ambiental de la arena oscurece todo: el contorno se compensa por encima de 1.
	halo.modulate = Color(outline.r * 1.45, outline.g * 1.45, outline.b * 1.45, outline.a)
	glow.position = boss.position + Vector2(0, -24)
	var target_energy: float = 0.55
	glow.color = PALETTE[id][1]
	if warning > 0:
		glow.color = PALETTE[id][0]
		target_energy = 1.0 if calm() else 0.8 + 0.6 * absf(sin(clock * 14))
	elif stage > 0 and boss.health > 0:
		glow.color = PALETTE[id][2]
		target_energy = 0.75 if stage == 1 else 0.95
	if dying: target_energy = maxf(0.0, 2.2 - death_clock * 0.8)
	glow.energy = move_toward(glow.energy, target_energy, delta * 6)
	halo.visible = outline.a > 0
	halo.queue_redraw()
	sprite_material.set_shader_parameter("tint", Vector4(tint.r, tint.g, tint.b, 1.0))
	if dying:
		death_clock += delta
		# Estallidos en cadena alrededor del cuerpo durante la cámara lenta.
		if death_clock < 1.4 and fmod(death_clock, 0.12) < delta:
			var at: Vector2 = boss.position + Vector2(rng.randf_range(-26, 26), rng.randf_range(-48, 0))
			boss.effects.emit_pixels(at, 6, PALETTE[id][1] if rng.randf() < 0.5 else PALETTE[id][2])
			add_ring(at, PALETTE[id][1], rng.randf_range(14, 26), 0.35)
			if not calm(): pulse(0.7, Color.WHITE)
			arena.combat_effects.shake = maxf(arena.combat_effects.shake, 2.0)
	ember_clock -= delta
	var emitting: bool = (stage > 0 and boss.health > 0) or (dying and death_clock < 3.0)
	if emitting and ember_clock <= 0 and GamePreferences.current().particles:
		ember_clock = 0.03 if dying else (0.05 if stage == 2 else 0.09)
		var angle: float = rng.randf() * TAU
		var gold: bool = dying
		embers.append({"at": boss.position + Vector2(cos(angle) * 26, sin(angle) * 11), "speed": Vector2(rng.randf_range(-6, 6), rng.randf_range(-70, -38) * (1.6 if gold else 1.0)),
			"age": 0.0, "life": rng.randf_range(0.6, 1.1), "color": Color("ffe7a3") if gold else (PALETTE[id][2] if rng.randf() < 0.7 else Color("fff1d6"))})
		if embers.size() > 90: embers.pop_front()
	for ember: Dictionary in embers:
		ember.age += delta
		ember.at += ember.speed * delta
	embers = embers.filter(func(ember: Dictionary) -> bool: return ember.age < ember.life)
	for ring: Dictionary in rings: ring.age += delta
	rings = rings.filter(func(ring: Dictionary) -> bool: return ring.age < ring.life)
	queue_redraw()
	front.queue_redraw()

func draw_halo() -> void:
	var visual: CombatFlipbook = boss.combat_visual
	if visual == null or visual.current == &"": return
	halo.position = visual.sprite.position
	halo.scale = visual.sprite.scale
	var frame: Texture2D = visual.texture()
	var corner: Vector2 = -frame.get_size() * 0.5
	for offset: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		halo.draw_texture(frame, corner + offset)

## Aura del suelo, bajo los actores: anillo de fase y columna dorada de victoria.
func _draw() -> void:
	var at: Vector2 = boss.position
	if stage > 0 and boss.health > 0:
		var color: Color = PALETTE[id][2]
		var radius: float = 34 + (0 if calm() else sin(clock * 6) * 3)
		draw_set_transform(at + Vector2(0, 2), 0, Vector2(1, 0.45))
		draw_circle(Vector2.ZERO, radius, Color(color, 0.14 if stage == 1 else 0.22))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(color, 0.85), 2)
		if stage == 2: draw_arc(Vector2.ZERO, radius + 7, clock * 2, clock * 2 + PI, 24, Color(color, 0.6), 2)
		draw_set_transform(Vector2.ZERO)
	if dying and death_clock > 0.4:
		var fade: float = clampf(1.0 - (death_clock - 2.4) / 1.2, 0, 1) * clampf((death_clock - 0.4) / 0.3, 0, 1)
		var width: float = 22 + (0 if calm() else sin(clock * 10) * 2)
		draw_rect(Rect2(at.x - width * 0.5, at.y - 420, width, 420), Color("ffce75", 0.16 * fade))
		draw_rect(Rect2(at.x - width * 0.25, at.y - 420, width * 0.5, 420), Color("fff1d6", 0.22 * fade))

## Encima de los actores: brasas, ondas de choque.
func draw_front() -> void:
	for ember: Dictionary in embers:
		var fade: float = 1.0 - ember.age / ember.life
		front.draw_rect(Rect2((ember.at as Vector2).round(), Vector2(2, 2)), Color(ember.color, fade))
	for ring: Dictionary in rings:
		if ring.age < 0: continue
		var t: float = ring.age / ring.life
		front.draw_arc(ring.at, lerpf(4, ring.radius, sqrt(t)), 0, TAU, 40, Color(ring.color, (1 - t) * 0.85), maxf(1, (1 - t) * 4))
