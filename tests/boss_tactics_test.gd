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

func make_arena(index: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
	arena.zone_index = index
	root.add_child(arena)
	arena.set_process(false)
	arena.player.set_physics_process(false)
	arena.boss.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.dynamics.set_physics_process(false)
	return arena

func picture(index: int) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/tactics/boss_%d.png" % index)

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/tactics"))
	var brain: BossTactics = BossTactics.new()
	verify(brain.choose({"impossible": -1, "legal": 5}) == "legal", "No elige acciones fuera de alcance")
	verify(brain.choose({"legal": 100, "other": 1}) == "other", "El enfriamiento evita repetir la acción dominante")
	verify(brain.choose({"legal": 100, "other": 100}) == "", "Sin acciones válidas espera")
	for index: int in range(5):
		var arena: RecaudadorArena = make_arena(index)
		var boss: Recaudador = arena.boss
		var dynamics: EncounterDynamics = arena.dynamics
		await physics_frame
		verify(boss.tactics.walkable.size() > 100, "Navegación con perímetro y coberturas: %d" % index)
		var path_valid: bool = true
		for cell: Vector2i in boss.tactics.walkable:
			var point: Vector2 = boss.tactics.navigation.get_point_position(cell)
			if not Geometry2D.is_point_in_polygon(point, ArenaLayout.boundary(index)): path_valid = false
			for rect: Rect2 in dynamics.obstacle_rects:
				if rect.grow(31).has_point(point): path_valid = false
		verify(path_valid, "La ruta no invade cobertura ni sale de plataforma: %d" % index)
		if index == 0:
			boss.position = Vector2(180, 95)
			arena.player.position = Vector2(180, 250)
			for step: int in range(300):
				boss.tactics.observe(arena.player, 1.0 / 60)
				boss.velocity = boss.tactics.steer(boss, arena.player.position, 85)
				boss.move_and_slide()
			verify(boss.position.y > 215, "Ruta física rodea el pilar en vez de avanzar contra él")
			boss.position = Vector2(320, 130)
			arena.player.position = Vector2(320, 370)
			boss.tactics = BossTactics.new()
			dynamics.configure_paths()
		boss.tactics.observe(arena.player, 0.2)
		arena.player.position.x += 22
		boss.tactics.observe(arena.player, 0.2)
		verify(boss.tactics.predicted(arena.player).x > arena.player.position.x, "Predicción usa desplazamiento observado: %d" % index)
		verify(boss.tactics.predicted(arena.player).distance_to(arena.player.position) <= 92, "Anticipación acotada: %d" % index)
		arena.player.position = Vector2(320, 370)
		boss.phase = 2
		dynamics.request_reinforcements()
		verify(dynamics.summons.size() == 2 and dynamics.sentinels.is_empty(), "Dos llegadas avisadas sin enemigos instantáneos: %d" % index)
		dynamics._physics_process(1.0)
		verify(dynamics.sentinels.is_empty() and arena.player.health == 100, "Aviso de refuerzos no hace daño: %d" % index)
		dynamics._physics_process(0.41)
		verify(dynamics.sentinels.size() == 2, "Refuerzos entran después del aviso: %d" % index)
		for unit: EncounterSentinel in dynamics.sentinels: unit.set_physics_process(false)
		for attempt: int in range(20): dynamics.request_reinforcements()
		verify(dynamics.sentinels.size() + dynamics.summons.size() <= (3 if index == 4 else 2), "Límite incluye llegadas pendientes: %d" % index)
		dynamics.summons.clear()
		var unit: EncounterSentinel = dynamics.sentinels[0]
		unit.position = Vector2(320, 320)
		unit.role = "gunner"
		unit.cooldown = 0
		unit._physics_process(0.01)
		verify(unit.windup > 0, "Escolta avisa antes de disparar: %d" % index)
		var aim: Vector2 = unit.aim
		arena.player.position = Vector2(370, 370)
		unit._physics_process(0.4)
		verify(unit.aim == aim, "No corrige puntería durante el aviso: %d" % index)
		unit._physics_process(0.6)
		verify(unit.cooldown > 3, "Disparo tiene recuperación: %d" % index)
		unit.position = Vector2(320, 330)
		arena.player.position = Vector2(320, 370)
		var previous: int = unit.health
		arena.strike(arena.player.position, Vector2.UP, 50, 42)
		verify(unit.health == previous - 50, "Hoja alcanza escoltas: %d" % index)
		arena.modules.timers.drone = 0
		arena.modules.update_arena(0.1)
		verify(unit.health < previous - 50, "Dron ayuda contra escoltas: %d" % index)
		arena.player.stamina = 50
		unit.receive_hit(arena.player.position, 999)
		verify(unit.health == 0 and arena.player.stamina == 58, "Escolta devuelve resistencia: %d" % index)
		unit.receive_hit(arena.player.position, 999)
		verify(arena.player.stamina == 58, "No duplica recompensa: %d" % index)
		await process_frame
		dynamics._physics_process(0.01)
		arena.player.health = 100
		arena.player.invulnerable = 0
		if index < 4:
			verify(not dynamics.activate_device(0), "No activa mecanismos a distancia: %d" % index)
			arena.player.position = dynamics.device_positions[0]
			if index == 1: (boss as SantaCaldera).prepare_heat()
			if index == 2: (boss as CoroSumergido).waves.append({"radius": 18.0, "hit": false})
			boss.position = Vector2(320, 230)
			verify(dynamics.activate_device(0) and not dynamics.activate_device(0), "Mecanismo tiene enfriamiento: %d" % index)
			match index:
				0:
					dynamics._physics_process(1.11)
					verify(boss.core_exposed and arena.player.health == 100, "Carga central aturde sin golpear operador")
				1: verify(boss.core_exposed and (boss as SantaCaldera).heat_areas.is_empty(), "Refrigerar cancela calor y abre ventana")
				2: verify((boss as CoroSumergido).waves.is_empty() and (boss as CoroSumergido).silence_left == 5, "Interferencia limpia ondas sin destruir antenas")
				3:
					verify(is_instance_valid(dynamics.barrier) and dynamics.barrier_left == 5, "Parapeto tiene colisión temporal")
					var bullet: RecaudadorBullet = RecaudadorBullet.new()
					bullet.position = Vector2(320, 280)
					bullet.velocity = Vector2(0, 200)
					arena.world.add_child(bullet)
					await physics_frame
					bullet.set_physics_process(false)
					bullet._physics_process(0.15)
					verify(bullet.spent, "Parapeto bloquea proyectiles de verdad")
					dynamics._physics_process(5.1)
					verify(dynamics.barrier_left == 0, "Parapeto desaparece tras cinco segundos")
		if index == 0:
			boss.tactics.cooldowns.clear()
			boss.choose_attack(60)
			verify(boss.state == Recaudador.State.CLAW_WINDUP, "Recaudador responde con garra a corta distancia")
			boss.tactics.cooldowns.clear()
			boss.tactics.history.clear()
			boss.choose_attack(240)
			verify(boss.state == Recaudador.State.CHARGE_WINDUP, "Recaudador cambia respuesta a larga distancia")
			var locked: Vector2 = boss.charge_direction
			arena.player.position.x += 60
			boss._physics_process(0.2)
			verify(boss.charge_direction == locked, "Embestida no persigue durante aviso")
		if index == 2:
			var choir: CoroSumergido = boss as CoroSumergido
			choir.silence_left = 0
			arena.player.position = dynamics.channels[0].get_center()
			dynamics._physics_process(0.01)
			verify(arena.player.terrain_speed_factor == 0.78, "Canal de corriente ralentiza desplazamiento normal")
			choir.silence_left = 5
			dynamics._physics_process(0.01)
			verify(arena.player.terrain_speed_factor == 1, "Bomba silenciada también detiene la corriente")
			choir.exposure_left = 0
			var before: Vector2 = choir.position
			for step: int in range(30): choir._physics_process(1.0 / 60)
			verify(choir.position.distance_to(before) > 1, "Coro se desplaza para defender enlaces")
			choir.waves.clear()
			choir.marks.clear()
			choir.pulse_timer = 100
			choir.mark_timer = 100
			choir.waves.append({"radius": 90.0, "hit": false, "origin": Vector2(320, 200), "gap": PI / 2})
			arena.player.position = Vector2(320, 320)
			choir._physics_process(0.3)
			verify(arena.player.health == 100, "Abertura cian deja atravesar pulso sin daño")
		if index == 4:
			var mother: MadreCero = boss as MadreCero
			mother.relays[1].health = 10
			mother.tactics.cooldowns.clear()
			mother.tactics.history.clear()
			verify(mother.choose_relay() == 1, "Madre Cero detecta relé vulnerable")
			verify(mother.choose_relay() != 1, "Memoria evita bombardear siempre el mismo relé")
			var saboteur: EncounterSentinel = dynamics.spawn_sentinel(mother.relays[0].position + Vector2(0, 25))
			saboteur.set_physics_process(false)
			saboteur.cooldown = 0
			saboteur._physics_process(0.01)
			var hp: int = mother.relays[0].health
			saboteur._physics_process(1.0)
			verify(mother.relays[0].health == hp - 9, "Saboteador daña infraestructura tras aviso")
			mother.guard_time = 4
			saboteur.cooldown = 0
			saboteur._physics_process(0.01)
			saboteur._physics_process(1.0)
			verify(mother.relays[0].health == hp - 9, "Escudo frena sabotaje")
			for relay: NetworkRelay in mother.relays: relay.health = 0
			verify(mother.choose_relay() == -1, "No prioriza infraestructura que ya está destruida")
			mother.pulse = 0
			mother.marks.clear()
			mother._physics_process(0.01)
			verify(mother.marks.size() == 1 and mother.marks[0].relay == -1, "Sin relés apunta al jugador con aviso")
			for relay: NetworkRelay in mother.relays: relay.health = 90
		if index == 3:
			var prefect: ElPrefecto = boss as ElPrefecto
			prefect.chained_thrust = false
			prefect.change_state(Recaudador.State.CHARGE_WINDUP, 0)
			prefect.charge_direction = Vector2.RIGHT
			arena.player.invulnerable = 100
			var recovered: bool = false
			for step: int in range(100):
				prefect._physics_process(0.1)
				if prefect.state == Recaudador.State.RECOVER:
					recovered = true
					break
			verify(recovered and prefect.charges_left == 0, "El combo de dos estocadas termina y permite contraatacar")
		boss.phase = 2
		boss.update_puppet(0.05)
		await picture(index)
		var clock: float = dynamics.elapsed
		dynamics.set_physics_process(true)
		paused = true
		await create_timer(0.05, true).timeout
		verify(dynamics.elapsed == clock, "Pausa suspende dispositivos y llegadas: %d" % index)
		paused = false
		dynamics.set_physics_process(false)
		arena.finish(false)
		verify(dynamics.summons.is_empty() and dynamics.sentinels.is_empty() and dynamics.device_effects.is_empty(), "Terminar limpia peligros y escoltas: %d" % index)
		arena.free()
		await process_frame
	verify(DebrisEmitter.live_count == 0, "Cerrar arenas libera efectos")
	print("Tácticas de cinco jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
