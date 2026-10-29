class_name EncounterDynamics
extends Node2D
## Mecanismos de arena y refuerzos comparten las reglas de pausa y final del combate.
var arena: RecaudadorArena
var elapsed: float = 0
var summon_cooldown: float = 14
var summons: Array[Dictionary] = []
var sentinels: Array[EncounterSentinel] = []
var device_positions: Array[Vector2] = [Vector2(245, 385), Vector2(395, 385)]
var device_cooldowns: Array[float] = [0.0, 0.0]
var device_effects: Array[Dictionary] = []
var device_hint: Label
var machinery: Array[Sprite2D] = []
var obstacle_rects: Array[Rect2] = []
var barrier: StaticBody2D
var barrier_left: float = 0
var summons_total: int = 0
var channels: Array[Rect2] = [Rect2(225, 155, 36, 180), Rect2(379, 155, 36, 180)]

func _ready() -> void:
	device_hint = Label.new()
	device_hint.position = Vector2(170, 415)
	device_hint.add_theme_font_size_override("font_size", 13)
	device_hint.add_theme_font_override("font", ThemeDB.fallback_font)
	device_hint.add_theme_constant_override("outline_size", 4)
	device_hint.add_theme_color_override("font_outline_color", Color("08111c"))
	device_hint.z_index = 20
	add_child(device_hint)
	if arena.zone_index == 4: device_positions.clear()
	for index: int in range(device_positions.size()):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = DepotArt.prop(2 if arena.zone_index == 2 else 0)
		sprite.position = device_positions[index]
		sprite.scale = Vector2(27, 28) / sprite.texture.get_size()
		add_child(sprite)
		machinery.append(sprite)

func configure_paths() -> void:
	obstacle_rects.clear()
	for child: Node in arena.actors.get_children():
		if not child is StaticBody2D: continue
		var shape: CollisionShape2D = child.get_child(0) as CollisionShape2D
		if shape != null and shape.shape is RectangleShape2D:
			obstacle_rects.append(Rect2(child.position - shape.shape.size / 2, shape.shape.size))
	arena.boss.tactics.configure_navigation(ArenaLayout.boundary(arena.zone_index), obstacle_rects)

func _physics_process(delta: float) -> void:
	if arena.ending or arena.boss.health <= 0 or arena.player.health <= 0: return
	elapsed += delta
	for index: int in range(sentinels.size() - 1, -1, -1):
		if not is_instance_valid(sentinels[index]) or sentinels[index].health <= 0 or sentinels[index].is_queued_for_deletion(): sentinels.remove_at(index)
	arena.player.terrain_speed_factor = 1.0
	if arena.boss is CoroSumergido and (arena.boss as CoroSumergido).silence_left <= 0:
		for channel: Rect2 in channels:
			if channel.has_point(arena.player.position): arena.player.terrain_speed_factor = 0.78
	for index: int in range(device_cooldowns.size()): device_cooldowns[index] = maxf(0, device_cooldowns[index] - delta)
	device_hint.text = ""
	for index: int in range(device_positions.size()):
		if arena.player.position.distance_to(device_positions[index]) < 48:
			device_hint.text = ("[E] " + device_name()) if device_cooldowns[index] <= 0 else ("Recargando: %ds" % ceili(device_cooldowns[index]))
			if Input.is_action_just_pressed("interact"): activate_device(index)
			break
	if barrier_left > 0:
		barrier_left = maxf(0, barrier_left - delta)
		if barrier_left == 0 and is_instance_valid(barrier): barrier.queue_free()
	for index: int in range(device_effects.size() - 1, -1, -1):
		device_effects[index].time -= delta
		if device_effects[index].time <= 0:
			resolve_device(device_effects[index])
			device_effects.remove_at(index)
	# No refuerzos durante ventanas de castigo; avisos de llegada duran 1.4 segundos.
	summon_cooldown -= delta
	var allowed: bool = arena.zone_index == 4 or arena.boss.phase == 2
	if allowed and not arena.boss.core_exposed and summon_cooldown <= 0:
		request_reinforcements()
	for index: int in range(summons.size() - 1, -1, -1):
		summons[index].time -= delta
		if summons[index].time <= 0:
			if not arena.boss.core_exposed: spawn_sentinel(summons[index].position)
			summons.remove_at(index)
	queue_redraw()

func device_name() -> String:
	return ["Soltar carga central", "Purga de refrigerante", "Silenciar el sonar", "Levantar parapeto", ""][arena.zone_index]

func activate_device(index: int) -> bool:
	if arena.ending or index < 0 or index >= device_positions.size() or device_cooldowns[index] > 0 or arena.player.position.distance_to(device_positions[index]) >= 48: return false
	device_cooldowns[index] = 20
	arena.sound.play_cue("upgrade", -8)
	match arena.zone_index:
		0:
			device_effects.append({"position": Vector2(320, 230), "time": 1.1, "kind": "cargo"})
		1:
			var boiler: SantaCaldera = arena.boss as SantaCaldera
			# Útil contra las rejillas, no permite mantener el núcleo abierto permanentemente.
			if boiler.state in [Recaudador.State.CLAW_WINDUP, Recaudador.State.CLAW]:
				boiler.clear_hazards()
				boiler.change_state(Recaudador.State.RECOVER, 3.0)
			device_effects.append({"position": Vector2(320, 240), "time": 0.6, "kind": "coolant"})
		2:
			var choir: CoroSumergido = arena.boss as CoroSumergido
			choir.waves.clear()
			choir.silence_left = 5
			device_effects.append({"position": device_positions[index], "time": 0.8, "kind": "sonar"})
		3:
			if is_instance_valid(barrier): barrier.queue_free()
			barrier = arena.wall(Vector2(320, 300), Vector2(80, 12))
			barrier.name = "ParapetoTemporal"
			barrier_left = 5
	return true

