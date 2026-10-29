class_name RecaudadorArena
extends CanvasLayer

signal resolved(victory: bool)
signal continued
signal menu_requested

const DAMAGE_EDGES: Script = preload("res://ui/damage_edges.gd")
const THEME: Theme = preload("res://ui/theme.tres")
var completed: bool = false
var ending: bool = false
var ending_victory: bool = false
var ending_timer: float = 0.0
var emitted: bool = false
var player: TopdownPlayer = TopdownPlayer.new()
var boss: Recaudador
var world: Node2D = Node2D.new()
var actors: Node2D = Node2D.new()
var viewport: SubViewport = SubViewport.new()
var banner: Label
var bar: ColorRect = ColorRect.new()
var pause_panel: PanelContainer = PanelContainer.new()
var damage_edges: Control = Control.new()
var hit_count: int = 0
var camera: Camera2D = Camera2D.new()
var sound: GameSound = GameSound.new()
var configured: bool = false
var present_story: bool = false
var novel: NovelPanel
var modules: ModuleSystem = ModuleSystem.new()
var options: SettingsPanel = SettingsPanel.new()
var exit_button: Button
var result_shade: ColorRect
@export_range(0, 4) var zone_index: int = 0
var support_units: int = 0
var zone: ZoneData
var boss_status: Label
var phase_notice: Label
var phase_notice_time: float = 0.0

func configure(source: Player, index: int = 0) -> void:
	configured = true
	zone_index = index
	player.copy_from(source)
	var colony: District = source.get_parent() as District
	if colony != null and colony.story != null: support_units = colony.story.soldiers()
	if colony != null and colony.story != null: present_story = colony.story.present_dialogue

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	zone = CampaignRoute.zone(zone_index)
	# Creación directa: no hay componentes de un jefe anterior que queden huérfanos.
	var scripts: Array[String] = ["recaudador", "santa_caldera", "coro_sumergido", "el_prefecto", "madre_cero"]
	boss = load("res://entities/enemies/" + scripts[zone_index] + ".gd").new() as Recaudador
	configure_controls()
	var screen: SubViewportContainer = SubViewportContainer.new()
	screen.size = Vector2(640, 360)
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	viewport.size = Vector2i(640, 360)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen.add_child(viewport)
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(world)
	var floor_node: Node2D = Node2D.new()
	floor_node.set_script(preload("res://levels/expedition/arena_floor.gd"))
	floor_node.set("theme_id", zone.id)
	world.add_child(floor_node)
	var telegraphs: EncounterTelegraphs = EncounterTelegraphs.new()
	telegraphs.boss = boss
	world.add_child(telegraphs)
	actors.y_sort_enabled = true
	world.add_child(actors)
	build_geometry()
	player.position = Vector2(320, 370)
	boss.position = Vector2(320, 130)
	boss.target = player
	actors.add_child(player)
	actors.add_child(boss)
	if boss is CoroSumergido:
		(boss as CoroSumergido).install_relays(actors)
	if boss is MadreCero:
		(boss as MadreCero).support_units = support_units
		(boss as MadreCero).install_relays(actors)
	modules.actor = player
	modules.boss = boss
	modules.planar = true
	modules.restore(player.module_state)
	world.add_child(modules)
	player.slash.connect(strike)
	player.damaged.connect(on_damage)
	player.died.connect(func() -> void: finish(false))
	boss.died.connect(func() -> void: finish(true))
	boss.fired.connect(spawn_bullet)
	boss.phase_changed.connect(func(_phase: int) -> void:
		phase_notice_time = 1.8
		phase_notice.text = "SEGUNDA FASE")
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 480
	if zone_index == 0:
		player.add_child(camera)
	else:
		# Las franjas y enlaces necesitan verse completos antes de elegir una ruta segura.
		camera.position_smoothing_enabled = false
		camera.zoom = Vector2(0.75, 0.75)
		camera.limit_left = -107
		camera.limit_right = 747
		camera.position = Vector2(320, 240)
		world.add_child(camera)
	camera.make_current()
	camera.reset_smoothing()
	build_lighting()
	build_hud()
	add_child(options)
	options.closed.connect(func() -> void:
		if pause_panel.visible:
			pause_panel.get_child(0).get_child(1).grab_focus())
	add_child(sound)
	modules.fired.connect(func() -> void: sound.play_cue("shot", -5))
	player.dodged.connect(func() -> void: sound.play_cue("dodge"))
	player.stepped.connect(func(_origin: Vector2) -> void: sound.play_cue("step", -18))
	boss.cue_requested.connect(func(id: String) -> void: sound.play_cue(id, -4))
	player.slash.connect(func(_o: Vector2, _d: Vector2, _a: int, _r: float) -> void: sound.play_cue("slash"))
	novel = NovelPanel.new()
	add_child(novel)
	if present_story: novel.play(VisualStory.scene(zone_index, "encounter"))

