extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/combat-art/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/combat-art"))
	var layout: Dictionary = CombatSpriteLibrary.data()
	verify(layout.actors.size() == 7 and layout.animations.size() == 40, "Siete variantes y cuarenta secuencias por variante")
	for id: String in layout.actors:
		verify(FileAccess.file_exists(CombatSpriteLibrary.source_path(id)), "Fuente editable de LibreSprite: " + id)
		var frames: SpriteFrames = CombatSpriteLibrary.frames(id)
		verify(frames == CombatSpriteLibrary.frames(id), "Caché compartida: " + id)
		var sheet: Image = load(CombatSpriteLibrary.sheet_path(id)).get_image()
		var size: int = layout.actors[id].cell
		for key: String in layout.animations:
			var hashes: Dictionary = {}
			for index: int in layout.animations[key].frames:
				var image: Image = sheet.get_region(Rect2i(index % 8 * size, index / 8 * size, size, size))
				hashes[hash(image.get_data())] = true
				var used: Rect2i = image.get_used_rect()
				verify(used.has_area() and used.position.x > 0 and used.position.y > 0 and used.end.x < size and used.end.y < size, "Sin recortes ni celdas vacías: %s/%s/%d" % [id, key, index])
			verify(hashes.size() >= int(layout.animations[key].get("min_unique_frames", 3)), "Fotogramas distintos según las poses reales: %s/%s" % [id, key])
		verify(not frames.get_animation_loop(&"death_south") and not frames.get_animation_loop(&"attack_south"), "Muerte y ataque no se repiten: " + id)
		if id in ["portador", "portador_cenital", "prefecto"]:
			var info: Dictionary = layout.actors[id]
			var height: float = info.idle_body_bounds[3] - info.idle_body_bounds[1]
			for direction: String in ["south", "east", "north", "west"]:
				var leg_masks: Dictionary = {}
				for index: int in layout.animations["walk_" + direction].frames:
					var image: Image = sheet.get_region(Rect2i(index % 8 * size, index / 8 * size, size, size))
					var mask: PackedByteArray = PackedByteArray()
					for y: int in range(int(info.anchor[1] - height * 0.30), int(info.anchor[1])):
						for x: int in size: mask.append(1 if image.get_pixel(x, y).a > 0.5 else 0)
					leg_masks[hash(mask)] = true
				verify(leg_masks.size() >= 3, "La silueta de piernas cambia durante el paso: %s/%s" % [id, direction])
				var first_hit: int = layout.animations["attack_" + direction].frames[0]
				var strike: Image = sheet.get_region(Rect2i(first_hit % 8 * size, first_hit / 8 * size, size, size))
				var centre: Vector2 = Vector2.ZERO
				var minimum: Vector2 = Vector2.ONE * size
				var maximum: Vector2 = Vector2.ZERO
				var count: int = 0
				for y: int in size:
					for x: int in size:
						var c: Color = strike.get_pixel(x, y)
						var edge: bool = c.r > 0.6 and c.g < 0.38 and c.b < 0.4 if id == "prefecto" else c.g > 0.4 and c.b > 0.4 and c.r < c.g * 0.8
						if c.a > 0.5 and edge:
							centre += Vector2(x, y)
							minimum = minimum.min(Vector2(x, y))
							maximum = maximum.max(Vector2(x, y))
							count += 1
				centre /= maxf(1, count)
				# A front thrust is foreshortened; its blade need not pass the boots.
				var aligned: bool = centre.x > info.anchor[0] + 8 if direction == "east" else centre.x < info.anchor[0] - 8 if direction == "west" else centre.y < info.anchor[1] - height * 0.60 if direction == "north" else centre.y > info.anchor[1] - height * 0.50
				var length: float = (maximum - minimum).x if direction in ["east", "west"] else (maximum - minimum).y
				# This measures the coloured edge; shaded steel can be longer.
				verify(count > 2 and aligned and length >= height * 0.10, "El filo pintado del impacto apunta hacia su dirección: %s/%s" % [id, direction])
			verify(frames.get_frame_duration(&"windup_south", 5) > frames.get_frame_duration(&"windup_south", 0), "La preparación tiene pausas de peso distintas: " + id)
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/combat/provenance.json"))
	for id: String in layout.actors:
		verify(layout.actors[id].camera == ("lateral" if id == "portador" else "three_quarter"), "Proyección declarada para la cámara: " + id)
		if layout.actors[id].has("key_poses"):
			verify(layout.actors[id].key_poses >= 48 and layout.actors[id].directions.size() == 4, "Poses pintadas en cuatro vistas: " + id)
		else:
			verify(layout.actors[id].orientation_landmarks.size() == 4, "Cuatro vistas del recurso anterior: " + id)
		if id.begins_with("portador"):
			var sheet: Image = load(CombatSpriteLibrary.sheet_path(id)).get_image()
			var cell: int = layout.actors[id].cell
			var skin: Dictionary = {}
			for direction: String in ["south", "east", "north", "west"]:
				var index: int = layout.animations["idle_" + direction].frames[0]
				var image: Image = sheet.get_region(Rect2i(index % 8 * cell, index / 8 * cell, cell, cell))
				var bounds: Rect2i = image.get_used_rect()
				verify(bounds.size.y * CombatSpriteLibrary.scale_for(id) >= 30 and bounds.size.y * CombatSpriteLibrary.scale_for(id) <= 37, "Cuerpo erguido de tamaño coherente: %s/%s" % [id, direction])
				var count: int = 0
				for y: int in range(bounds.position.y, bounds.position.y + int(bounds.size.y * 0.25)):
					for x: int in range(bounds.position.x, bounds.end.x):
						var c: Color = image.get_pixel(x, y)
						if c.a > 0.5 and c.r > c.g * 1.12 and c.g > c.b * 1.08 and c.r > 0.25 and c.r - c.b > 0.08: count += 1
				skin[direction] = count
			verify(skin.south > skin.north + 3, "Rostro humano visible de frente y nuca al mirar al norte: " + id)
	var body: Array = layout.actors.portador.idle_body_bounds
	var height: float = (body[3] - body[1]) * CombatSpriteLibrary.scale_for("portador")
	var ally: Image = UnitSpriteLibrary.frames("guardian").get_frame_texture(&"reposo", 0).get_image()
	verify(height >= 32 and height <= 36 and height <= ally.get_used_rect().size.y * 1.2, "El cuerpo del Portador respeta la escala de los aliados")
	verify(body[3] == layout.actors.portador.anchor[1], "Las botas apoyan en el suelo sin hundirse")
	verify(not provenance.external_raster_inputs.is_empty() and provenance.tool == "LibreSprite", "Poses pintadas registradas y exportadas en LibreSprite con procedencia explícita")
	var studio: Control = load("res://levels/story/combat_animation_preview.tscn").instantiate()
	root.add_child(studio)
	await process_frame
	verify(studio.actors.size() == 6, "Galería F6 presenta los seis personajes")
	for index: int in studio.actors.size():
		var sprite: AnimatedSprite2D = studio.actors[index]
		var image: Image = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_image()
		var used: Rect2i = image.get_used_rect()
		var top: float = sprite.position.y + (used.position.y - image.get_height() / 2.0) * sprite.scale.y
		var bottom: float = top + used.size.y * sprite.scale.y
		var card_top: float = 47 + (index / 3) * 153
		verify(top >= card_top and bottom < card_top + 127, "Silueta dentro de su tarjeta sin tapar el texto: %d" % index)
	await picture("galeria_caminar")
	studio.show_detail(0)
	verify(studio.focus_sprite.visible and studio.focus_sprite.sprite_frames == studio.actors[0].sprite_frames, "Detalle amplía las poses reales sin sustituirlas")
	await picture("detalle_portador")
	studio.show_detail(4)
	await picture("detalle_prefecto")
	studio.show_detail(-1)
	verify(not studio.focus_sprite.visible and studio.focus_index == -1, "Volver a conjunto restaura las escalas del mundo")
	for direction: int in range(1, 4):
		studio.direction_choice.select(direction)
		studio.play_all()
		await picture("galeria_" + studio.DIRECTIONS[direction])
	studio.direction_choice.select(0)
	studio.play_all()
	studio.turn_preview.button_pressed = true
	studio._process(0.95)
	verify(studio.direction_choice.selected == 1, "Giro de prueba avanza una vista sin tumbar el sprite")
	studio.turn_preview.button_pressed = false
	studio.direction_choice.select(0)
	studio.play_all()
	studio.change_camera(1)
	verify(studio.guardian.visible and studio.actors[0].sprite_frames == CombatSpriteLibrary.frames("portador"), "Comparación lateral con aliado real")
	verify(studio.actors[0].scale.x == CombatSpriteLibrary.scale_for("portador") and studio.guardian.scale == Vector2.ONE, "Comparación con tamaños de mundo correctos")
	await picture("escala_portador_aliado")
	studio.change_camera(0)
	studio.state_choice.select(3)
	studio.play_all()
	await create_timer(0.12).timeout
	await picture("galeria_ataque")
	studio.free()
	await process_frame
	for index: int in range(5):
		var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.zone_index = index
		root.add_child(arena)
		arena.set_process(false)
		arena.boss.set_physics_process(false)
		arena.player.set_physics_process(false)
		arena.modules.set_physics_process(false)
		arena.dynamics.set_physics_process(false)
		await physics_frame
		var visual: CombatFlipbook = arena.boss.combat_visual
		verify(visual != null and not arena.boss.puppet.visible, "Jefe utiliza fotogramas completos, no la ilustración antigua: %d" % index)
		arena.boss.change_state(Recaudador.State.CLAW_WINDUP, 1)
		visual.pose_boss(arena.boss)
		var initial: int = visual.sprite.frame
		arena.boss.timer = 0.3
		visual.pose_boss(arena.boss)
		if index not in [2, 4]: verify(visual.sprite.frame > initial and visual.state_name == "windup", "Preparación sigue el aviso real: %d" % index)
		var player: TopdownPlayer = arena.player
		verify(player.combat_visual.actor_id == "portador_cenital", "La arena utiliza el Portador cenital: %d" % index)
		player.facing = Vector2.UP
		player.velocity = Vector2.UP * 100
		player.update_visual()
		var frame: int = player.combat_visual.sprite.frame
		player.position.y -= 12
		player.update_visual()
		verify(player.combat_visual.sprite.frame != frame, "Paso cambia al recorrer distancia: %d" % index)
		frame = player.combat_visual.sprite.frame
		player.update_visual()
		verify(player.combat_visual.sprite.frame == frame, "Un redibujado sin movimiento no inventa pasos: %d" % index)
		var hits: Array[int] = []
		player.slash.connect(func(_o: Vector2, _d: Vector2, amount: int, _r: float) -> void: hits.append(amount))
		player.velocity = Vector2.ZERO
		player.facing = Vector2.RIGHT
		player.cooldown = 0
		player.attack()
		player.update_visual()
		verify(hits.is_empty() and player.combat_visual.state_name == "windup", "La espada anticipa antes de causar daño: %d" % index)
		player._physics_process(0.05)
		verify(hits.is_empty(), "El daño no se adelanta a la preparación: %d" % index)
		player.facing = Vector2.UP
		player._physics_process(0.04)
		verify(hits.size() == 1 and player.combat_visual.current == &"attack_east", "El golpe conserva su dirección anunciada y emite una vez: %d" % index)
		player._physics_process(0.08)
		verify(hits.size() == 1, "No repite daño durante el barrido: %d" % index)
		player.cooldown = 0
		player.attack()
		player.dodge()
		player._physics_process(0.1)
		verify(hits.size() == 1 and not player.attack_pending, "Esquivar cancela un golpe en preparación: %d" % index)
		player.dodge_remaining = 0
		player.invulnerable = 0
		player.take_damage(1)
		player.combat_visual.pose_player()
		verify(player.combat_visual.state_name == "hurt", "Daño tiene pose corporal propia: %d" % index)
		if index == 3:
			arena.boss.position = Vector2(320, 225)
			arena.boss.facing = Vector2.DOWN
			arena.boss.change_state(Recaudador.State.CLAW, 0.16)
			visual.pose_boss(arena.boss)
			await picture("prefecto_combate")
		arena.boss.health = 0
		arena.boss.state = Recaudador.State.DEAD
		visual._process(0.01)
		visual._process(0.4)
		verify(visual.state_name == "death" and visual.sprite.frame > 0, "Muerte cambia de pose sin girar la imagen entera: %d" % index)
		arena.free()
		await process_frame
	var world: District = load("res://levels/main.tscn").instantiate()
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	verify(world.player.combat_visual != null and not world.player.visual.sprite.visible, "La colonia también utiliza el Portador de LibreSprite")
	verify(world.player.combat_visual.actor_id == "portador", "La colonia conserva su perspectiva lateral")
	# Separate the player from the initial crowd for an unambiguous art capture.
	if capture:
		world.player.position.x = -180
		world.player.set_physics_process(false)
		world.player.combat_visual.set_pose("idle", Vector2.RIGHT)
	await picture("portador_colonia")
	world.free()
	await process_frame
	print("Arte de combate LibreSprite: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
