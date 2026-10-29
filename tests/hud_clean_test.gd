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
	var hud: GameHud = world.get_node("HUD") as GameHud
	hud.set_process(false)
	var pixel_theme: Theme = load("res://ui/theme.tres")
	verify(ProjectSettings.get_setting("gui/theme/custom") == "res://ui/theme.tres" and pixel_theme.default_font_size == 12, "Texto pixel legible a 12 px")
	for path: String in ["Micro5-Regular.ttf", "Silkscreen-Regular.ttf"]:
		var font: FontFile = load("res://assets/fonts/" + path)
		verify(font.antialiasing == TextServer.FONT_ANTIALIASING_NONE and font.hinting == TextServer.HINTING_NONE and font.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED and not font.generate_mipmaps, "Fuente sin suavizado: " + path)
	verify(hud.values.phase.get_theme_font("font") == pixel_theme.get_font("font", "Title") and hud.values.phase.get_theme_font_size("font_size") == 16, "Título Silkscreen a 16 px")
	verify_hud_text(hud)
	verify(not ConstructionSite.WORLD_BARS_ENABLED and not ColonyCore.WORLD_BARS_ENABLED and not EnemyVisual.WORLD_BARS_ENABLED, "Sin barras en estructuras y enemigos")
	for path: String in ["entities/structures/construction_site.gd", "entities/structures/colony_core.gd", "entities/enemies/enemy_visual.gd"]:
		var source: String = FileAccess.get_file_as_string("res://" + path)
		for line: String in source.split("\n"):
			if "draw_rect" in line:
				verify(not ("health /" in line or "hp /" in line or "progress /" in line), "El dibujo no contiene barras: " + path)
	verify(hud.get_node("Gameplay").find_children("*", "ProgressBar", true, false).is_empty(), "Sin barras en HUD de juego")
	verify(hud.phase_banner.visible and "DÍA 1" in hud.values.phase.text, "Cartel inicial de amanecer")
	hud._process(2.6)
	verify(not hud.phase_banner.visible, "Cartel desaparece en 2.5 s")
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.phase_banner.visible, "Publicar misma fase no reinicia cartel")
	world.cycle.phase = "AVISO"
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.phase_banner.visible and hud.icons.aviso.visible and "ATARDECER" in hud.values.phase.text, "Cambio de fase muestra cartel e icono")
	world.director.start(1)
	world.director.spawn_remaining = 10
	world.cycle.phase = "NOCHE"
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.icons.noche.visible and "NOCHE 1" in hud.values.phase.text, "Cartel nocturno")
	await process_frame
	Input.action_press("pause")
	world.session._process(0)
	Input.action_release("pause")
	verify_hud_text(hud)
	verify(paused and hud.pause_panel.visible and not hud.get_node("Gameplay").visible, "Esc/Start abre pausa y oculta HUD jugable")
	await process_frame
	verify(hud.pause_panel.size.x <= 560 and hud.pause_panel.size.y <= 332, "Texto ampliado y controles caben en el panel")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/hud-pause.png")
	Input.action_press("pause")
	world.session._process(0)
	Input.action_release("pause")
	verify(not paused and not hud.pause_panel.visible and hud.get_node("Gameplay").visible, "Reanudar oculta pausa")
	var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/corredor.tres"))
	enemy.set_physics_process(false)
	var screen_to_world: Transform2D = root.get_canvas_transform().affine_inverse()
	enemy.global_position = screen_to_world * Vector2(320, 270)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.left_arrow.visible and not hud.right_arrow.visible, "Enemigo visible no activa flechas")
	enemy.global_position = screen_to_world * Vector2(-80, 270)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.left_arrow.visible and not hud.right_arrow.visible, "Fuera a izquierda activa solo izquierda")
	enemy.global_position = screen_to_world * Vector2(720, 270)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.left_arrow.visible and hud.right_arrow.visible, "Fuera a derecha activa solo derecha")
	var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
	camera.position.x = 400
	camera.zoom = Vector2(1.5, 1.5)
	camera.force_update_scroll()
	enemy.global_position = root.get_canvas_transform().affine_inverse() * Vector2(320, 270)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.left_arrow.visible and not hud.right_arrow.visible, "Indicadores siguen desplazamiento y zoom de cámara")
	enemy.take_damage(1000)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.left_arrow.visible and not hud.right_arrow.visible, "Cadáver no activa amenazas")
	camera.position.x = 0
	camera.zoom = Vector2.ONE
	camera.force_update_scroll()
	world.player.health_component.take_damage(65)
	world.presenter.publish()
	verify_hud_text(hud)
	var edges: Control = hud.get_node("DamageEdges")
	verify(edges.player_flash > 0 and edges.low_health, "Daño activa destello y latido al 35%")
	edges._process(0.5)
	verify(edges.player_flash == 0 and edges.low_health, "Destello termina, latido continúa")
	world.player.health = Player.MAX_HEALTH
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not edges.low_health and edges.player_flash == 0, "Curar elimina latido sin destello")
	world.core.take_damage(ceili(GameRules.CORE_HEALTH * 0.7))
	world.presenter.publish()
	verify_hud_text(hud)
	verify(edges.core_flash > 0 and hud.toast.text == "Núcleo dañado", "Daño del núcleo: ámbar y aviso crítico")
	world.presenter.tick(4)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.toast.text.is_empty(), "Aviso crítico no se repite durante la misma noche")
	world.cycle.day += 1
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.toast.text.is_empty(), "Nueva noche permite otro aviso crítico")
	world.presenter.tick(2.7)
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.toast.modulate.a < 1 and hud.toast.modulate.a > 0, "Toast se desvanece")
	world.player.position.x = world.construction.sites[0].x
	world.interaction.hold_time = 0.2
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.context_row.visible and hud.context_label.text == "Construir" and hud.context_keycap.visible and hud.context_cost.text == str(world.construction.sites[0].cost), "Interacción muestra tecla, acción y coste")
	verify(hud.context_progress.visible and hud.context_progress.size.y == 1 and "%" not in hud.context_label.text, "Progreso en línea fina sin porcentaje")
	var context_site: ConstructionSite = world.construction.sites[0]
	context_site.hp = 1
	world.presenter.publish()
	verify(hud.context_label.text == "Reparar" and hud.context_cost.text == str(context_site.data.repair_cost), "Reparación muestra coste real")
	context_site.hp = 0
	context_site.ordered = true
	context_site.progress = GameRules.BUILD_TIME * 0.5
	world.presenter.publish()
	verify(hud.context_label.text == "Construyendo" and not hud.context_keycap.visible and not hud.context_cost.visible and hud.context_progress.visible, "Obra muestra progreso sin coste ni tecla")
	verify_hud_text(hud)
	context_site.ordered = false
	context_site.progress = 0
	var site: ConstructionSite = world.construction.sites[0]
	var anchor: Vector2 = site.get_global_transform_with_canvas() * Vector2(0, -site.visual_height())
	verify(is_equal_approx(hud.context_row.position.y, clampf(anchor.y - 24, 50, 280)), "Rótulo anclado sobre objeto en pantalla")
	world.player.position.x = 900
	world.presenter.publish()
	verify_hud_text(hud)
	verify(not hud.context_row.visible, "Sin objeto cercano no hay rótulo")
	world.player.position.x = 0
	world.presenter.publish()
	verify_hud_text(hud)
	verify(hud.context_row.visible and hud.context_label.text == world.core.upgrade_blocker() and not hud.context_label.text.is_empty(), "Núcleo explica el requisito aplicable de su próxima mejora")
	world.player.health = Player.MAX_HEALTH - 1
	world.presenter.publish()
	verify(hud.context_label.text == "Curarte" and not hud.context_icon.visible and not hud.context_cost.visible, "Curación sin coste")
	verify_hud_text(hud)
	world.player.health = Player.MAX_HEALTH
	world.presenter.publish()
	if "--capture" in OS.get_cmdline_user_args():
		hud._process(3)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/hud-game.png")
	world.player.health = 0
	world.presenter.publish()
	verify_hud_text(hud)
	verify("Reenlace" in hud.get_node("Result").text, "Reaparición mantiene texto centrado")
	world.session.finish(true)
	verify("ESTABILIZADO" in hud.get_node("Result").text and not hud.get_node("Gameplay").visible, "Victoria centrada")
	verify_hud_text(hud)
	world.session.finish(false)
	verify("DESTRUIDO" in hud.get_node("Result").text, "Derrota centrada")
	verify_hud_text(hud)
	world.free()
	print("HUD limpio: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)

func verify_hud_text(hud: GameHud) -> void:
	for node: Node in hud.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if not label.is_visible_in_tree():
			continue
		var valid: bool = true
		for index: int in range(label.text.length()):
			if label.text.unicode_at(index) > 255 or label.text.unicode_at(index) == 183:
				valid = false
		verify(valid, "Texto visible Latin-1 sin adornos: " + label.text)
