extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_checks")
func verify(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run_checks() -> void:
	var impact: ImpactFeedback = ImpactFeedback.new()
	root.add_child(impact)
	var prefs: GamePreferences = GamePreferences.current()
	var original: bool = prefs.values.reduced_flashes
	prefs.values.reduced_flashes = false
	impact.hit(Vector2.ZERO, 25, true)
	verify(impact.numbers.size() == 1 and impact.shake > 0 and impact.stop_active, "Matar crea impacto y hit-stop")
	verify(ImpactFeedback.hit_stops == 1, "Laboratorio distingue hit-stop de una velocidad de práctica")
	await create_timer(0.08, true, false, true).timeout
	verify(not impact.stop_active and Engine.time_scale == 1, "Hit-stop restaura tiempo real tras 55 ms")
	verify(ImpactFeedback.hit_stops == 0, "Hit-stop libera su registro global")
	for index: int in 60: impact.collect(Vector2.ZERO, 3)
	verify(impact.numbers.size() <= 32 and impact.flights.size() <= 36, "Presupuesto acotado de efectos")
	prefs.values.reduced_flashes = true
	impact.shake = 0
	impact.hit(Vector2.ZERO, 12, true)
	verify(impact.shake == 0 and not impact.stop_active, "Accesibilidad elimina sacudida y hit-stop")
	prefs.values.reduced_flashes = false
	Engine.time_scale = 0.5
	impact.hit_stop()
	impact.free()
	verify(Engine.time_scale == 0.5, "Salir durante hit-stop conserva cámara lenta del laboratorio")
	Engine.time_scale = 1
	prefs.values.reduced_flashes = original
	print("PASS: impact_feedback; fallos: %d" % failures)
	quit(1 if failures else 0)