func configure_controls() -> void:
	if not InputMap.has_action("attack"):
		InputSetup.configure_input()
	for entry: Array in [["arena_up", KEY_W, KEY_UP, JOY_BUTTON_DPAD_UP, -1.0], ["arena_down", KEY_S, KEY_DOWN, JOY_BUTTON_DPAD_DOWN, 1.0]]:
		if InputMap.has_action(entry[0]):
			continue
		InputSetup.add_action(entry[0], entry[1], entry[3])
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = entry[2]
		InputMap.action_add_event(entry[0], key)
		var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_Y
		axis.axis_value = entry[4]
		InputMap.action_add_event(entry[0], axis)

func wall(center: Vector2, extent: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = extent
	collider.shape = shape
	body.add_child(collider)
	world.add_child(body)
	return body

func build_geometry() -> void:
	if zone_index in [1, 3, 4]:
		var boundary: Array[Vector2] = [Vector2(140, 24), Vector2(500, 24), Vector2(616, 140), Vector2(616, 340), Vector2(500, 456), Vector2(140, 456), Vector2(24, 340), Vector2(24, 140)]
		if zone_index == 3:
			boundary = [Vector2(96, 24), Vector2(544, 24), Vector2(616, 100), Vector2(616, 380), Vector2(544, 456), Vector2(96, 456), Vector2(24, 380), Vector2(24, 100)]
		elif zone_index == 4:
			boundary.clear()
			for index: int in range(12): boundary.append(Vector2(320, 240) + Vector2(cos(index * TAU / 12) * 285, sin(index * TAU / 12) * 215))
		for index: int in range(boundary.size()):
			var a: Vector2 = boundary[index]
			var b: Vector2 = boundary[(index + 1) % boundary.size()]
			var edge: StaticBody2D = wall((a + b) * 0.5, Vector2(a.distance_to(b), 14))
			edge.rotation = (b - a).angle()
	else:
		wall(Vector2(320, 6), Vector2(640, 12))
		wall(Vector2(320, 474), Vector2(640, 12))
		wall(Vector2(6, 240), Vector2(12, 480))
		wall(Vector2(634, 240), Vector2(12, 480))
	var positions: Array[Vector2] = [Vector2(180, 160), Vector2(460, 160), Vector2(180, 320), Vector2(460, 320), Vector2(85, 245), Vector2(555, 245)]
	var assets: Array[String] = ["pillar_top", "pillar_top", "crate_top", "crate_top", "barrel_top", "barrel_top"]
	if zone_index == 1:
		positions = [Vector2(90, 140), Vector2(550, 140), Vector2(90, 360), Vector2(550, 360)]
		assets = ["pillar_top", "pillar_top", "crate_top", "crate_top"]
	elif zone_index == 2:
		positions = [Vector2(90, 240), Vector2(550, 240), Vector2(320, 65)]
		assets = ["pillar_top", "pillar_top", "crate_top"]
	elif zone_index >= 3:
		positions = [Vector2(90, 240), Vector2(550, 240), Vector2(320, 65), Vector2(145, 360), Vector2(495, 360)]
		assets = ["pillar_top", "pillar_top", "crate_top", "barrel_top", "barrel_top"]
	for index: int in range(positions.size()):
		var texture: Texture2D = load("res://assets/expedition/arena/%s.png" % assets[index]) as Texture2D
		var body: StaticBody2D = wall(positions[index], texture.get_size())
		body.reparent(actors)
		body.name = "Cover%d" % index
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = texture
		body.add_child(sprite)

func build_lighting() -> void:
	var ambient: CanvasModulate = CanvasModulate.new()
	ambient.color = Color("b2bacb")
	world.add_child(ambient)
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 0.75, 0.4, 0.7), Color(1, 0.6, 0.2, 0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	for x: int in [48, 592]:
		for y: int in [80, 400]:
			var light: PointLight2D = PointLight2D.new()
			light.texture = texture
			light.position = Vector2(x, y)
			light.energy = 1.1
			light.texture_scale = 1.3
			light.add_to_group(&"arena_light")
			world.add_child(light)
	# Luz roja de alarma tenue sobre la zona del jefe; arena_floor.gd la hace respirar.
	var alarm: PointLight2D = PointLight2D.new()
	alarm.texture = texture
	alarm.color = Color("dd6482")
	alarm.position = Vector2(320, 230)
	alarm.energy = 0.35
	alarm.texture_scale = 2.2
	alarm.add_to_group(&"arena_alarm")
	world.add_child(alarm)

func label(text: String, rect: Rect2, title: bool = false) -> Label:
	var node: Label = Label.new()
	node.theme = THEME
	node.theme_type_variation = &"Title" if title else &"SmallTitle"
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(node)
	return node

func build_hud() -> void:
	damage_edges.set_script(DAMAGE_EDGES)
	damage_edges.size = Vector2(640, 360)
	damage_edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_edges)
	damage_edges.set_state({"health": player.health})
	label(zone.boss_title, Rect2(110, 325, 420, 14))
	boss_status = label(zone.briefing, Rect2(8, 15, 624, 28))
	boss_status.add_theme_font_size_override("font_size", 10)
	boss_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_notice = label("", Rect2(80, 60, 480, 22), true)
	phase_notice.add_theme_color_override("font_color", Color("dd6482"))
	var backing: ColorRect = ColorRect.new()
	backing.color = Color("0b1322")
	backing.position = Vector2(159, 345)
	backing.size = Vector2(322, 4)
	add_child(backing)
	bar.color = Color("e99b43")
	bar.position = Vector2(160, 346)
	bar.size = Vector2(320, 2)
	add_child(bar)
	result_shade = ColorRect.new()
	result_shade.color = Color("0b1322", 0.8)
	result_shade.size = Vector2(640, 360)
	result_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_shade)
	result_shade.hide()
	banner = label("", Rect2(0, 140, 640, 44), true)
	pause_panel.theme = THEME
	pause_panel.position = Vector2(210, 90)
	pause_panel.size = Vector2(220, 180)
	add_child(pause_panel)
	var rows: VBoxContainer = VBoxContainer.new()
	pause_panel.add_child(rows)
	var title: Label = Label.new()
	title.text = "PAUSA"
	title.theme_type_variation = &"Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)
	var resume: Button = Button.new()
	resume.text = "Continuar"
	resume.pressed.connect(toggle_pause)
	rows.add_child(resume)
	var settings: Button = Button.new()
	settings.text = "Opciones"
	settings.pressed.connect(options.open_panel)
	rows.add_child(settings)
	exit_button = Button.new()
	exit_button.text = "Menú principal"
	exit_button.pressed.connect(return_to_menu)
	rows.add_child(exit_button)
	pause_panel.hide()

