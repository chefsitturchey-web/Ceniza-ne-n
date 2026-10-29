extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.hide()
	world.get_node("HUD").hide()
	var studio: Node2D = Node2D.new()
	root.add_child(studio)
	var background: ColorRect = ColorRect.new()
	background.color = Color("0b1322")
	background.size = Vector2(640, 360)
	studio.add_child(background)
	var ground: ColorRect = ColorRect.new()
	ground.color = Color("182639")
	ground.position.y = 266
	ground.size = Vector2(640, 94)
	studio.add_child(ground)
	var camera: Camera2D = Camera2D.new()
	camera.position = Vector2(320, 180)
	studio.add_child(camera)
	camera.make_current()
	var actors: Array[SiegeEnemy] = []
	var ids: Array[String] = ["blindado", "saltador", "ariete"]
	for index: int in range(ids.size()):
		var data: EnemyData = load("res://data/enemies/%s.tres" % ids[index])
		var enemy: SiegeEnemy = world.director.spawn_enemy(1, data)
		enemy.set_physics_process(false)
		enemy.reparent(studio)
		enemy.position = Vector2(115 + index * 205, 266)
		enemy.scale = Vector2(2, 2)
		enemy.face_toward(enemy.position.x + 50)
		actors.append(enemy)
		verify(enemy.visual.rig != null and enemy.visual.rig.kind == ids[index], "Silueta propia: " + ids[index])
		verify(not enemy.sprite.visible and enemy.sprite.sprite_frames != null, "Conserva sprites como alternativa: " + ids[index])
		verify(enemy.visual.rig.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Filtro nítido: " + ids[index])
		var hp: int = enemy.health
		var where: Vector2 = enemy.position
		enemy.update_visual(true)
		enemy.visual.rig._process(0.2)
		verify(enemy.health == hp and enemy.position == where, "La animación no altera reglas ni posición: " + ids[index])
		var label: Label = Label.new()
		label.theme = preload("res://ui/theme.tres")
		label.theme_type_variation = &"Title"
		label.text = ids[index].to_upper()
		label.position = Vector2(index * 205 + 20, 290)
		label.size.x = 190
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		studio.add_child(label)
	var heading: Label = Label.new()
	heading.theme = preload("res://ui/theme.tres")
	heading.theme_type_variation = &"Title"
	heading.text = "MÁQUINAS DE ASEDIO"
	heading.position = Vector2(40, 40)
	heading.add_theme_color_override("font_color", Color("ffce75"))
	studio.add_child(heading)
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/maquinas-siluetas.png")
	for enemy: SiegeEnemy in actors:
		enemy.take_damage(100000)
		enemy.visual.rig._process(0.3)
		verify(enemy.visual.rig.death_time > 0 and not enemy.is_in_group(GameRules.ENEMIES), "Destrucción visual sin prolongar amenaza")
	var original: SiegeEnemy = load("res://entities/enemies/blindado.tscn").instantiate() as SiegeEnemy
	original.detailed_silhouette = false
	original.data = load("res://data/enemies/blindado.tres")
	studio.add_child(original)
	verify(original.visual.rig == null and original.sprite.visible, "El Inspector permite volver al sprite anterior")
	studio.free()
	world.free()
	await process_frame
	print("Siluetas mecánicas: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