func resolve_device(effect: Dictionary) -> void:
	if effect.kind != "cargo": return
	arena.boss.effects.emit_pixels(effect.position, 18, Color("ffce75"))
	if arena.boss.position.distance_to(effect.position) < 70: arena.boss.stun()
	if arena.player.position.distance_to(effect.position) < 65: arena.player.take_damage(20)
	for index: int in range(sentinels.size()):
		if not is_instance_valid(sentinels[index]): continue
		if sentinels[index].position.distance_to(effect.position) < 70: sentinels[index].receive_hit(effect.position, 150)

func request_reinforcements() -> void:
	summon_cooldown = [24.0, 26.0, 25.0, 28.0, 22.0][arena.zone_index]
	var cap: int = 3 if arena.zone_index == 4 else 2
	var count: int = mini(2, cap - sentinels.size() - summons.size())
	if count <= 0: return
	var points: Array[Vector2] = [Vector2(210, 85), Vector2(430, 85), Vector2(110, 300), Vector2(530, 300)]
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(arena.player.position) > b.distance_squared_to(arena.player.position))
	for index: int in range(count):
		if points[index].distance_to(arena.player.position) > 110:
			summons.append({"position": points[index], "time": 1.4})
	arena.sound.play_cue("alarm", -10)

func spawn_sentinel(at: Vector2) -> EncounterSentinel:
	var unit: EncounterSentinel = EncounterSentinel.new()
	unit.encounter = arena
	unit.role = "saboteur" if arena.zone_index == 4 else ("hunter" if arena.zone_index in [2, 3] else "gunner")
	unit.position = at
	unit.side = -1 if summons_total % 2 == 0 else 1
	unit.tactics.configure_navigation(ArenaLayout.boundary(arena.zone_index), obstacle_rects, 15)
	arena.actors.add_child(unit)
	sentinels.append(unit)
	summons_total += 1
	return unit

func clear_encounter() -> void:
	arena.player.terrain_speed_factor = 1.0
	summons.clear()
	device_effects.clear()
	device_hint.text = ""
	for index: int in range(sentinels.size()):
		if is_instance_valid(sentinels[index]): sentinels[index].queue_free()
	sentinels.clear()
	if is_instance_valid(barrier): barrier.queue_free()
	barrier_left = 0
	queue_redraw()

func _draw() -> void:
	if arena.ending: return
	if arena.zone_index == 2:
		var active: bool = (arena.boss as CoroSumergido).silence_left <= 0
		for channel: Rect2 in channels:
			draw_rect(channel, Color("071e2a", 0.85))
			draw_rect(channel, Color("47dacb", 0.2 if active else 0.07), false, 1)
			for ripple: int in range(8):
				var y: float = fposmod(elapsed * (25 if active else 5) + ripple * 23, 172)
				var at: Vector2 = channel.position + Vector2(5, y)
				draw_line(at, at + Vector2(24, sin(elapsed + ripple) * 2), Color("47dacb", 0.23 if active else 0.1), 1)
				draw_line(at + Vector2(8, 4), at + Vector2(12, 7), Color("8299a8", 0.2), 1)
	for index: int in range(device_positions.size()):
		var color: Color = Color("47dacb") if device_cooldowns[index] <= 0 else Color("8299a8")
		draw_arc(device_positions[index], 21, -PI / 2, -PI / 2 + TAU * (1 - device_cooldowns[index] / 20), 24, color, 2)
		draw_circle(device_positions[index] + Vector2(0, -9), 2, color)
	for summon: Dictionary in summons:
		draw_circle(summon.position, 22, Color("dd6482", 0.1))
		draw_arc(summon.position, 22, elapsed * 3, elapsed * 3 + 5, 24, Color("dd6482"), 2)
		draw_line(summon.position - Vector2(8, 0), summon.position + Vector2(8, 0), Color("ffce75"), 2)
	for effect: Dictionary in device_effects:
		if effect.kind == "cargo":
			draw_circle(effect.position, 70, Color("ffce75", 0.12))
			draw_arc(effect.position, 70, 0, TAU, 48, Color("ffce75"), 2)
			var fall: float = 1 - effect.time / 1.1
			draw_texture_rect(DepotArt.prop(3), Rect2(effect.position - Vector2(28, 150 - fall * 125), Vector2(56, 42)), false, Color(1, 1, 1, 0.65))
		else:
			draw_arc(effect.position, 25 + (1 - effect.time) * 160, 0, TAU, 48, Color("47dacb", 0.5), 3)
	if barrier_left > 0:
		draw_texture_rect(DepotArt.part(3), Rect2(280, 285, 80, 28), false)
		draw_line(Vector2(282, 280), Vector2(358, 280), Color("47dacb", 0.6), 2)