func _input(event: InputEvent) -> void:
	if options.opened or options.closed_frame == Engine.get_process_frames():
		return
	if event.is_action_pressed("pause") and not event.is_echo() and not ending and not completed:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif completed and event.is_action_pressed("restart"):
		if not configured:
			if ending_victory:
				return_to_menu()
			else:
				retry_arena()
		else:
			continued.emit()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if not get_tree().paused:
		GamePreferences.current().block_gameplay_input()
	pause_panel.visible = get_tree().paused
	if pause_panel.visible:
		pause_panel.get_child(0).get_child(1).grab_focus()

func return_to_menu() -> void:
	get_tree().paused = false
	if configured:
		menu_requested.emit()
	else:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func strike(origin: Vector2, direction: Vector2, amount: int, reach: float) -> void:
	if ending:
		return
	if boss.strike_attachments(origin, direction, amount, reach):
		return
	var offset: Vector2 = boss.global_position - origin
	if ending or offset.length() > reach + 29 or direction.dot(offset.normalized()) < cos(0.85):
		return
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, boss.global_position, 1)
	if world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		boss.receive_hit(origin, amount)

func spawn_bullet(origin: Vector2, direction: Vector2) -> void:
	sound.play_cue("shot", -6)
	var bullet: RecaudadorBullet = RecaudadorBullet.new()
	bullet.position = origin
	bullet.velocity = direction * (190 if boss.phase == 2 else 155)
	world.add_child(bullet)

