extends SceneTree
## Golpes cuerpo a cuerpo de los cinco jefes y pistas de combate.
## Cada jefe castiga a un jugador quieto y pegado, siempre con aviso antes del daño,
## y una esquiva o un paso fuera de la forma avisada evitan el golpe.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func arena_for(index: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
	arena.zone_index = index
	root.add_child(arena)
	arena.set_process(false)
	arena.boss.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.dynamics.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.combat_effects.set_physics_process(false)
	arena.combat_effects.set_process(false)
	return arena

## Avanza al jefe hasta que termine el aviso; devuelve si hubo daño antes de tiempo.
func wind(boss: Recaudador, player: TopdownPlayer, start: int) -> bool:
	var early: bool = false
	var guard: int = 0
	while boss.melee_winding() and guard < 200:
		if player.health != start: early = true
		boss._physics_process(1.0 / 60)
		guard += 1
	return early

func quiet(boss: Recaudador) -> void:
	# Aísla el golpe cercano de pulsos y marcas propios del jefe.
	if boss is CoroSumergido:
		(boss as CoroSumergido).pulse_timer = 99
		(boss as CoroSumergido).mark_timer = 99
	if boss is MadreCero: (boss as MadreCero).pulse = 99

func run_checks() -> void:
	for index: int in 5:
		var arena: RecaudadorArena = arena_for(index)
		await physics_frame
		var boss: Recaudador = arena.boss
		var player: TopdownPlayer = arena.player
		quiet(boss)
		var profile: Dictionary = boss.melee_profile()
		for key: String in ["combo", "finisher", "lunge", "shove"]:
			verify(profile.has(key), "Perfil cuerpo a cuerpo completo (%s): %d" % [key, index])
		verify(profile.combo.size() >= 2, "Combo de al menos dos golpes: %d" % index)
		# Equidad: ningún aviso baja de 0.4 s, ni en la fase más rápida.
		boss.phase = 2
		if boss is ElPrefecto: (boss as ElPrefecto).last_guard = true
		if boss is MadreCero: (boss as MadreCero).last_protocol = true
		var moves: Array = profile.combo.duplicate()
		moves.append_array([profile.finisher, profile.lunge, profile.shove])
		for move: Dictionary in moves:
			verify(maxf(0.4, float(move.windup) * boss.melee_tempo()) >= 0.4 and float(move.windup) >= 0.45, "Aviso suficiente en %s: %d" % [move.name, index])
		boss.phase = 1
		if boss is ElPrefecto: (boss as ElPrefecto).last_guard = false
		if boss is MadreCero: (boss as MadreCero).last_protocol = false

		# Jugador quieto y pegado: el combo lo alcanza, pero solo después del aviso.
		player.position = boss.position + Vector2(0, 60)
		player.health = 100
		player.invulnerable = 0
		boss.melee_cooldown = 0
		verify(boss.try_melee(60), "Abre combo contra un jugador pegado: %d" % index)
		verify(boss.melee_winding() and boss.melee.kind == "swing", "Empieza con un golpe avisado: %d" % index)
		verify(boss.melee_contains(player.global_position), "El aviso cubre al jugador quieto: %d" % index)
		verify(boss.status_text().contains(String(boss.melee.name).to_upper()), "El estado del jefe nombra el golpe: %d" % index)
		verify(boss.combat_visual != null, "Jefe con flipbook: %d" % index)
		boss.combat_visual.pose_boss(boss)
		verify(boss.combat_visual.state_name == "windup", "Usa el clip de preparación: %d" % index)
		var early: bool = wind(boss, player, 100)
		verify(not early, "Sin daño durante el aviso: %d" % index)
		boss._physics_process(1.0 / 60)
		verify(player.health < 100, "El golpe cercano daña al jugador quieto: %d" % index)
		boss.combat_visual.pose_boss(boss)
		verify(boss.combat_visual.state_name in ["attack", "windup"], "Clip de ataque tras el aviso: %d" % index)
		# Termina el combo sin dañar más allá de un golpe por ventana de invulnerabilidad.
		var guard: int = 0
		while boss.melee_active() and guard < 400:
			boss._physics_process(1.0 / 60)
			guard += 1
		verify(not boss.melee_active() and boss.melee_cooldown > 0, "El combo termina y deja respiro: %d" % index)

		# Salir de la forma fijada evita el golpe: el ataque se puede esquivar.
		player.position = boss.position + Vector2(0, 60)
		player.health = 100
		player.invulnerable = 0
		boss.melee_cooldown = 0
		boss.try_melee(60)
		while float(boss.melee.time) > float(boss.melee.windup) * 0.45: boss._physics_process(1.0 / 60)
		var locked: Vector2 = boss.melee.direction
		player.position = boss.position + Vector2(0, -170)
		boss._physics_process(1.0 / 60)
		verify(Vector2(boss.melee.direction).is_equal_approx(locked), "La dirección queda fija en la segunda mitad del aviso: %d" % index)
		wind(boss, player, 100)
		boss._physics_process(1.0 / 60)
		verify(player.health == 100, "Alejarse durante el aviso evita el golpe: %d" % index)
		boss.cancel_melee()

		# Esquivar en el último instante también lo evita (invulnerable durante la esquiva).
		player.position = boss.position + Vector2(0, 60)
		boss.melee_cooldown = 0
		boss.try_melee(60)
		while float(boss.melee.time) > 0.05: boss._physics_process(1.0 / 60)
		player.stamina = 100
		player.dodge()
		boss._physics_process(0.06)
		verify(player.health == 100, "Esquivar justo antes del impacto evita el daño: %d" % index)
		boss.cancel_melee()
		player.dodge_remaining = 0
		player.invulnerable = 0

		# Segunda fase: combo más largo y avisos más cortos.
		var first_windup: float = float(profile.combo[0].windup)
		boss.phase = 2
		boss.melee_cooldown = 0
		boss.try_melee(60)
		verify(boss.melee_queue.size() == profile.combo.size(), "Fase dos suma un remate al combo: %d" % index)
		verify(float(boss.melee.windup) < first_windup, "Fase dos acorta el aviso: %d" % index)
		boss.cancel_melee()
		boss.phase = 1

		# Embestida corta contra quien se queda quieto a media distancia.
		player.position = boss.position + Vector2(0, 200)
		player.health = 100
		player.invulnerable = 0
		boss.tactics.stationary_time = 2.0
		boss.melee_cooldown = 0
		verify(boss.try_melee(200), "Cierra distancia contra un jugador quieto: %d" % index)
		verify(boss.melee.kind == "lunge" and boss.melee_queue.size() == 1, "Embestida seguida de un golpe: %d" % index)
		verify(not wind(boss, player, 100), "La embestida no daña durante su aviso: %d" % index)
		for step: int in 20: boss._physics_process(1.0 / 60)
		verify(player.health < 100, "La embestida corta alcanza al jugador quieto: %d" % index)
		boss.cancel_melee()

		# Insistir contra la defensa provoca un empujón.
		if not boss is SantaCaldera:
			boss.blocked_streak = 2
			boss.blocked_clock = 2
			boss.melee_cooldown = 0
			player.position = boss.position + Vector2(0, 60)
			boss.try_melee(60)
			verify(boss.melee.name == profile.shove.name, "Golpear su defensa sin parar provoca %s: %d" % [profile.shove.name, index])
			boss.cancel_melee()

		# Con el núcleo expuesto no hay golpes cercanos: la ventana de castigo es real.
		if index == 2: (boss as CoroSumergido).exposure_left = 3
		elif index == 4: (boss as MadreCero).exposure = 3
		else: boss.state = Recaudador.State.STUNNED if index == 0 else Recaudador.State.RECOVER
		boss.melee_cooldown = 0
		verify(not boss.try_melee(60), "Sin golpes cercanos con el núcleo expuesto: %d" % index)

		await check_hints(arena)
		arena.free()
		await process_frame
	print("Golpes cercanos y pistas de jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func check_hints(arena: RecaudadorArena) -> void:
	var hints: BossHints = arena.hints
	var boss: Recaudador = arena.boss
	verify(hints != null and hints.label != null, "La arena crea las pistas: %d" % arena.zone_index)
	boss.cancel_melee()
	if arena.zone_index == 2: (boss as CoroSumergido).exposure_left = 0
	elif arena.zone_index == 4: (boss as MadreCero).exposure = 0
	boss.state = Recaudador.State.APPROACH
	hints.shown.clear()
	hints.queue.clear()
	hints.current = ""
	hints.left = 0
	hints.clock = 0
	BossHints.last_pad = false
	for step: int in 100: hints.advance(1.0 / 30)
	verify(hints.shown.has("controles") and hints.label.text.contains(KeyRemap.key_name(KeyRemap.binding("attack").key)), "Pista inicial con la tecla de ataque: %d" % arena.zone_index)
	verify(hints.label.text.contains(KeyRemap.key_name(KeyRemap.binding("dodge").key)), "Pista inicial con la tecla de esquiva: %d" % arena.zone_index)
	BossHints.last_pad = true
	verify(hints.text_for("controles").contains(KeyRemap.pad_name(KeyRemap.binding("attack").pad)), "Con mando muestra el botón: %d" % arena.zone_index)
	BossHints.last_pad = false
	for step: int in 160: hints.advance(1.0 / 30)
	verify(hints.shown.has("mecanica"), "Explica la mecánica propia del jefe: %d" % arena.zone_index)
	# Golpe cercano: pista urgente, una sola vez por pelea.
	boss.melee_cooldown = 0
	boss.try_melee(60)
	hints.advance(0.4)
	hints.advance(0.1)
	verify(hints.current == "melee", "Explica el primer golpe cercano: %d" % arena.zone_index)
	for step: int in 200: hints.advance(1.0 / 30)
	boss.cancel_melee()
	hints.advance(0.1)
	boss.melee_cooldown = 0
	boss.try_melee(60)
	for step: int in 10: hints.advance(1.0 / 30)
	verify(hints.current != "melee" and not "melee" in hints.queue, "La pista del golpe no se repite: %d" % arena.zone_index)
	boss.cancel_melee()
	# Núcleo expuesto: explica cómo castigar.
	if arena.zone_index == 2: (boss as CoroSumergido).exposure_left = 3
	elif arena.zone_index == 4: (boss as MadreCero).exposure = 3
	else: boss.state = Recaudador.State.STUNNED if arena.zone_index == 0 else Recaudador.State.RECOVER
	for step: int in 20: hints.advance(1.0 / 30)
	verify(hints.current == "expuesto" and hints.label.text.contains("doble"), "Explica cómo castigar el núcleo expuesto: %d" % arena.zone_index)
	var count: int = hints.shown.size()
	for step: int in 400: hints.advance(1.0 / 30)
	verify(hints.shown.size() >= count and hints.queue.is_empty(), "Las pistas se agotan sin repetirse: %d" % arena.zone_index)
	for id: String in ["controles", "mecanica", "melee", "lunge", "expuesto", "bloqueo", "marcas", "fase"]:
		var text: String = hints.text_for(id)
		var plain: bool = true
		for character: String in text:
			if character.unicode_at(0) > 0x24F: plain = false
		verify(plain and text.length() < 140, "Pista breve y sin símbolos (%s): %d" % [id, arena.zone_index])
