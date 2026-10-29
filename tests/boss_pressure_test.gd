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
	root.get_texture().get_image().save_png("res://.godot/combat-art/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/combat-art"))
	var preferences: GamePreferences = GamePreferences.current()
	var original: Dictionary = preferences.values.duplicate()
	for index: int in 5:
		var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.zone_index = index
		root.add_child(arena)
		arena.set_process(false)
		arena.boss.set_physics_process(false)
		arena.player.set_physics_process(false)
		arena.dynamics.set_physics_process(false)
		arena.modules.set_physics_process(false)
		var fx: BossCombatEffects = arena.combat_effects
		fx.set_physics_process(false)
		fx.set_process(false)
		await physics_frame
		fx.request_combo()
		verify(fx.hazards.size() == (1 if index == 0 else 2), "Primera fase superpone ataques con presupuesto acotado: %d" % index)
		verify(fx.hazards[0].warning >= 1.0 and not fx.hazards[0].hit, "Ataque adicional comienza con aviso: %d" % index)
		var locked: Vector2 = fx.hazards[0].origin
		arena.player.position += Vector2(18, 0)
		fx.tick(0.3)
		verify(fx.hazards[0].origin == locked and arena.player.health == 100, "Aviso fijo no persigue ni hiere al jugador: %d" % index)
		var hazard: Dictionary = fx.hazards[0]
		verify(fx.contains(hazard, hazard.origin), "Geometría incluye su origen: %d" % index)
		var normal: Vector2 = (hazard.end - hazard.origin).normalized().orthogonal() if hazard.kind == "lance" else Vector2.RIGHT
		var middle: Vector2 = (hazard.origin + hazard.end) / 2
		verify(fx.contains(hazard, middle + normal * (hazard.radius - 0.1)), "El borde visible interior daña: %d" % index)
		verify(not fx.contains(hazard, middle + normal * (hazard.radius + 0.1)), "Fuera del borde visible no daña: %d" % index)
		arena.player.position = hazard.origin
		arena.player.invulnerable = 0
		fx.tick(1.0)
		verify(hazard.hit and arena.player.health < 100, "Daño solo después de completar el aviso: %d" % index)
		var health: int = arena.player.health
		arena.player.invulnerable = 0
		fx.hazards.clear()
		fx.hazards.append(hazard)
		fx.tick(0.01)
		verify(arena.player.health == health, "Cada impacto adicional golpea una sola vez: %d" % index)
		fx.hazards.clear()
		arena.boss.phase = 2
		arena.player.position = Vector2(320, 370)
		fx.request_combo()
		verify(fx.hazards.size() == (1 if index == 0 else (2 if index == 1 else 3)), "Segunda fase aumenta las capas de presión: %d" % index)
		arena.boss.facing = Vector2.DOWN
		arena.boss.charge_direction = Vector2.DOWN
		arena.boss.change_state(Recaudador.State.CHARGE_WINDUP, 0.8)
		if capture:
			for frame: int in 20: fx._process(0.05)
		fx.impact(arena.boss.position + Vector2(0, 90), 95, 4, 24)
		fx._process(0.12)
		await picture("presion_jefe_%d" % index)
		verify(fx.particles.size() > 0 and fx.shake > 0 and arena.camera.offset.length() > 0, "Impacto produce fragmentos y temblor: %d" % index)
		if index == 1: (arena.boss as SantaCaldera).prepare_heat()
		elif index == 2: (arena.boss as CoroSumergido).waves.append({"radius": 190.0, "hit": false, "origin": arena.boss.position, "gap": PI * 0.6})
		arena.boss.change_state(Recaudador.State.CLAW if index in [0, 1, 3] else Recaudador.State.APPROACH, 0.16)
		arena.boss.combat_visual.pose_boss(arena.boss)
		fx.queue_redraw()
		await picture("golpe_jefe_%d" % index)
		# Run the actual decision machines against a moving target, with secondary
		# pressure advancing concurrently instead of replacing the primary attack.
		fx.hazards.clear()
		fx.cooldown = 1.0
		arena.player.debug_invincible = true
		arena.player.health = 100
		arena.boss.change_state(Recaudador.State.APPROACH, 0.2)
		var concurrent: bool = false
		for step: int in 480:
			var point: Vector2 = Vector2(320, 280) + Vector2.from_angle(step * 0.02) * 95
			arena.player.position = fx.safe_point(point)
			arena.boss._physics_process(1.0 / 60)
			fx.tick(1.0 / 60)
			fx._process(1.0 / 60)
			var primary: bool = arena.boss.state in [Recaudador.State.CLAW_WINDUP, Recaudador.State.CLAW, Recaudador.State.VOLLEY, Recaudador.State.CHARGE_WINDUP, Recaudador.State.CHARGE]
			if index == 2: primary = not (arena.boss as CoroSumergido).waves.is_empty()
			elif index == 4: primary = not (arena.boss as MadreCero).marks.is_empty()
			if primary and not fx.hazards.is_empty(): concurrent = true
		verify(concurrent, "Patrones principales y secundarios coexisten contra un blanco móvil: %d" % index)
		if index == 2: (arena.boss as CoroSumergido).exposure_left = 3
		elif index == 4: (arena.boss as MadreCero).exposure = 3
		else: arena.boss.state = Recaudador.State.STUNNED if index == 0 else Recaudador.State.RECOVER
		fx.tick(0.1)
		verify(fx.hazards.is_empty(), "Núcleo expuesto cancela las capas ofensivas: %d" % index)
		fx.request_combo()
		verify(fx.hazards.is_empty(), "Ventana de castigo no genera nuevas trampas: %d" % index)
		preferences.values.particles = false
		preferences.values.reduced_flashes = true
		fx.impact(Vector2(320, 200), 80, 5, 50)
		fx._process(0.01)
		verify(fx.particles.is_empty() and fx.shake == 0 and arena.camera.offset == Vector2.ZERO, "Accesibilidad desactiva partículas y temblor: %d" % index)
		preferences.values = original.duplicate()
		for attempt: int in 30: fx.impact(Vector2(320, 200), 80, 0, 50)
		verify(fx.particles.size() <= BossCombatEffects.PARTICLE_LIMIT and fx.impacts.size() <= 32, "Efectos mantienen presupuesto: %d" % index)
		arena.finish(false)
		verify(fx.hazards.is_empty() and not fx.enabled and arena.camera.offset == Vector2.ZERO, "Cerrar limpia ataques y restaura cámara: %d" % index)
		arena.free()
		await process_frame
	await check_walks()
	print("Marcha y presión de jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func check_walks() -> void:
	var layout: Dictionary = CombatSpriteLibrary.data()
	for direction: String in ["south", "east", "north", "west"]:
		var board: Node2D = Node2D.new()
		root.add_child(board)
		var row: int = 0
		for id: String in ["portador", "portador_cenital", "prefecto", "madre"]:
			var frames: SpriteFrames = CombatSpriteLibrary.frames(id)
			var info: Dictionary = layout.actors[id]
			var rest: Image = frames.get_frame_texture("idle_" + direction, 0).get_image()
			var height: float = 70 if id.begins_with("portador") else (116 if id == "prefecto" else 144)
			var crop: Rect2i = Rect2i(int(info.anchor[0] - height * 0.1), rest.get_used_rect().position.y + 2, int(height * 0.2), int(height * 0.15))
			var head: int = hash(rest.get_region(crop).get_data())
			var unique: Dictionary = {}
			for frame: int in 8:
				var texture: Texture2D = frames.get_frame_texture("walk_" + direction, frame)
				var image: Image = texture.get_image()
				unique[hash(image.get_data())] = true
				var translated: Rect2i = crop
				translated.position.y += roundi(cos(frame * PI / 2) * height * 0.012)
				verify(hash(image.get_region(translated).get_data()) == head, "Cabeza estable, sin redibujarse entre pasos: %s/%s/%d" % [id, direction, frame])
				var sprite: Sprite2D = Sprite2D.new()
				sprite.texture = texture
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.scale = Vector2.ONE * 0.5
				sprite.position = Vector2(40 + frame * 80, 75 + row * 90) + CombatSpriteLibrary.offset_for(id) * 0.5
				board.add_child(sprite)
			verify(unique.size() == 8, "Ocho fases propias de marcha sin reposo intercalado: %s/%s" % [id, direction])
			row += 1
		await picture("zancadas_" + direction)
		board.free()
		await process_frame