func on_damage() -> void:
	sound.play_cue("hit")
	hit_count += 1
	damage_edges.set_state({"health": player.health, "player_hit": hit_count})

func finish(victory: bool) -> void:
	if ending or completed:
		return
	ending = true
	boss.clear_hazards()
	sound.play_cue("destroy" if victory else "alarm")
	ending_victory = victory
	ending_timer = 2.2 if victory else 1.2
	player.set_physics_process(false)
	boss.set_physics_process(false)
	modules.set_physics_process(false)
	for child: Node in world.get_children():
		if child is RecaudadorBullet:
			child.queue_free()
	banner.text = "" if victory else "SENAL PERDIDA"

func _process(delta: float) -> void:
	if novel != null and (novel.opened or novel.closed_frame == Engine.get_process_frames()): return
	if get_tree().paused:
		return
	bar.size.x = 320 * float(boss.health) / boss.max_health
	boss_status.text = boss.status_text() if not ending else ""
	phase_notice_time = maxf(0, phase_notice_time - delta)
	phase_notice.visible = phase_notice_time > 0 and not ending
	bar.color = Color("dd6482") if boss.phase == 2 else Color("e99b43")
	if ending and not emitted:
		ending_timer -= delta
		if ending_victory and ending_timer <= 1.6:
			banner.text = zone.boss_title + " - DERROTADO"
		if ending_timer <= 0:
			emitted = true
			resolved.emit(ending_victory)
			if not configured:
				if ending_victory:
					show_completed()
				else:
					show_standalone_defeat()

func retry_arena() -> void:
	get_tree().paused = false
	var scenes: Array[String] = ["res://levels/expedition/recaudador_arena.tscn", "res://levels/expedition/caldera_arena.tscn", "res://levels/expedition/choir_arena.tscn", "res://levels/expedition/prefect_arena.tscn", "res://levels/expedition/mother_arena.tscn"]
	get_tree().change_scene_to_file(scenes[zone_index])

func show_standalone_defeat() -> void:
	if completed:
		return
	completed = true
	result_shade.show()
	var retry: Button = Button.new()
	retry.theme = THEME
	retry.text = "Reintentar  [R]"
	retry.position = Vector2(245, 200)
	retry.size = Vector2(150, 25)
	retry.pressed.connect(retry_arena)
	add_child(retry)
	var menu: Button = Button.new()
	menu.theme = THEME
	menu.text = "Menú principal"
	menu.position = Vector2(245, 235)
	menu.size = Vector2(150, 25)
	menu.pressed.connect(return_to_menu)
	add_child(menu)
	retry.grab_focus()

func show_completed(next_zone: String = "") -> void:
	if completed:
		return
	completed = true
	result_shade.show()
	player.set_physics_process(false)
	boss.set_physics_process(false)
	modules.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.dodge_remaining = 0
	player.attack_anim_remaining = 0
	player.slash_remaining = 0
	player.update_visual()
	banner.text = "DISTRITO %d COMPLETADO" % (zone_index + 1)
	var ending_text: RichTextLabel = RichTextLabel.new()
	ending_text.theme = THEME
	ending_text.position = Vector2(40, 45)
	ending_text.size = Vector2(560, 85)
	ending_text.add_theme_font_size_override("normal_font_size", 12)
	ending_text.text = CampaignStory.chapter(zone_index).ending
	add_child(ending_text)
	label("Ruta disponible completada." if next_zone.is_empty() else "Siguiente destino: " + next_zone + ". Equipo y tripulación conservados.", Rect2(40, 178, 560, 16))
	var button: Button = Button.new()
	button.theme = THEME
	button.text = "Volver al menú" if next_zone.is_empty() else "Viajar a " + next_zone
	button.position = Vector2(210, 200)
	button.size = Vector2(220, 28)
	button.pressed.connect(func() -> void:
		if configured:
			continued.emit()
		else:
			return_to_menu())
	add_child(button)
	button.grab_focus()
	if not next_zone.is_empty():
		var menu: Button = Button.new()
		menu.theme = THEME
		menu.text = "Volver al menú"
		menu.position = Vector2(245, 238)
		menu.size = Vector2(150, 25)
		menu.pressed.connect(return_to_menu)
		add_child(menu)
	if present_story: novel.play(VisualStory.scene(zone_index, "ending"))
