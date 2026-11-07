extends SceneTree
var failures: int = 0
func _initialize() -> void: call_deferred("run_checks")
func verify(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run_checks() -> void:
	SaveSystem.engagement_path = "user://guide_test.cfg"
	SaveSystem.store_engagement({"guide": 0, "record": 0, "achievements": []})
	var world: District = load("res://levels/main.tscn").instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.story.present_dialogue = false
	var guide: FirstSteps = world.first_steps
	guide.enabled = true
	guide.persist = true
	guide.restart()
	var scrap: int = world.bank.scrap
	guide.tick(8.1)
	verify(guide.step == 0 and guide.idle > 8, "Inactividad no completa objetivos")
	world.player.position.x += 40
	guide.tick(0)
	verify(guide.step == 1 and world.bank.scrap == scrap + 8, "Mover premia una sola vez")
	world.bank.add_parts(12)
	guide.tick(0)
	verify(guide.step == 2, "Recoger piezas avanza")
	world.core.restore({"tier": 1, "ordered": false, "progress": 0})
	guide.tick(0)
	verify(guide.step == 3, "Núcleo completado")
	for site: ConstructionSite in world.construction.sites:
		if site.data.blocks_enemies: site.complete_work()
	guide.tick(0)
	for plot: ClearanceSite in world.frontier.plots: plot.cleared = true
	guide.tick(0)
	world.expansion.sites[2].hp = 180
	guide.tick(0)
	world.bank.add_parts(10)
	guide.tick(0)
	world.core.restore({"tier": 2, "ordered": false, "progress": 0})
	guide.tick(0)
	for site: ConstructionSite in world.construction.sites:
		if not site.data.blocks_enemies: site.complete_work()
	guide.tick(0)
	world.cycle.phase = "NOCHE"
	guide.tick(0)
	world.cycle.day = 2
	guide.tick(0)
	verify(guide.step == FirstSteps.COUNT and SaveSystem.engagement_profile().guide == FirstSteps.COUNT, "Guía persistida al amanecer")
	var another: FirstSteps = FirstSteps.new()
	another.setup(world)
	verify(another.step == FirstSteps.COUNT, "Recargar no repite una guía completa")
	another.free()
	guide.tick(50)
	verify(world.bank.scrap == scrap + 8 * FirstSteps.COUNT, "Recompensas sin duplicados")
	guide.restart()
	verify(guide.step == 0 and SaveSystem.engagement_profile().guide == 0, "Opciones reinicia guía")
	var done: Dictionary = SaveSystem.engagement_profile()
	done.guide = FirstSteps.COUNT
	done.tips = ["journal"]
	SaveSystem.store_engagement(done)
	MainMenu.reset_guide()
	var fresh: Dictionary = SaveSystem.engagement_profile()
	verify(fresh.guide == 0 and fresh.tips.is_empty() and fresh.record == done.record, "Partida nueva vuelve a mostrar la guía y conserva el récord")
	world.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.engagement_path))
	print("PASS: first_steps; fallos: %d" % failures)
	quit(1 if failures else 0)
