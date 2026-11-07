extends SceneTree
## Colores, remapeos y conservacion de medidas en los avisos.
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var prefs: GamePreferences = GamePreferences.current()
	prefs.values.glyphs = 1
	prefs.bindings.clear()
	var label: Label = Label.new()
	label.theme = preload("res://ui/theme.tres")
	label.size = Vector2(400, 64)
	label.text = "MARA: mantén E; recupera piezas. Peligro: fuego."
	root.add_child(label)
	var before: Vector2 = label.get_combined_minimum_size()
	var layer: TextMarks = TextMarks.attach(label)
	layer.refresh()
	verify(layer.get_parsed_text() == label.text, "El resaltado conserva texto plano y signos")
	verify(label.get_combined_minimum_size() == before, "El resaltado conserva las medidas del HUD")
	verify(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "La capa no intercepta controles")
	verify(layer.text.contains("[color=#c6a0e8]MARA:"), "Hablante con color propio")
	verify(layer.text.contains("[color=#ffce75]E[/color]"), "Tecla dorada")
	verify(layer.text.contains("[color=#47dacb]piezas[/color]"), "Recurso turquesa")
	verify(layer.text.contains("[color=#dd6482]fuego[/color]"), "Peligro rosa")
	var chip: TextMarks = TextMarks.attach(Label.new(), "Mantén {interact}: núcleo")
	root.add_child(chip.source)
	verify(chip.get_parsed_text() == "Mantén E: núcleo", "Plantilla de accion legible")
	prefs.bindings.interact = {"key": KEY_H, "pad": JOY_BUTTON_X}
	chip.refresh()
	verify(chip.get_parsed_text().contains("H:"), "Plantilla respeta remapeo de teclado")
	prefs.values.glyphs = 2
	chip.refresh()
	verify(chip.get_parsed_text().contains("□:"), "Plantilla respeta mando fijo y remapeo")
	verify(BossHints.control("interact") == "[□]", "Pista de jefe usa InputGlyphs")
	prefs.values.glyphs = 1
	verify(BossHints.control("interact") == "[H]", "Pista de jefe respeta teclado fijo")
	label.text = "[color=red]Literal[/color]"
	layer.refresh()
	verify(layer.get_parsed_text() == label.text, "Contenido no puede insertar BBCode")
	label.text = "Las piezasmayores y el fogueo siguen igual."
	layer.refresh()
	verify(not "[color=" in layer.text, "Solo palabras completas")
	verify(InputGlyphs.fill("[{mute}]") == "[M]", "Silencio fijo centralizado")
	var world: District = load("res://levels/main.tscn").instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	await process_frame
	world.story.present_dialogue = false
	world.session.set_process(false)
	verify(world.guide_hud.caption_label.has_node("TextMarks"), "Guia usa marcas sin cambiar pasos")
	verify(world.get_node("HUD").context_label.has_node("TextMarks"), "Avisos del mundo usan marcas")
	world.free()
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.novel.close_panel()
	arena.set_process(false)
	arena.set_physics_process(false)
	verify(arena.boss_status.get_theme_font("font") == TextMarks.FONT, "Estado de jefe usa fuente pixel")
	verify(arena.hints.label.get_theme_font("font") == TextMarks.FONT, "Pista de jefe usa fuente pixel")
	arena.player.set_physics_process(false)
	arena.boss.set_physics_process(false)
	arena.dynamics.set_physics_process(false)
	arena.player.position = arena.dynamics.device_positions[0]
	arena.dynamics._physics_process(0)
	verify(arena.dynamics.device_hint.text.begins_with("[H]"), "Mecanismo de arena respeta remapeo")
	prefs.values.glyphs = 2
	arena.dynamics._physics_process(0)
	verify(arena.dynamics.device_hint.text.begins_with("[□]"), "Mecanismo de arena respeta mando")
	prefs.values.glyphs = 1
	for zone: int in 5:
		arena.zone_index = zone
		for id: String in ["controles", "mecanica", "melee", "lunge", "expuesto", "bloqueo", "marcas", "fase"]:
			arena.hints.label.text = arena.hints.text_for(id)
			arena.hints.fit_label()
			var marks: TextMarks = arena.hints.label.get_node("TextMarks")
			marks.refresh()
			await process_frame
			verify(marks.get_content_height() <= marks.size.y, "Pista pixel cabe: %d %s" % [zone, id])
	arena.free()
	var mother: MadreCero = MadreCero.new()
	root.add_child(mother)
	verify(mother.status_text().contains("H ("), "Estado de Madre Cero respeta remapeo")
	for i: int in 2:
		var relay: NetworkRelay = NetworkRelay.new()
		mother.add_child(relay)
		mother.relays.append(relay)
	prefs.values.glyphs = 2
	verify(mother.status_text().contains("□ reparar"), "Estado de Madre Cero respeta mando")
	mother.free()
	label.free()
	chip.source.free()
	prefs.bindings.clear()
	print("PASS: text_marks; %d comprobaciones; %d fallos" % [checks, failures])
	await process_frame
	quit(1 if failures else 0)
