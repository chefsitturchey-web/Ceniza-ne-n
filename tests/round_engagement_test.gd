extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_checks")
func verify(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run_checks() -> void:
	SaveSystem.engagement_path = "user://round_test.cfg"
	SaveSystem.store_engagement({"guide": 6, "record": 0, "achievements": []})
	var world: District = load("res://levels/main.tscn").instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.story.present_dialogue = false
	world.rewards_hud.present_results = false
	var progress: RoundEngagement = world.engagement
	progress.enabled = true
	progress.persist = true
	progress.on_phase("NOCHE", 1)
	var scrap: int = world.bank.scrap
	progress.register_kill(2)
	progress.register_kill(2)
	progress.register_kill(2)
	verify(progress.combo == 3 and world.bank.scrap == scrap + 6, "Combo paga solo el extra sobre botín base")
	progress.tick(2.51)
	progress.register_kill(2)
	verify(progress.combo == 1, "Cadena caduca a los 2.5 s")
	for index: int in 6: progress.register_kill(2)
	verify(progress.night_kills == 10, "Cuenta bajas nocturnas")
	var before_dawn: int = world.bank.scrap
	progress.on_phase("DÍA", 2)
	verify(progress.goal_paid and world.bank.scrap == before_dawn + 25, "Meta paga al sobrevivir sin perder muros")
	progress.on_phase("DÍA", 2)
	verify(world.bank.scrap == before_dawn + 25, "Amanecer duplicado no vuelve a pagar")
	var stats: Dictionary = progress.result(true, true)
	verify(stats.stars == 3 and stats.record > 0, "Tres estrellas y récord")
	verify("combo" in SaveSystem.engagement_profile().achievements and "night" in SaveSystem.engagement_profile().achievements, "Logros persistidos")
	progress.on_phase("NOCHE", 2)
	world.construction.sites[0].destroyed.emit()
	for index: int in 10: progress.register_kill(0)
	progress.on_phase("DÍA", 3)
	verify(not progress.goal_paid and progress.walls_lost == 1, "Perder un muro invalida meta")
	world.rewards_hud.present_results = true
	world.rewards_hud.show_result(progress.result(false, false))
	verify(paused and world.rewards_hud.result_open and world.rewards_hud.star_row.get_child_count() == 3, "Resultado modal con estrellas propias")
	world.rewards_hud.close_result()
	verify(not paused and not world.rewards_hud.result_open, "Seguir devuelve el control")
	var record: int = SaveSystem.engagement_profile().record
	progress.kills = 0
	progress.nights = 0
	progress.best_combo = 0
	progress.result(false, false)
	verify(SaveSystem.engagement_profile().record == record, "Récord no disminuye")
	var previous_kills: int = progress.kills
	world.session.debug_practice = true
	progress.register_kill(10)
	verify(progress.kills == previous_kills, "Laboratorio no entrega progreso persistente")
	world.session.debug_practice = false
	world.impact.active = false
	progress.combo_left = 0
	var enemy: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres"))
	enemy.set_physics_process(false)
	var before_kill: int = world.bank.scrap
	enemy.take_damage(enemy.health)
	verify(progress.kills == previous_kills + 1 and world.bank.scrap == before_kill + enemy.data.reward, "Baja real conecta estadísticas sin duplicar recompensa base")
	world.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.engagement_path))
	print("PASS: round_engagement; fallos: %d" % failures)
	quit(1 if failures else 0)
