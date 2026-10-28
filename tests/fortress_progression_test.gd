extends SceneTree
var checks: int = 0
var failures: int = 0
var world: District
var capture: bool = false
const PATH: String = "user://fortress_progression_test.json"

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func work(seconds: float) -> void:
	for step: int in range(ceili(seconds * 10)):
		world.colony.update_workers(0.1)
		world.expansion.tick(0.1)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/fortress/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/fortress"))
	world = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	world.bank.scrap = 1000
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = PATH
	world.add_child(save)
	var wall: ConstructionSite = world.construction.sites[0]
	var turret: ConstructionSite = world.construction.sites[1]
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	var balance: int = world.bank.scrap
	verify(world.core.tier == 1 and world.core.health == 300, "Nace una base Nv.1 sin cambiar la integridad inicial")
	verify(not world.construction.order_site(wall) and not world.construction.order_site(turret) and world.bank.scrap == balance, "Nv.1 bloquea mejoras sin cobrar ni apagar la torreta")
	verify(not world.expansion.interact(-101) and not world.civic.interact(-323) and world.bank.scrap == balance, "Servicios y escudos bloqueados antes de Nv.2")
	verify(not world.core.request_upgrade() and world.bank.scrap == balance, "El núcleo requiere generación operativa")
	verify(world.expansion.interact(-102), "Generador básico disponible desde Nv.1")
	work(35)
	verify(world.expansion.energy_bonus() == 2, "El constructor entrega el generador")
	balance = world.bank.scrap
	verify(world.core.request_upgrade(), "Se encarga la primera mejora del núcleo")
	verify(world.bank.scrap == balance - 60 and world.core.tier == 1, "Pagar no completa el edificio")
	verify(not world.core.request_upgrade(), "No se paga dos veces una mejora en curso")
	world.colony.workers[0].x = -500
	work(0.1)
	verify(world.core.progress == 0, "El constructor debe llegar al núcleo")
	world.colony.workers[0].x = 0
	work(2)
	var partial: float = world.core.progress
	verify(save.save_game(), "Guarda una mejora del núcleo pagada y en curso")
	world.core.ordered = false
	verify(save.load_game() and world.core.ordered and is_equal_approx(world.core.progress, partial), "Cargar conserva obra y progreso sin volver a pagar")
	work(30)
	verify(world.core.tier == 2 and world.core.health == 450 and not world.core.ordered, "Trabajo real desbloquea Nv.2 e integridad nueva")
	verify(world.civic.interact(-323) and world.civic.interact(-324), "Nv.2 desbloquea escudos y herramientas técnicas")
	verify(world.expansion.interact(-101), "Nv.2 desbloquea el puesto médico")
	verify(world.construction.order_site(wall) and world.construction.order_site(turret), "Nv.2 permite reforzar muros y torretas")
	verify(wall.tier == 1 and turret.tier == 1, "Las defensas conservan su nivel durante las obras")
	work(35)
	verify(wall.tier == 2 and turret.tier == 2 and turret.max_hp == 200, "Ambas mejoras terminan mediante constructor")
	verify(FortressRules.damage(turret) > turret.data.damage and FortressRules.reach(turret) > turret.data.attack_range and FortressRules.interval(turret, false) < turret.data.interval, "La torreta mejorada cambia daño, alcance y cadencia")
	balance = world.bank.scrap
	verify(not world.construction.order_site(wall) and not world.construction.order_site(turret) and world.bank.scrap == balance, "El nivel del núcleo limita ambas defensas a Nv.2")
	verify(not world.core.request_upgrade(), "Nv.3 exige sobrevivir una noche")
	world.cycle.day = 2
	verify(world.core.request_upgrade(), "Noche resistida e instalaciones desbloquean Nv.3")
	work(25)
	verify(world.core.tier == 3 and world.core.health_component.maximum == 650, "El tercer diseño tiene integridad propia")
	verify(world.construction.order_site(wall) and world.construction.order_site(turret), "Nv.3 habilita fortificaciones avanzadas")
	work(20)
	verify(wall.tier == 3 and turret.tier == 3 and wall.max_hp == 720 and turret.max_hp == 300, "Niveles finales efectivos")
	balance = world.bank.scrap
	verify(not world.core.request_upgrade() and not world.construction.order_site(wall) and world.bank.scrap == balance, "El tope no cobra ni inventa un cuarto nivel")
	verify(world.construction.toggle_power(turret) and not turret.powered and world.construction.toggle_power(turret), "T conserva control energético independiente de mejorar")
	verify(save.save_game(), "Guarda núcleo y defensas avanzadas")
	world.core.restore({"tier": 1, "ordered": false, "progress": 0})
	verify(save.load_game() and world.core.tier == 3 and turret.tier == 3, "Carga valida la salud contra el nivel guardado, no el anterior")
	var legacy: Dictionary = save._snapshot()
	legacy.erase("core_building")
	verify(save.write_document(legacy) and save.load_game() and world.core.tier == 3, "Migra defensas antiguas sin rebajarlas")
	var malformed: Dictionary = save._snapshot()
	malformed.core_building.tier = 8
	verify(not save._valid(malformed), "Rechaza niveles inválidos antes de aplicar la partida")
	malformed.core_building.tier = 1
	verify(not save._valid(malformed), "No carga fortificaciones superiores a un núcleo explícito de Nv.1")
	var service_legacy: Dictionary = legacy.duplicate(true)
	for site: Dictionary in service_legacy.structures: site.tier = 1
	for site: Dictionary in service_legacy.civic.walls: site.tier = 1
	verify(ColonyCore.saved_tier(service_legacy) == 2, "Los servicios avanzados antiguos también conservan su tecnología")
	var outer: ConstructionSite = world.civic.walls[0]
	outer.complete_work()
	world.player.position.x = outer.position.x
	Input.action_press("interact")
	world.interaction.update_interaction(0)
	world.interaction.update_interaction(0.81)
	work(20)
	world.interaction.update_interaction(2)
	verify(outer.tier == 2 and not outer.ordered, "Mantener E no paga otro nivel al terminar la primera mejora")
	Input.action_release("interact")
	world.interaction.update_interaction(0)
	for tier: int in range(1, 4):
		for kind: String in ["core", "wall", "turret_base", "turret_head"]:
			var texture: Texture2D = FortressArt.texture(kind, tier)
			var source: Rect2 = ArtScale.source(texture)
			verify(Rect2(Vector2.ZERO, texture.get_size()).encloses(source) and source.size.x > 0 and source.size.y > 0, "Región de arte válida: %s %d" % [kind, tier])
		world.core.restore({"tier": tier, "ordered": false, "progress": 0})
		world.core.health = world.core.health_component.maximum
		for site: ConstructionSite in world.construction.sites:
			site.tier = tier
			site.health_component.maximum = site.data.health * tier
			site.hp = site.max_hp
		world.player.position = Vector2(40, GameRules.FLOOR_Y)
		var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2.ONE
		camera.force_update_scroll()
		world.presenter.publish()
		await picture("nivel_%d" % tier)
	verify(ArtScale.source(GameArt.UNITS, 1).position.x > GameArt.UNITS.get_width() / 4 + 40, "El escudo no incluye píxeles ajenos de la celda vecina")
	save.delete_save()
	world.free()
	await process_frame
	var practice: District = load("res://levels/zones/fortress_playground.tscn").instantiate() as District
	root.add_child(practice)
	await process_frame
	await process_frame
	verify(not practice.session.persistence_enabled and practice.core.tier == 1 and practice.bank.scrap == 800 and practice.cycle.day == 2, "F6 ofrece práctica de niveles con guardado desactivado")
	practice.free()
	await process_frame
	print("Fortificaciones: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
