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

func wait_transition() -> void:
	await create_timer(0.42, true).timeout

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/novel/" + name + ".png")

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/novel"))
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	world.story.present_dialogue = false
	var novel: NovelPanel = world.story.novel
	var opening: Dictionary = VisualStory.scene(0, "opening")
	verify(VisualStory.scene(0, "rescue").lines[1].speaker == "vera", "El rescate identifica a Vera y separa su nombre del texto")
	verify(VisualStory.scene(3, "convoy").lines[1].speaker == "prefect", "La discusión de Ciudadela identifica al Prefecto")
	var clock: float = world.cycle.phase_remaining
	verify(novel.play(opening) and paused and novel.opened, "La conversación toma la pausa del mundo")
	verify(novel.transitioning and novel.curtain.color.a == 1, "La entrada comienza con fundido")
	var initial: int = novel.line_index
	novel.advance()
	verify(novel.line_index == initial, "La entrada que abrió la escena no salta el diálogo")
	await wait_transition()
	verify(not novel.transitioning and novel.curtain.color.a < 0.01, "El fundido descubre la escena")
	world.session._process(12)
	verify(world.cycle.phase_remaining == clock, "Leer no consume tiempo de preparación")
	novel.advance()
	verify(novel.body.visible_characters == novel.body.get_total_character_count() and novel.line_index == 0, "Primer avance completa el texto progresivo")
	novel.advance()
	verify(novel.line_index == 1 and novel.speaker.text == "MARA", "Segundo avance cambia de interlocutor")
	verify(novel.left.modulate.r > novel.right.modulate.r, "El personaje que habla recibe el foco visual")
	await create_timer(0.3, true).timeout
	novel.advance()
	await picture("mara")
	novel.previous_line()
	verify(novel.line_index == 0 and novel.speaker.text == "PORTADOR", "Se puede volver a una intervención anterior")
	novel.close_panel()
	await wait_transition()
	verify(not novel.opened and not paused and "0:opening" in world.story.seen_scenes, "Salir restaura la pausa y registra la escena")
	world.story.journal.open_panel()
	world.story.journal.replay_scene()
	await wait_transition()
	verify(novel.opened and world.story.journal.opened and paused, "El diario reproduce una conversación sin perder su pausa")
	novel.close_panel()
	await wait_transition()
	verify(paused and world.story.journal.visible, "Al cerrar la repetición se vuelve al diario")
	Input.action_press("pause")
	world.story.journal.close_panel()
	world.session._process(0)
	Input.action_release("pause")
	verify(not paused, "Esc no reabre la pausa después del diario")
	var balance: int = world.bank.scrap
	for index: int in range(5):
		for section: String in VisualStory.SECTIONS:
			var scene: Dictionary = VisualStory.scene(index, section)
			verify(VisualStory.valid_key(scene.id) and not scene.lines.is_empty(), "Guion disponible: " + scene.id)
			novel.scene_data = scene
			novel.reduced_motion = true
			for line: int in range(scene.lines.size()):
				novel.line_index = line
				novel.show_line()
				await process_frame
				verify(novel.body.get_content_height() <= novel.body.size.y + 1, "Texto cabe completo: %s/%d" % [scene.id, line])
	verify(world.bank.scrap == balance, "Releer no concede recompensas ni cambia recursos")
	var data: Dictionary = world.story.snapshot()
	verify(StoryDirector.valid(data), "Escenas vistas se guardan con la historia")
	data.seen_scenes = ["9:opening"]
	verify(not StoryDirector.valid(data), "Rechaza un capítulo de diálogo inexistente")
	data.seen_scenes = ["0:opening", "0:opening"]
	verify(not StoryDirector.valid(data), "Rechaza identificadores duplicados")
	world.story.present_dialogue = true
	world.story.dialogue_queue.clear()
	world.story.complete(0)
	var xp: int = world.experience.level
	world.story.complete(0)
	verify(world.experience.level == xp and world.story.dialogue_queue.size() == 1, "Completar dos veces no duplica escenas ni experiencia")
	await process_frame
	await process_frame
	await wait_transition()
	verify(novel.opened and novel.scene_data.id == "0:rescue", "El rescate abre su conversación automáticamente")
	novel.close_panel()
	await wait_transition()
	world.story.present_dialogue = false
	world.story.dialogue_queue.clear()
	verify(novel.play(VisualStory.scene(4, "encounter")), "El encuentro final usa el mismo sistema")
	await wait_transition()
	novel.advance()
	novel.advance()
	novel.advance()
	await process_frame
	await picture("madre_cero")
	novel.close_panel()
	await wait_transition()
	load("res://tests/game_fixture.gd").stabilize(world)
	world.story.present_dialogue = true
	world.expedition.restore({"destroyed": [true, true], "train_arrived": true})
	world.cycle.phase = "DÍA"
	var saver: SaveSystem = SaveSystem.new()
	saver.session = world.session
	saver.save_path = "user://novel_handoff_test.json"
	world.session.add_child(saver)
	world.session.save_system = saver
	verify(world.expedition.start(), "La campaña permite viajar con presentación narrativa")
	var arena: RecaudadorArena = world.expedition.arena as RecaudadorArena
	verify(arena.novel.opened and paused and arena.novel.scene_data.id == "0:encounter", "El viaje abre el encuentro y pausa el combate")
	await wait_transition()
	arena.novel.close_panel()
	await wait_transition()
	verify(not paused and world.expedition.active, "Cerrar el encuentro permite combatir")
	world.expedition.resolve(true)
	verify(arena.novel.opened and arena.novel.scene_data.id == "0:ending", "La victoria abre la despedida del distrito")
	verify(SaveSystem.checkpoint_info(saver.save_path).get("zone") == 1, "La victoria guarda la llegada al distrito siguiente")
	await wait_transition()
	arena.novel.close_panel()
	await wait_transition()
	verify(not paused and arena.completed, "Cerrar la despedida permite continuar la campaña")
	verify(SaveSystem.checkpoint_info(saver.save_path).get("zone") == 1, "Cerrar el diálogo conserva el avance guardado")
	saver.delete_save()
	arena.free()
	world.expedition.arena = null
	world.free()
	await process_frame
	var gallery: Control = load("res://levels/story/novel_preview.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	await wait_transition()
	verify(gallery.novel.opened and paused, "La galería F6 presenta una escena sin campaña")
	gallery.novel.close_panel()
	await wait_transition()
	verify(not paused, "Salir de la galería restaura los controles de selección")
	gallery.free()
	print("Novela visual: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
