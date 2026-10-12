class_name RecaudadorArena
extends CanvasLayer

signal resolved(victory: bool)
signal continued

const DAMAGE_EDGES: Script = preload("res://ui/damage_edges.gd")
const THEME: Theme = preload("res://ui/theme.tres")
var completed: bool = false
var ending: bool = false
var ending_victory: bool = false
var ending_timer: float = 0.0
var emitted: bool = false
var player: TopdownPlayer = TopdownPlayer.new()
var boss: Recaudador = Recaudador.new()
var world: Node2D = Node2D.new()
var actors: Node2D = Node2D.new()
var viewport: SubViewport = SubViewport.new()
var banner: Label
var bar: ColorRect = ColorRect.new()
var pause_panel: PanelContainer = PanelContainer.new()
var damage_edges: Control = Control.new()
var hit_count: int = 0
var camera: Camera2D = Camera2D.new()

func configure(source: Player) -> void:
	player.copy_from(source)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	world.add_child(floor_node)
	actors.y_sort_enabled = true
	world.add_child(actors)
	build_geometry()
	player.position = Vector2(320, 370)
	boss.position = Vector2(320, 130)
	boss.target = player
	actors.add_child(player)
	actors.add_child(boss)
	player.slash.connect(strike)
	player.damaged.connect(on_damage)
	player.died.connect(func() -> void: finish(false))
	boss.died.connect(func() -> void: finish(true))
	boss.fired.connect(spawn_bullet)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 480
	player.add_child(camera)
	camera.make_current()
	camera.reset_smoothing()
	build_lighting()
	build_hud()

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
	wall(Vector2(320, 6), Vector2(640, 12))
	wall(Vector2(320, 474), Vector2(640, 12))
	wall(Vector2(6, 240), Vector2(12, 480))
	wall(Vector2(634, 240), Vector2(12, 480))
	var positions: Array[Vector2] = [Vector2(180, 160), Vector2(460, 160), Vector2(180, 320), Vector2(460, 320), Vector2(85, 245), Vector2(555, 245)]
	var assets: Array[String] = ["pillar_top", "pillar_top", "crate_top", "crate_top", "barrel_top", "barrel_top"]
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
	label("EL RECAUDADOR", Rect2(160, 325, 320, 14))
	var backing: ColorRect = ColorRect.new()
	backing.color = Color("0b1322")
	backing.position = Vector2(159, 345)
	backing.size = Vector2(322, 4)
	add_child(backing)
	bar.color = Color("e99b43")
	bar.position = Vector2(160, 346)
	bar.size = Vector2(320, 2)
	add_child(bar)
	banner = label("", Rect2(0, 140, 640, 44), true)
	pause_panel.theme = THEME
	pause_panel.position = Vector2(220, 115)
	pause_panel.size = Vector2(200, 130)
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
	pause_panel.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and not ending and not completed:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif completed and (event.is_action_pressed("restart") or event.is_action_pressed("ui_accept")):
		continued.emit()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	if pause_panel.visible:
		pause_panel.get_child(0).get_child(1).grab_focus()

func strike(origin: Vector2, direction: Vector2, amount: int, reach: float) -> void:
	var offset: Vector2 = boss.global_position - origin
	if ending or offset.length() > reach + 29 or direction.dot(offset.normalized()) < cos(0.85):
		return
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, boss.global_position, 1)
	if world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		boss.receive_hit(origin, amount)

func spawn_bullet(origin: Vector2, direction: Vector2) -> void:
	var bullet: RecaudadorBullet = RecaudadorBullet.new()
	bullet.position = origin
	bullet.velocity = direction * (190 if boss.phase == 2 else 155)
	world.add_child(bullet)

func on_damage() -> void:
	hit_count += 1
	damage_edges.set_state({"health": player.health, "player_hit": hit_count})

func finish(victory: bool) -> void:
	if ending or completed:
		return
	ending = true
	ending_victory = victory
	ending_timer = 2.2 if victory else 1.2
	player.set_physics_process(false)
	boss.set_physics_process(false)
	for child: Node in world.get_children():
		if child is RecaudadorBullet:
			child.queue_free()
	banner.text = "" if victory else "SENAL PERDIDA"

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	bar.size.x = 320 * float(boss.health) / boss.max_health
	bar.color = Color("dd6482") if boss.phase == 2 else Color("e99b43")
	if ending and not emitted:
		ending_timer -= delta
		if ending_victory and ending_timer <= 1.6:
			banner.text = "EL RECAUDADOR - DERROTADO"
		if ending_timer <= 0:
			emitted = true
			resolved.emit(ending_victory)

func show_completed() -> void:
	completed = true
	player.set_physics_process(false)
	boss.set_physics_process(false)
	banner.text = "DISTRITO 1 COMPLETADO"
	var button: Button = Button.new()
	button.theme = THEME
	button.text = "Continuar"
	button.position = Vector2(265, 200)
	button.size = Vector2(110, 28)
	button.pressed.connect(func() -> void: continued.emit())
	add_child(button)
	button.grab_focus()
