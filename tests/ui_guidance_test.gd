extends SceneTree
## Avisos vivos, alturas reales y consejos compatibles con perfiles antiguos.
var failures: int = 0
var checks: int = 0
var world: District
var capture: bool = false
const CAPTURES: String = "res://build/capturas/ui_guia/"

func _initialize() -> void:
	call_deferred("run_checks")

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	verify(root.get_texture().get_image().save_png(CAPTURES + name + ".png") == OK, "Guardar captura " + name)

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURES))
	SaveSystem.engagement_path = "user://ui_guidance_test.cfg"
	SaveSystem.store_engagement({"guide": 11, "record": 0, "achievements": []})
	world = load("res://levels/main.tscn").instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.story.present_dialogue = false
	world.player.set_physics_process(false)
	var prefs: GamePreferences = GamePreferences.current()
	prefs.values.glyphs = 0
	prefs.bindings.clear()
	InputGlyphs.last_pad = false
	verify(world.first_steps.step == 11 and world.first_steps.tips_done.is_empty(), "Perfil antiguo mantiene paso 11 y recibe consejos")
	verify(InputGlyphs.fill("Mantén {interact}; {journal}") == "Mantén E; L", "Teclas predeterminadas")
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_X
	prefs._input(pad)
	verify(InputGlyphs.fill("Mantén {interact}; {journal}") == "Mantén △; R1", "Boton cambia al mando")
	var drift: InputEventJoypadMotion = InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	InputGlyphs.last_pad = false
	verify(not InputGlyphs.observe(drift) and not InputGlyphs.using_pad(), "Deriva no cambia dispositivo")
	drift.axis_value = 0.8
	prefs._input(drift)
	verify(InputGlyphs.using_pad(), "Stick cambia al mando")
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse.relative = Vector2(8, 0)
	prefs._input(mouse)
	verify(not InputGlyphs.using_pad(), "Raton cambia al teclado")
	prefs._input(pad)
	prefs.bindings.interact = {"key": KEY_K, "pad": JOY_BUTTON_X}
	prefs.changed.emit()
	verify(InputGlyphs.action_name("interact") == "□", "Remapeo del mando")
	verify(find_text(world.equipment_shop, "Volver  [Options]"), "Arsenal actualiza cierre")
	var hud: GameHud = world.get_node("HUD")
	hud.pause_panel.show()
	paused = true
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_K
	prefs._input(key)
	verify(InputGlyphs.action_name("interact") == "K", "Teclado cambia durante pausa")
	verify(find_text(hud.pause_panel.controls, "K"), "Pausa usa ultimo dispositivo")
	prefs.bindings.interact.key = KEY_H
	prefs.changed.emit()
	verify(find_text(hud.pause_panel.controls, "H"), "Pausa actualiza remapeo abierto")
	prefs._input(pad)
	await picture("pausa_mando")
	prefs._input(key)
	prefs.values.glyphs = 2
	verify(InputGlyphs.action_name("interact") == "□", "Modo mando fijo")
	prefs.values.glyphs = 1
	verify(InputGlyphs.action_name("interact") == "H", "Modo teclado fijo")
	prefs.values.glyphs = 0
	paused = false
	hud.pause_panel.hide()
	var touch: TouchOverlay = TouchOverlay.current()
	touch.mode = TouchOverlay.MODE_ZONE
	touch.visible = true
	verify(InputGlyphs.action_name("interact") == "Operar" and InputGlyphs.action_name("journal") == "Diario", "Tactil conserva botones propios")
	touch.visible = false
	touch.mode = TouchOverlay.MODE_NONE
	load("res://tests/game_fixture.gd").found_colony(world)
	world.first_steps.enabled = true
	world.first_steps.persist = true
	world.engagement.enabled = true
	world.mobility.owned = true
	world.experience.xp = 6
	world.player.position.x = 75
	world.player.set_physics_process(true)
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	world.player.set_physics_process(false)
	world.presenter.publish()
	for guide_on: bool in [true, false]:
		for night: bool in [true, false]:
			for combo: bool in [true, false]:
				world.first_steps.enabled = guide_on
				world.first_steps.step = 2
				world.cycle.phase = "NOCHE" if night else "DÍA"
				world.engagement.night_active = night
				world.engagement.walls_lost = 1
				world.engagement.goal_changed.emit()
				world.rewards_hud.combo_label.text = "x5" if combo else ""
				world.rewards_hud.combo_left = 0.8
				hud.poison_label.show()
				await process_frame
				world.hud_stack.layout()
				verify_stack(hud)
				if night and combo: await picture("noche_guia" if guide_on else "noche_sin_guia")
	world.first_steps.enabled = true
	world.first_steps.step = 11
	world.cycle.phase = "DÍA"
	world.first_steps.tip = "journal"
	prefs._input(pad)
	await picture("diario_mando")
	var guide: FirstSteps = world.first_steps
	guide._process(0)
	world.story.journal.open_panel()
	guide._process(0)
	world.story.journal.close_panel()
	guide.tick_tips(0)
	verify("journal" in guide.tips_done, "Abrir diario pausado completa consejo")
	guide.tip = "recruit"
	guide.tip_baseline = guide.tip_measure("recruit")
	await picture("reclutar_mando")
	world.bank.deposit(100)
	verify(world.civic.interact(-300), "Reclutamiento real disponible")
	guide.tick_tips(0)
	verify("recruit" in guide.tips_done, "Reclutar completa consejo")
	guide.tip = "arsenal"
	world.player.position.x = -600
	world.equipment_shop.open_panel()
	guide._process(0)
	await picture("arsenal_mando")
	world.equipment_shop.close_panel()
	guide.tick_tips(0)
	verify("arsenal" in guide.tips_done and "herramientas" in guide.tip_caption("arsenal"), "Arsenal explica armas y oficios")
	guide.tip = "portal"
	verify(guide.target() == guide.nearest_portal().global_position, "Flecha al portal vivo")
	world.guide_hud._process(0)
	verify(world.guide_hud.banner_bottom() < 75, "Consejo con cruceta larga cabe en el cartel")
	await picture("portal_mando")
	world.civic.advance_side = -1
	guide.tick_tips(0)
	verify("portal" in guide.tips_done, "Ordenar asalto completa consejo")
	guide.tip = "overload"
	world.cycle.phase = "NOCHE"
	for site: ConstructionSite in world.construction.sites:
		if site.kind == &"turret": site.complete_work()
	world.player.position.x = -200
	world.guide_hud._process(0)
	verify(guide.target().x < 0 and guide.target() != world.player.position, "Sobrecarga apunta a torreta del lado del jugador")
	await picture("sobrecarga_mando")
	world.overload.overload_left = 2
	guide.tick_tips(0)
	verify("overload" in guide.tips_done, "Sobrecarga completa consejo")
	var saved: Dictionary = SaveSystem.engagement_profile()
	verify(saved.guide == 11 and "recruit" in saved.tips, "Consejos persisten sin cambiar pasos antiguos")
	var bank_before: int = world.bank.scrap
	guide.tick_tips(0)
	verify(world.bank.scrap == bank_before, "Consejos resueltos no pagan otra vez")
	world.options.open_panel()
	await picture("opciones_avisos")
	world.options.close_panel()
	guide.restart()
	verify(SaveSystem.engagement_profile().guide == 0 and SaveSystem.engagement_profile().tips.is_empty(), "Reiniciar guia tambien borra consejos")
	world.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.engagement_path))
	print("PASS: ui_guidance; %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func verify_stack(hud: GameHud) -> void:
	var edge: float = world.guide_hud.banner_bottom() if world.guide_hud.visible else 0.0
	for item: Label in [hud.objective, world.experience.status, world.mobility.status, world.rewards_hud.goal_label, hud.poison_label]:
		if not HudStack.shown(item): continue
		verify(item.position.y >= edge, "Texto apilado sin solaparse: " + item.text)
		edge = item.position.y + item.size.y
		if item == world.experience.status: edge = world.experience.bar_back.position.y + world.experience.bar_back.size.y
	if not world.rewards_hud.combo_label.text.is_empty():
		verify(world.rewards_hud.combo_label.position.y >= edge, "Combo debajo de los textos")
	verify(edge < 160, "Columna superior deja libre la zona de juego")

func find_text(node: Node, text: String) -> bool:
	if (node is Label or node is Button) and node.get("text") == text: return true
	for child: Node in node.get_children():
		if find_text(child, text): return true
	return false
