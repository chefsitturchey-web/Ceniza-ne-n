extends SceneTree
## Boss Rush: orden de campaña, curación parcial, resultados, mejor tiempo y entrada del menú.
## Nunca toca la partida guardada de la campaña.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func panel_text(rush: BossRush) -> String:
	var text: String = ""
	for node: Node in rush.panel.find_children("*", "Label", true, false): text += (node as Label).text + "\n"
	return text

func start_rush() -> BossRush:
	var rush: BossRush = (load("res://levels/expedition/boss_rush.tscn") as PackedScene).instantiate() as BossRush
	root.add_child(rush)
	await process_frame
	rush.arena.boss.set_physics_process(false)
	rush.arena.player.set_physics_process(false)
	return rush

func run_checks() -> void:
	BossRush.record_path = "user://boss_rush_prueba.cfg"
	if FileAccess.file_exists(BossRush.record_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(BossRush.record_path))
	var campaign: String = "user://partida.json"
	var campaign_before: String = FileAccess.get_file_as_string(campaign) if FileAccess.file_exists(campaign) else "<sin partida>"
	verify(BossRush.best_time() == 0.0, "Sin récord previo")
	verify(BossRush.format_time(83.45) == "01:23.4", "Formato de tiempo")

	# Recorrido completo en orden de campaña con curación parcial.
	var rush: BossRush = await start_rush()
	var scripts: Array = [Recaudador, SantaCaldera, CoroSumergido, ElPrefecto, MadreCero]
	verify(rush.arena.zone_index == 0 and rush.arena.rush and rush.arena.boss.get_script() == Recaudador, "Empieza por el Recaudador")
	verify(rush.timer_label.visible and rush.timer_label.text.contains("1/5"), "Cronómetro visible durante el combate")
	rush._process(1.5)
	verify(is_equal_approx(rush.elapsed, 1.5), "El cronómetro avanza en combate")
	paused = true
	rush._process(1.0)
	paused = false
	verify(is_equal_approx(rush.elapsed, 1.5), "El cronómetro se detiene en pausa")
	for number: int in 5:
		var arena: RecaudadorArena = rush.arena
		verify(arena.zone_index == number and is_instance_of(arena.boss, scripts[number]), "Jefe %d en orden de campaña" % number)
		verify(arena.player.attack_damage == 50 + BossRush.DAMAGE_STEP * number, "Filo de la ruta en el jefe %d" % number)
		if number == 0: verify(arena.player.health == 100, "Empieza con vida completa")
		arena.hit_count = 2
		arena.player.health = 30
		rush._process(10.0)
		rush._on_resolved(true)
		if number < 4:
			verify(rush.stage == "transition" and rush.arena == null, "Pantalla de transición tras el jefe %d" % number)
			verify(rush.health == 80, "Curación parcial entre jefes: 30 + 50")
			verify(panel_text(rush).contains("DERROTADO") and panel_text(rush).contains("Siguiente"), "La transición anuncia el siguiente jefe")
			verify(not rush.timer_label.visible, "Sin cronómetro sobre la transición")
			var frozen: float = rush.elapsed
			rush._process(5.0)
			verify(rush.elapsed == frozen, "La transición no suma tiempo")
			await process_frame
			rush.continue_run()
			await process_frame
			rush.arena.boss.set_physics_process(false)
			rush.arena.player.set_physics_process(false)
			verify(rush.arena.player.health == 80, "La vida curada pasa al siguiente combate")
	verify(rush.stage == "results" and rush.victory and rush.new_record, "Resultados al vencer a los cinco")
	verify(rush.hits == 10, "Suma los golpes recibidos de todos los jefes")
	var results: String = panel_text(rush)
	verify(results.contains("COMPLETADO") and results.contains("Tiempo") and results.contains("Golpes 10") and results.contains("1. "), "Resultados con tiempo, golpes y ranking")
	verify(rush.place == 0 and BossRush.ranking().size() == 1 and BossRush.ranking()[0].hits == 10, "La marca entra primera en el ranking")
	rush.name_edit.text = "Mara"
	rush.rename_entry()
	verify(BossRush.ranking()[0].name == "Mara" and BossRush.last_name() == "Mara", "El nombre del ranking se puede cambiar")
	for slot: int in 12: BossRush.submit("R%d" % slot, 9000 + slot, 0)
	verify(BossRush.ranking().size() == BossRush.RANKING_SIZE and BossRush.ranking()[0].name == "Mara", "El ranking guarda solo los 10 mejores, ordenados")
	verify(BossRush.submit("Lento", 99999, 0) == -1, "Un tiempo peor que el décimo no entra")
	verify(is_equal_approx(BossRush.best_time(), rush.elapsed), "Guarda el mejor tiempo en user://")
	var record: float = BossRush.best_time()
	rush.free()
	await process_frame

	# Derrota real a través de la arena: vuelve con resultados, sin pantallas de práctica.
	rush = await start_rush()
	rush._process(record + 30.0)
	rush.arena.player.health = 10
	rush.arena.player.take_damage(50)
	var arena: RecaudadorArena = rush.arena
	verify(arena.ending, "La muerte cierra el combate")
	for step: int in 4: arena._process(0.5)
	verify(rush.stage == "results" and not rush.victory and not arena.completed, "La derrota muestra los resultados del Boss Rush")
	verify(panel_text(rush).contains("Caíste ante"), "Resultados de derrota explican dónde caíste")
	var buttons: Array = rush.panel.find_children("*", "Button", true, false).map(func(node: Node) -> String: return (node as Button).text)
	verify("Volver al menú" in buttons and "Reintentar" in buttons, "Botones para volver al menú o reintentar")
	verify(not rush.new_record and BossRush.best_time() == record, "Una derrota no cambia el récord")
	rush.free()
	await process_frame

	# Una marca más lenta no sustituye al récord; una más rápida sí.
	rush = await start_rush()
	rush.index = 4
	rush.elapsed = record + 5
	rush.show_results(true, "MADRE CERO")
	verify(not rush.new_record and BossRush.best_time() == record, "Un tiempo peor no sustituye el récord")
	rush.elapsed = record - 5
	rush.new_record = false
	rush.show_results(true, "MADRE CERO")
	verify(rush.new_record and is_equal_approx(BossRush.best_time(), record - 5), "Un tiempo mejor sustituye el récord")
	rush.free()
	await process_frame

	# Entrada del menú principal.
	var menu: MainMenu = (load("res://ui/main_menu.tscn") as PackedScene).instantiate() as MainMenu
	menu.navigation_enabled = false
	root.add_child(menu)
	await process_frame
	var labels: Array = []
	for node: Node in menu.find_children("*", "Button", true, false): labels.append((node as Button).text)
	verify("Boss Rush" in labels and labels.find("Boss Rush") == labels.find("Nueva partida") + 1, "El menú ofrece Boss Rush tras Nueva partida")
	menu.free()

	var campaign_after: String = FileAccess.get_file_as_string(campaign) if FileAccess.file_exists(campaign) else "<sin partida>"
	verify(campaign_after == campaign_before, "El Boss Rush no toca la partida guardada")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BossRush.record_path))
	print("Boss Rush: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
