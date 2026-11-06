extends SceneTree
## Puesta en escena de los jefes finales: solo cosmética, acotada y accesible.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func arena_for(zone: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
	arena.zone_index = zone
	root.add_child(arena)
	return arena

func spectacle_of(arena: RecaudadorArena) -> BossSpectacle:
	for child: Node in arena.world.get_children():
		if child is BossSpectacle: return child
	return null

func run_checks() -> void:
	var prefs: GamePreferences = GamePreferences.current()
	var original: bool = prefs.values.reduced_flashes
	prefs.values.reduced_flashes = false
	for zone: int in [0, 1, 2]:
		var early: RecaudadorArena = arena_for(zone)
		await process_frame
		verify(spectacle_of(early) == null, "Solo los jefes finales tienen puesta en escena: %d" % zone)
		early.free()
	for zone: int in [3, 4]:
		var arena: RecaudadorArena = arena_for(zone)
		await process_frame
		var show: BossSpectacle = spectacle_of(arena)
		var boss: Recaudador = arena.boss
		verify(show != null and show.card.modulate.a >= 0 and show.card_title.text == BossSpectacle.TITLES[show.id][0], "Tarjeta de nombre al entrar: %d" % zone)
		verify(arena.camera.zoom.x > show.base_zoom.x, "La cámara empieza acercada al jefe: %d" % zone)
		verify(boss.combat_visual.sprite.material == show.sprite_material and show.halo.get_parent() == boss.combat_visual, "Destello y contorno sobre el cuadro real: %d" % zone)
		# Golpe que entra: destello y pausa breve que se restaura.
		if boss is ElPrefecto: boss.change_state(Recaudador.State.RECOVER, 3)
		else: (boss as MadreCero).exposure = 3
		var dealt: int = boss.receive_hit(boss.position, 100)
		verify(dealt > 0 and show.flash > 0.9 and arena.impact.stop_active, "Golpe con destello e hit-stop: %d" % zone)
		await create_timer(0.08, true, false, true).timeout
		verify(not arena.impact.stop_active and Engine.time_scale == 1, "El hit-stop del jefe devuelve el tiempo: %d" % zone)
		# Transformación visible al cruzar la última guardia o el último protocolo.
		boss.health = int(boss.max_health * 0.29)
		boss.phase = 2
		if boss is ElPrefecto: (boss as ElPrefecto).last_guard = true
		else: (boss as MadreCero).last_protocol = true
		boss.phase_changed.emit(2)
		await process_frame
		verify(show.stage == 2 and show.halo.visible and arena.phase_notice.text.begins_with("ÚLTIM"), "Transformación con aura, contorno y aviso: %d" % zone)
		# Muerte: cámara lenta temporal y tarjeta de victoria.
		boss.health = 1
		boss.receive_hit(boss.position, 100)
		await create_timer(0.08, true, false, true).timeout
		verify(show.dying and is_equal_approx(Engine.time_scale, 0.3), "Muerte en cámara lenta tras el hit-stop final: %d" % zone)
		verify(show.card_title.text == "VICTORIA", "Momento de victoria: %d" % zone)
		await create_timer(1.3, true, false, true).timeout
		verify(Engine.time_scale == 1, "La cámara lenta se restaura sola: %d" % zone)
		verify(show.embers.size() <= 90 and show.rings.size() <= 16, "Partículas acotadas: %d" % zone)
		arena.free()
		await process_frame
	# Accesibilidad: sin destellos fuertes ni hit-stop; salir a mitad de cámara lenta la restaura.
	prefs.values.reduced_flashes = true
	var calm: RecaudadorArena = arena_for(3)
	await process_frame
	var quiet: BossSpectacle = spectacle_of(calm)
	calm.boss.change_state(Recaudador.State.RECOVER, 3)
	calm.boss.receive_hit(calm.boss.position, 100)
	verify(quiet.flash <= 0.41 and not calm.impact.stop_active, "Destellos reducidos: sin hit-stop y destello suave")
	calm.boss.health = 1
	calm.boss.receive_hit(calm.boss.position, 100)
	verify(quiet.screen_flash.color.a == 0, "Destellos reducidos: sin fogonazo de pantalla al morir")
	calm.free()
	await process_frame
	verify(Engine.time_scale == 1, "Liberar la arena durante la cámara lenta restaura el tiempo")
	prefs.values.reduced_flashes = original
	print("Puesta en escena de jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
