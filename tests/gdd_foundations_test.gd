extends SceneTree
var world: District
var checks: int = 0
var failures: int = 0
var capture: bool = false
const PATH: String = "user://gdd_test.json"

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func work(seconds: float) -> void:
	for step: int in range(ceili(seconds * 10)):
		world.colony.update_workers(0.1)
		world.civic.tick(0.1)
		world.expansion.tick(0.1)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/gdd/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/gdd"))
	GamePreferences.current().briefing_requested = false
	world = load("res://levels/zones/foundry.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.modules.set_physics_process(false)
	world.experience.present_choices = false
	world.bank.scrap = 2000
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	verify(world.construction.toggle_power(world.construction.sites[1]) and world.bank.energy_used() == 2, "Desactivar torreta libera energía sin destruirla")
	verify(world.construction.toggle_power(world.construction.sites[1]) and world.bank.energy_used() == 4, "Reactivar comprueba y reserva capacidad")
	world.player.position.x = world.construction.sites[1].x
	Input.action_press("interact")
	world.interaction.update_interaction(0)
	world.interaction.update_interaction(0.81)
	world.interaction.update_interaction(2)
	verify(world.construction.sites[1].powered and not world.construction.sites[1].ordered, "E bloqueada por tecnología no cambia alimentación ni encarga obras")
	Input.action_release("interact")
	world.interaction.update_interaction(0)
	# El resto de esta suite comprueba profesiones y murallas; la progresión tiene suite propia.
	world.core.restore({"tier": 3, "ordered": false, "progress": 0})
	verify(world.civic.gates.size() == 2 and world.expedition.repeaters.size() == 2, "Fundición tiene dos brechas intermedias y dos repetidores terminales")
	verify(world.civic.entrance(-1) == -1180, "Las oleadas parten de la entrada abierta más cercana")
	verify(not world.expedition.can_travel(), "No viaja antes de estabilizar colonia y entradas")
	verify(not world.expansion.interact(-103), "La brecha bloquea construir detrás de su frontera")
	verify(world.expansion.interact(-102), "Pagar generador dentro de la franja accesible")
	var generator: ExpansionOutpost = world.expansion.sites[2]
	world.expansion.tick(30)
	verify(generator.hp == 0 and generator.progress == 0, "Un módulo no se construye sin trabajadores")
	work(5)
	verify(generator.hp == 0, "El constructor debe recorrer la distancia real")
	work(25)
	verify(generator.hp == 180 and world.bank.available_capacity() == 6, "Constructor entrega generador operativo")
	verify(world.expansion.interact(-100), "Paga cuartel con energía disponible")
	work(25)
	var barracks: ExpansionOutpost = world.expansion.sites[0]
	verify(barracks.hp == 180 and barracks.ally == null, "El cuartel vacío no crea soldados gratis")
	verify(world.civic.interact(-300) and world.civic.villagers.size() == 1, "Campamento recluta persona sin profesión")
	verify(world.civic.interact(-322) and world.civic.tools[2] == 1, "El fusil queda disponible en el puesto de herramientas")
	work(15)
	verify(barracks.staffed and barracks.ally != null and barracks.ally.role == "ranger", "El superviviente camina a la herramienta y ocupa el cuartel")
	var ranger: FieldAlly = barracks.ally
	ranger.take_damage(100)
	verify(not barracks.staffed and world.civic.villagers.size() == 1, "La derrota desarma al soldado y devuelve un superviviente")
	work(20)
	verify(ranger.hp == 0, "No hay relevos gratuitos por esperar")
	verify(world.civic.interact(-322), "Rearmar requiere pagar otra herramienta")
	work(10)
	verify(barracks.staffed and barracks.ally.hp == 90, "Una nueva herramienta rearma a la persona")
	verify(world.civic.interact(-300) and world.civic.interact(-323), "Reclutar y comprar escudo usa la misma economía")
	work(20)
	verify(barracks.staff_count() == 2, "El cuartel aloja una escuadra de varias personas")
	var guardian: FieldAlly = barracks.squad[1]
	guardian.take_damage(20)
	verify(guardian.role == "guardian" and guardian.hp == 83, "Guardián equipado reduce daño con escudo")
	verify(world.civic.interact(-301) and world.civic.interact(-324), "Contratar técnico y pagar su herramienta")
	work(35)
	verify(generator.ally != null and generator.ally.role == "technician", "El técnico ocupa un generador real")
	generator.take_damage(30)
	generator.ally.cooldown = 0
	generator.ally.tick(3.1)
	verify(generator.hp == 158, "Técnico repara infraestructura sin crear energía ficticia")
	verify(world.expansion.interact(-101), "Encarga puesto médico")
	work(30)
	verify(world.civic.interact(-301) and world.civic.interact(-325), "Recluta médico con botiquín")
	work(35)
	var medical: ExpansionOutpost = world.expansion.sites[1]
	verify(medical.ally != null and medical.ally.role == "medic", "Médico ocupa el puesto de salud")
	world.player.position.x = medical.position.x
	world.player.health = 60
	medical.ally.cooldown = 0
	medical.ally.tick(0.01)
	verify(world.player.health == 68, "Sanitario restaura vida con alcance y cadencia")
	world.player.health = 100
	verify(world.civic.interact(-340), "Se paga muralla exterior")
	world.cycle.phase = "NOCHE"
	work(15)
	verify(world.civic.walls[0].hp == 0 and world.civic.walls[0].progress == 0, "Obra exterior desprotegida espera hasta el día")
	world.cycle.phase = "DÍA"
	work(25)
	var wall: ConstructionSite = world.civic.walls[0]
	verify(wall.hp == 240 and world.civic.frontier(-1) == 600, "Una muralla terminada amplía el perímetro real")
	verify(world.civic.interact(-340), "Encarga mejora de muralla")
	work(20)
	verify(wall.tier == 2 and wall.max_hp == 480, "Mejora por trabajo aumenta integridad y nivel")
	verify(world.civic.interact(-340), "Encarga tercer nivel")
	work(20)
	verify(wall.tier == 3 and wall.max_hp == 720 and not world.civic.interact(-340), "Tres niveles y tope sin cobros adicionales")
	verify(world.civic.interact(-360) and world.civic.capacity == 12, "Refugio amplía capacidad de población")
	var workforce: int = world.colony.workers.size()
	var waiting: int = world.civic.villagers.size()
	world.civic.capacity = 20
	world.colony.add_worker(&"collector")
	verify(world.civic.interact(-360) and world.colony.workers.size() == workforce and world.civic.villagers.size() == waiting + 1, "Refugio máximo permite reasignar profesiones sin bloquear una colonia llena")
	world.civic.capacity = 12
	var gate: EnemyRepeater = world.civic.gates[0]
	gate.hurtbox.receive(300)
	verify(world.civic.safe_to_build(-1320) and world.civic.entrance(-1) == -1440, "Cerrar brecha recupera terreno y desplaza la entrada")
	world.civic.tick(3.1)
	verify(get_nodes_in_group(GameRules.ENEMIES).size() == 3, "Destruir una brecha provoca contraataque anunciado")
	for enemy: Node in get_nodes_in_group(GameRules.ENEMIES): enemy.free()
	world.civic.retaliation.clear()
	world.player.position.x = -820
	world.player.get_node("Camera2D").reset_smoothing()
	world.player.get_node("Camera2D").force_update_scroll()
	world.view.queue_redraw()
	world.presenter.publish()
	await picture("colonia")
	world.experience.restore({})
	world.neural.kills = 0
	world.experience.drop(world.player.position, 8, true)
	world.experience.tick(0)
	verify(world.experience.level == 2 and world.experience.pending == 1 and world.experience.chest_pending == 1, "Datos recogidos suben nivel; élite deja cofre separado")
	var core: Dictionary
	for option: Dictionary in world.experience.options(true):
		if option.type == "core": core = option
	verify(world.experience.choose(core, true) and world.modules.cores == 1, "Cofre permite guardar su núcleo")
	var options: Array[Dictionary] = world.experience.options()
	verify(options.size() == 3 and options[0] != options[1] and options[1] != options[2], "Tres alternativas únicas mezclan armas pasivas e implantes")
	world.experience.present_choices = true
	world.experience.tick(0)
	var time_left: float = world.cycle.phase_remaining
	world.session._process(20)
	verify(paused and world.experience.panel.opened and world.cycle.phase_remaining == time_left, "Elegir nivel detiene la colonia y su reloj")
	await picture("subida_nivel")
	world.experience.panel.rows.get_child(1).pressed.emit()
	verify(not paused and world.experience.pending == 0, "Elegir una carta aplica mejora y devuelve el control")
	verify(not world.experience.choose(options[0], false), "Un nivel no se cobra dos veces")
	world.experience.present_choices = false
	world.experience.gain(200)
	world.modules.levels.drone = 5
	world.modules.passives.optic = true
	world.modules.passive_levels.optic = 1
	world.experience.chest_pending += 1
	world.experience.opened_chests += 1
	world.modules.cores += 1
	var evolution: Dictionary
	for option: Dictionary in world.experience.options(true):
		if option.type == "evolve": evolution = option
	verify(not evolution.is_empty() and world.experience.choose(evolution, true) and world.modules.evolved.drone, "Cofre ofrece evolución válida por arma cinco y pasiva compatible")
	verify(world.modules.equipped.size() <= 2 and world.modules.passive_count() <= 4 and ModuleSystem.PASSIVE_IDS.size() == 6, "Se eligen cuatro pasivas entre seis y dos armas automáticas")
	world.experience.gain(500)
	for id: String in ModuleSystem.PASSIVE_IDS:
		if id != "optic" and world.modules.passives[id]: world.modules.toggle_passive(id)
	verify(world.neural.install_passive("battery") and world.neural.install_passive("bearing") and world.neural.install_passive("magnet"), "Cuatro espacios aceptan una combinación elegida")
	verify(not world.neural.install_passive("condenser"), "No permite equipar una quinta pasiva")
	verify(world.modules.toggle_passive("optic") and world.neural.install_passive("condenser"), "Se puede cambiar catalizador después de evolucionar")
	verify(world.modules.evolved.drone and ModuleSystem.valid(world.modules.snapshot()), "Cambiar pasiva conserva evolución y guardado válido")
	for rank: int in range(4): world.neural.install_passive("condenser")
	verify(world.modules.passive_rank("condenser") == 5 and not world.neural.install_passive("condenser"), "Las pasivas suben hasta cinco y respetan el tope")
	world.experience.xp = 5
	world.player.health = 0
	world.experience.tick(0)
	verify(world.experience.xp == 0 and world.experience.lost.amount == 5, "Muerte deja señal de experiencia sin gastar")
	world.player.health = 100
	world.experience.tick(0)
	verify(world.experience.xp == 5 and world.experience.lost.is_empty(), "La señal recupera la experiencia al volver")
	var save: SaveSystem = SaveSystem.new()
	save.save_path = PATH
	save.session = world.session
	world.session.add_child(save)
	verify(save.save_game(), "Guardado acepta población herramientas murallas y niveles")
	var saved: Dictionary = save._snapshot()
	verify(save.load_game(), "Carga coherente sin duplicar población ni energía")
	var bad: Dictionary = saved.duplicate(true)
	bad.civic.tools[0] = -1
	verify(save.write_document(bad) and not save.load_game(), "Datos de herramientas inválidos se rechazan antes de aplicar")
	verify(save.write_document(saved) and save.load_game(), "Guardado válido permanece recuperable")
	save.delete_save()
	world.session.save_system = null
	world.player.health = 100
	world.experience.pending = 0
	paused = true
	world.presenter.publish()
	await picture("pausa")
	verify(world.get_node("HUD").pause_panel.get_global_rect().end.x <= 640 and world.get_node("HUD").pause_panel.get_global_rect().end.y <= 360, "Pausa ampliada conserva todos los controles dentro de pantalla")
	paused = false
	world.presenter.publish()
	verify(world.clinic_panel.open_panel(), "Clínica conserva descanso y configuración")
	await picture("clinica")
	world.clinic_panel.tabs.current_tab = 1
	await picture("equipo")
	world.clinic_panel.close_panel()
	world.free()
	await process_frame
	var arena: RecaudadorArena = load("res://levels/expedition/caldera_arena.tscn").instantiate() as RecaudadorArena
	root.add_child(arena)
	arena.boss.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.player.set_physics_process(false)
	var boiler: SantaCaldera = arena.boss as SantaCaldera
	await physics_frame
	var start: Vector2 = boiler.position
	for frame: int in range(30):
		await physics_frame
		boiler._physics_process(1.0 / 60.0)
	verify(start.distance_to(boiler.position) > 15, "Santa Caldera se desplaza por la plataforma")
	boiler.phase = 2
	boiler.change_state(Recaudador.State.VOLLEY, 0)
	boiler._physics_process(0.01)
	verify(boiler.state == Recaudador.State.CHARGE_WINDUP and boiler.charges_left == 2, "Segunda fase anuncia dos arremetidas")
	await picture("caldera")
	boiler._physics_process(1.11)
	start = boiler.position
	for frame: int in range(6):
		await physics_frame
		boiler._physics_process(1.0 / 60.0)
	verify(start.distance_to(boiler.position) > 20, "Arremetida mueve el cuerpo tras el aviso")
	var angled: int = 0
	for child: Node in arena.world.get_children():
		if child is StaticBody2D and absf(child.rotation) > 0.1: angled += 1
	verify(angled >= 4, "Arena tiene diagonales físicas y forma octogonal")
	arena.free()
	await process_frame
	var menu: MainMenu = load("res://ui/main_menu.tscn").instantiate() as MainMenu
	root.add_child(menu)
	await picture("menu")
	var briefing: BriefingPanel = BriefingPanel.new()
	briefing.zone = CampaignRoute.zone(1)
	root.add_child(briefing)
	briefing.open_panel()
	await process_frame
	verify(briefing.begin_button.get_global_rect().end.y <= 350, "Introducción cabe con la fuente legible")
	await picture("introduccion")
	briefing.close_panel()
	briefing.free()
	menu.options.open_panel()
	await picture("opciones")
	menu.options.close_panel()
	menu.free()
	await process_frame
	print("GDD: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
