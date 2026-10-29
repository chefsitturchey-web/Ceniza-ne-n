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
	verify(layout.actors.size() == 6 and layout.animations.size() == 40, "Seis actores y cuarenta secuencias por actor")
	for id: String in layout.actors:
		verify(FileAccess.file_exists("res://assets/combat/native/sources/%s.ase" % id), "Fuente editable de LibreSprite: " + id)
		var frames: SpriteFrames = CombatSpriteLibrary.frames(id)
		verify(frames == CombatSpriteLibrary.frames(id), "Caché compartida: " + id)
		var sheet: Image = load("res://assets/combat/native/%s.png" % id).get_image()
		var size: int = layout.actors[id].cell
		for key: String in layout.animations:
			var hashes: Dictionary = {}
			for index: int in layout.animations[key].frames:
				var image: Image = sheet.get_region(Rect2i(index % 8 * size, index / 8 * size, size, size))
				hashes[hash(image.get_data())] = true
				var used: Rect2i = image.get_used_rect()
				verify(used.has_area() and used.position.x > 0 and used.position.y > 0 and used.end.x < size and used.end.y < size, "Sin recortes ni celdas vacías: %s/%s/%d" % [id, key, index])
			verify(hashes.size() >= 3, "Tres o más poses distintas: %s/%s" % [id, key])
		verify(not frames.get_animation_loop(&"death_south") and not frames.get_animation_loop(&"attack_south"), "Muerte y ataque no se repiten: " + id)
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/combat/native/provenance.json"))
	verify(provenance.external_raster_inputs.is_empty() and provenance.tool == "LibreSprite", "Este bloque dibuja los píxeles en LibreSprite sin ilustraciones generadas de entrada")
	var studio: Control = load("res://levels/story/combat_animation_preview.tscn").instantiate()
	root.add_child(studio)
	await process_frame
	verify(studio.actors.size() == 6, "Galería F6 presenta los seis personajes")
	await picture("galeria_caminar")
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
	world.free()
	await process_frame
	print("Arte de combate LibreSprite: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
