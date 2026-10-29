extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/unit-art/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	for role: String in UnitSpriteLibrary.ROLES:
		var frames: SpriteFrames = UnitSpriteLibrary.frames(role)
		verify(frames == UnitSpriteLibrary.frames(role), "Recurso compartido: " + role)
		for state: String in ["reposo", "caminar", "dano", "caer", "cansancio", "disparar", "reparar", "cargar", "huir", "levantarse", "proteger"]:
			verify(frames.has_animation(state) and frames.get_frame_count(state) >= 4, "Secuencia completa: %s/%s" % [role, state])
			var fingerprints: Dictionary = {}
			var feet: Dictionary = {}
			for index: int in range(frames.get_frame_count(state)):
				var texture: Texture2D = frames.get_frame_texture(state, index)
				var image: Image = texture.get_image()
				fingerprints[hash(image.get_data())] = true
				feet[hash(image.get_region(Rect2i(0, 44, 64, 12)).get_data())] = true
				verify(image.get_used_rect().end.y <= 56, "Apoyo sin hundirse: %s/%s/%d" % [role, state, index])
			verify(fingerprints.size() >= 3, "Poses diferentes: %s/%s" % [role, state])
			if state == "caminar": verify(feet.size() >= 4, "Piernas cambian de pose: " + role)
		verify(not frames.get_animation_loop(&"caer") and not frames.get_animation_loop(&"dano"), "Caída y daño no se repiten: " + role)
	var person: PersonVisual = PersonVisual.new()
	root.add_child(person)
	person.setup_person("ranger")
	person.update_person(0.1, 5, false, -1)
	verify(person.current == &"caminar" and person.sprite.flip_h, "Marcha y dirección corresponden al desplazamiento")
	person.pulse_action()
	person.update_person(0.01, 0, false, 1)
	verify(person.current == &"disparar", "Disparo reproduce su secuencia")
	person.pulse_hurt()
	person.update_person(0.01, 3, true, 1)
	verify(person.current == &"dano", "Daño tiene prioridad sobre acción y marcha")
	person.hurt_left = 0
	person.action_left = 0
	for index: int in range(150): person.update_person(0.2, 8, false, 1)
	person.update_person(0.1, 0, false, 1)
	verify(person.exhausted and person.current == &"cansancio", "El esfuerzo acumulado se ve al descansar")
	for index: int in range(24): person.update_person(0.5, 0, false, 1)
	verify(not person.exhausted and person.current == &"reposo", "Descansar recupera la respiración normal")
	var fatigue: float = person.fatigue
	person.update_person(0.1, 4000, false, 1)
	verify(person.fatigue <= fatigue, "Un traslado de prueba no acumula cansancio")
	person.update_person(0.1, 0, false, 1, true, true)
	person.sprite.frame = 6
	person.update_person(0.1, 0, false, 1, true, true)
	verify(person.current == &"caer" and person.sprite.frame == 6, "La caída tiene prioridad y no se reinicia")
	person.update_person(1.1, 0, false, 1, false, true)
	verify(person.sprite.modulate.a <= 0.01, "El cuerpo desaparece después de caer")
	person.free()
	GamePreferences.current().briefing_requested = false
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var worker: ColonyWorker = world.colony.workers[0]
	worker.update_visual(worker.x, true)
	verify(worker.visual.sprite.animation == &"reparar", "Constructor articula el trabajo real")
	var home: ExpansionOutpost = world.expansion.sites[0]
	home.hp = home.MAX_HEALTH
	var ally: FieldAlly = home.hire("guardian")
	ally.take_damage(10)
	verify(ally.visual.hurt_left > 0, "El aliado reacciona al golpe real")
	ally.take_damage(10000)
	verify(not ally.is_in_group(GameRules.ALLIES) and home.staff_count() == 0, "Caer retira de inmediato la capacidad de combate")
	world.civic.tick(0)
	verify(world.civic.villagers.size() == 1 and not world.civic.people[0].visible, "La persona desarmada espera a que termine la caída")
	world.civic.tick(1.3)
	verify(world.civic.people[0].visible and world.civic.people[0].current == &"levantarse", "El superviviente se incorpora antes de volver a caminar")
	verify(CivicSystem.valid(world.civic.snapshot(), world.civic.gates.size()), "El estado de recuperación se puede guardar")
	var civic_data: Dictionary = world.civic.snapshot()
	civic_data.villagers[0].recover = "invalid"
	verify(not CivicSystem.valid(civic_data, world.civic.gates.size()), "Recuperación corrupta no entra al guardado")
	for id: String in ["artillero", "saboteador"]:
		var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/%s.tres" % id))
		enemy.set_physics_process(false)
		verify(enemy.visual.field_rig != null and enemy.visual.field_rig.sprite.sprite_frames == UnitSpriteLibrary.frames(id), "El enemigo usa fotogramas completos: " + id)
		enemy.take_damage(10000)
		verify(enemy.death_remaining >= 1.1 and not enemy.is_in_group(GameRules.ENEMIES), "El enemigo termina su caída sin seguir atacando: " + id)
	world.free()
	await process_frame
	var gallery: Control = load("res://levels/story/unit_animation_preview.tscn").instantiate()
	root.add_child(gallery)
	verify(gallery.people.size() == 9, "La galería F6 presenta las nueve profesiones")
	for state: String in ["caminar", "reparar", "caer"]:
		for index: int in range(gallery.states.item_count):
			if gallery.states.get_item_text(index) == state: gallery.states.select(index)
		gallery.play_selected()
		await create_timer(0.25).timeout
		await picture("galeria_" + state)
	gallery.free()
	print("Animación de personas: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
