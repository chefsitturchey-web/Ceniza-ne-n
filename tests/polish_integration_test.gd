extends SceneTree

var checks: int = 0
var failures: int = 0
const PATH: String = "user://polish_test.json"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func snapshot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run_checks() -> void:
	GamePreferences.current().briefing_requested = true
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	current_scene = world
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var initial_time: float = world.cycle.phase_remaining
	verify(world.briefing != null and world.briefing.opened and paused, "Nueva colonia muestra explicación sin gastar el día")
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/pulido"))
		await snapshot("res://.godot/pulido/instrucciones.png")
	world.session._process(8)
	verify(world.cycle.phase_remaining == initial_time, "El reloj permanece detenido al leer controles")
	var stamina: float = world.player.stamina
	world.briefing.close_panel()
	Input.action_press("dodge")
	world.player._physics_process(0.016)
	Input.action_release("dodge")
	verify(not paused and world.player.stamina == stamina, "Cerrar explicación no dispara una esquiva accidental")
	await process_frame
	await process_frame
	verify("Construye" in world.presenter.objective_text(), "Primer objetivo indica cómo construir")
	paused = true
	world.presenter.publish()
	verify(world.get_node("HUD").pause_panel.resume_button.has_focus(), "Pausa entrega el foco a Continuar para jugar con mando")
	world.get_node("HUD").pause_panel.resume_button.pressed.emit()
	verify(not paused, "Continuar de la pausa reanuda por botón")
	var turrets: Array[ConstructionSite] = []
	for site: ConstructionSite in world.construction.sites:
		site.complete_work()
		if site.kind == &"turret":
			turrets.append(site)
	verify("0/2" in world.presenter.objective_text(), "Con defensas encargadas señala las antenas")
	var turret: ConstructionSite = turrets[0]
	var base_position: Vector2 = turret.position
	verify(turret.turret_visual != null, "Torreta dispone de cabezal articulado")
	var enemy: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/errante.tres"))
	enemy.set_physics_process(false)
	enemy.position = Vector2(turret.x - 140, GameRules.FLOOR_Y)
	world.defenses.drone_timer = 100
	var hp: int = enemy.health
	world.defenses.update_defenses(0)
	verify(enemy.health == hp - turret.data.damage, "Disparo de torreta aplica el daño configurado")
	verify(turret.turret_visual.facing == -1 and turret.turret_visual.tracking, "Cabezal sigue al enemigo exterior")
	verify(world.defenses.beams.size() == 1 and world.defenses.beams[0].from.is_equal_approx(turret.muzzle_position()), "Rayo y fogonazo parten de la misma boca de cañón")
	var previous_angle: float = turret.turret_visual.desired_angle
	enemy.position.y -= 45
	world.defenses.update_defenses(0)
	verify(turret.turret_visual.desired_angle < previous_angle, "La torreta eleva el cabezal para un enemigo alto")
	enemy.position = Vector2(turret.x + 80, GameRules.FLOOR_Y)
	world.defenses.update_defenses(0.1)
	verify(turret.turret_visual.facing == 1, "Gira al frente interior cuando el enemigo la supera")
	turret._process(0.2)
	verify(turret.recoil == 0 and turret.position == base_position, "El retroceso termina sin desplazar el pedestal ni colisiones")
	enemy.position.x = -900
	world.defenses.update_defenses(0)
	verify(not turret.turret_visual.tracking, "Abandona un blanco fuera de alcance")
	turret.turret_visual._process(1)
	verify(absf(turret.turret_visual.desired_angle) > 0, "Sin blancos patrulla visualmente")
	turret.take_damage(turret.max_hp)
	var beam_count: int = world.defenses.beams.size()
	world.defenses.update_defenses(2)
	verify(world.defenses.beams.size() == beam_count, "Una torreta destruida no dispara")
	turret.complete_work()
	enemy.position.x = turret.x - 100
	world.player.position.x = turret.x
	world.overload.activate_overload()
	turret.shot = 0
	world.defenses.update_defenses(0)
	verify(turret.boosted and turret.shot == turret.data.overloaded_interval, "La animación conserva la cadencia de sobrecarga")
	world.player.position.x = 0
	var collector: ColonyWorker = world.colony.workers[1]
	collector.x = collector.side * collector.data.gather_distance
	collector.gather = 0
	collector.cargo = 0
	world.colony.update_workers(0.1)
	verify(collector.visual.working and collector.visual.sprite.animation == &"reparar", "Recuperador trabaja de verdad al alcanzar la chatarra")
	var gathered: float = collector.gather
	collector.visual._process(0.4)
	verify(collector.gather == gathered, "Las chispas de trabajo no alteran la economía")
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/pulido"))
		for node: Node in world.find_children("*", "Node2D", true, false):
			if node is DebrisEmitter.Pixel:
				node.free()
		world.get_node("HUD").hide()
		world.view.set_process(false)
		turret.set_process(false)
		turret.turret_visual.set_process(false)
		var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
		camera.position_smoothing_enabled = false
		camera.global_position = Vector2(turret.x, 220)
		camera.zoom = Vector2(3, 3)
		camera.force_update_scroll()
		enemy.health_component.maximum = 10000
		enemy.health = 10000
		for frame: int in range(30):
			var time: float = frame / 12.0
			enemy.position = Vector2(turret.x + cos(time * 2.8) * 85, GameRules.FLOOR_Y - maxf(0, sin(time * 2.0)) * 40)
			enemy.update_visual(true)
			turret._process(1.0 / 12.0)
			turret.turret_visual._process(1.0 / 12.0)
			world.defenses.update_beams(1.0 / 12.0)
			world.defenses.update_defenses(1.0 / 12.0)
			world.view.queue_redraw()
			await snapshot("res://.godot/pulido/torreta_%03d.png" % frame)
	enemy.take_damage(100000)
	world.expedition.restore({"destroyed": [true, false], "train_arrived": false})
	verify("1/2" in world.presenter.objective_text(), "El objetivo cuenta antenas reales")
	world.expedition.restore({"destroyed": [true, true], "train_arrived": false})
	verify("espera" in world.presenter.objective_text(), "El objetivo anuncia llegada del tren")
	world.expedition.station.restore(true, true)
	verify("Tren listo" in world.presenter.objective_text(), "El objetivo señala cómo viajar")
	var save: SaveSystem = SaveSystem.new()
	world.defenses.drone_timer = 0.5
	save.session = world.session
	save.save_path = PATH
	world.session.add_child(save)
	world.session.save_system = save
	verify(save.save_game(), "Guardado mediante archivo temporal")
	var exact: String = FileAccess.get_file_as_string(PATH)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	world.bank.scrap += 7
	verify(not save.save_game() and FileAccess.get_file_as_string(PATH) == exact, "Un fallo de escritura conserva intacto el checkpoint anterior")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + ".tmp"))
	verify(world.expedition.start(), "Viaje de prueba al jefe")
	verify(FileAccess.get_file_as_string(PATH) != exact and "\"train_arrived\":true" in FileAccess.get_file_as_string(PATH), "El viaje guarda preparación y tren antes de suspender la colonia")
	var arena: RecaudadorArena = world.expedition.arena as RecaudadorArena
	arena.boss.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.set_process(false)
	arena.player.facing = Vector2.UP
	arena.player.velocity = Vector2.UP * arena.player.speed
	arena.player.elapsed = 0.1
	arena.player.update_visual()
	var foot: float = arena.player.stride.left_step
	verify(arena.player.stride.visible and not arena.player.sprite.visible, "Carrera norte articula la vista existente")
	arena.player.elapsed = 0.35
	arena.player.update_visual()
	verify(arena.player.stride.left_step != foot and arena.player.stride.right_step == -arena.player.stride.left_step, "Los pies alternan pasos independientes")
	arena.player.facing = Vector2.DOWN
	arena.player.update_visual()
	verify(arena.player.stride.source == TopdownPlayer.VIEWS[0], "Carrera sur conserva el aspecto del personaje")
	arena.player.facing = Vector2.RIGHT
	arena.player.velocity = Vector2.ZERO
	arena.player.cooldown = 0
	arena.player.attack()
	arena.player.update_visual()
	verify(arena.player.runner.visible and arena.player.runner.animation == &"ataque", "Ataque lateral usa la animación de espada existente")
	arena.toggle_pause()
	arena.options.open_panel()
	arena.options.close_panel()
	verify(paused and arena.pause_panel.visible, "Opciones del jefe vuelven a la misma pausa")
	await process_frame
	await process_frame
	arena.toggle_pause()
	if "--capture" in OS.get_cmdline_user_args():
		arena.camera.position_smoothing_enabled = false
		arena.camera.zoom = Vector2(3, 3)
		arena.player.slash_remaining = 0
		for frame: int in range(30):
			arena.player.facing = Vector2.UP if frame < 15 else Vector2.DOWN
			arena.player.velocity = arena.player.facing * arena.player.speed
			arena.player.attack_anim_remaining = 0
			arena.player.elapsed = frame / 12.0
			arena.player.update_visual()
			arena.camera.force_update_scroll()
			await snapshot("res://.godot/pulido/portador_%03d.png" % frame)
	world.expedition.resolve(true)
	var buttons: int = arena.find_children("*", "Button", true, false).size()
	arena.show_completed()
	verify(arena.completed and "COMPLETADO" in arena.banner.text and arena.find_children("*", "Button", true, false).size() == buttons, "Final de demo claro e idempotente")
	if "--capture" in OS.get_cmdline_user_args():
		await snapshot("res://.godot/pulido/final-demo.png")
	var finish_button: Button = null
	for node: Node in arena.find_children("*", "Button", true, false):
		if (node as Button).text == "Volver al menú":
			finish_button = node as Button
	verify(finish_button != null, "El final ofrece volver al menú")
	if finish_button != null:
		finish_button.pressed.emit()
	await process_frame
	await process_frame
	verify(current_scene is MainMenu and not paused, "Regreso real al menú sin dejar pausado el árbol")
	var leftovers: int = 0
	for node: Node in root.get_children():
		if node is RecaudadorArena:
			leftovers += 1
	verify(leftovers == 0, "No quedan arenas hermanas huérfanas tras salir")
	var menu: Node = current_scene
	current_scene = null
	menu.free()
	for path: String in [PATH, PATH + ".tmp", PATH + ".anterior"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	GamePreferences.current().input_block_frame = -1
	await process_frame
	print("Pulido jugable: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
