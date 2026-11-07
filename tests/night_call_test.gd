extends SceneTree
## Duración del día en los datos y "Adelantar la noche" manteniendo E en el núcleo.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func open_world(scene: String) -> District:
	var world: District = load(scene).instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	return world

## Mantiene la acción real de E (la misma que inyecta el botón táctil "Operar").
func hold_interact(world: District, seconds: float) -> void:
	Input.action_press("interact")
	var elapsed: float = 0.0
	while elapsed < seconds - 0.001:
		world.interaction.update_interaction(0.1)
		elapsed += 0.1
	Input.action_release("interact")
	world.interaction.update_interaction(0.1)

func run_checks() -> void:
	# Días de 120 s; el día de fundación (día 1) conserva margen para murallas, generador, Nv.2 y torretas.
	var kingdom: CycleConfig = load("res://data/cycles/kingdom.tres") as CycleConfig
	verify(kingdom.day_duration == 120.0 and kingdom.day_length(1) == 300.0 and kingdom.day_length(2) == 120.0 and kingdom.day_length(3) == 120.0, "kingdom.tres: fundación de 300 s y días de 120 s")
	var founding: Array[float] = [300.0, 315.0, 330.0, 345.0, 360.0]
	for index: int in CampaignRoute.COUNT:
		var world: District = open_world(CampaignRoute.SCENES[index])
		var config: CycleConfig = world.cycle.config
		verify(config.day_duration == 120.0 and config.day_length(2) == 120.0, CampaignRoute.zone(index).id + ": días de 120 s")
		verify(config.day_length(1) == founding[index] and world.cycle.phase_remaining == founding[index], CampaignRoute.zone(index).id + ": fundación de %d s" % founding[index])
		world.free()
		await process_frame
	var standard: CycleConfig = load("res://data/cycles/standard.tres") as CycleConfig
	verify(standard.day_length(1) == standard.day_duration, "Sin fundación propia, el día 1 dura lo mismo")

	var world: District = open_world("res://levels/main.tscn")
	var hud: GameHud = world.get_node("HUD") as GameHud
	hud.set_process(false)
	world.player.position.x = 0
	verify(not world.interaction.night_call_available(), "Sin núcleo encendido no se adelanta la noche")
	load("res://tests/game_fixture.gd").found_colony(world)
	verify(world.core.upgrade_blocker() == "Primero construye un generador", "Nv.1 recién encendido: mejora bloqueada por el generador")
	verify(world.interaction.night_call_available(), "De día, con núcleo encendido y nada que mejorar, se ofrece adelantar la noche")
	verify(world.interaction.required_hold(-1) == InteractionSystem.NIGHT_CALL_HOLD and InteractionSystem.NIGHT_CALL_HOLD > GameRules.INTERACT_HOLD, "Exige mantener E más que una obra")
	world.presenter.publish()
	verify(hud.context_row.visible and hud.context_label.text.begins_with("Adelantar la noche") and "generador" in hud.context_label.text and hud.context_keycap.visible and not hud.context_cost.visible, "El HUD muestra el aviso en español, con tecla y la razón del bloqueo")

	# Curar tiene prioridad sobre adelantar la noche.
	world.player.health = 50
	verify(not world.interaction.night_call_available(), "Herido: E en el núcleo cura antes")
	verify(world.interaction.perform_interaction(-1) and world.player.health == Player.MAX_HEALTH and world.cycle.phase == "DÍA", "E cura sin adelantar la noche")

	# Un toque breve no dispara el salto.
	var phases: Array[String] = []
	world.cycle.phase_changed.connect(func(phase: String, _day: int) -> void: phases.append(phase))
	var notices: Array[String] = []
	world.cycle.notice_requested.connect(func(message: String) -> void: notices.append(message))
	hold_interact(world, 1.0)
	verify(world.cycle.phase == "DÍA" and phases.is_empty(), "Mantener 1 s no adelanta la noche")
	var day_left: float = world.cycle.phase_remaining
	hold_interact(world, InteractionSystem.NIGHT_CALL_HOLD + 0.1)
	verify(world.cycle.phase == "AVISO" and world.cycle.phase_remaining == world.cycle.config.warning_duration, "Mantener E salta al AVISO completo, no a la noche")
	verify(phases.size() == 1 and phases[0] == "AVISO" and "Ataque en ambos frentes" in notices and day_left > 200.0, "El salto emite el cambio de fase y el aviso habitual")
	verify(world.cycle.day == 1, "Adelantar la noche no cambia el número de día")
	verify(not world.interaction.night_call_available() and not world.cycle.skip_day(), "En AVISO ya no se puede volver a adelantar")
	world.presenter.publish()
	verify(not hud.context_label.text.begins_with("Adelantar la noche"), "Fuera del día desaparece la opción")
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.cycle.phase == "NOCHE" and not world.cycle.skip_day(), "De noche no hay salto")
	for enemy: Node in get_nodes_in_group(GameRules.ENEMIES): enemy.free()
	world.director.spawn_count = world.director.wave.enemies.size()
	world.cycle.phase_remaining = 0
	world.cycle.update_phase(0)
	verify(world.cycle.phase == "DÍA" and world.cycle.day == 2 and world.cycle.phase_remaining == 120.0, "Tras la fundación, los días duran 120 s")

	# Si la mejora del núcleo está disponible, E sigue mejorando.
	world.cycle.phase = "DÍA"
	world.cycle.phase_remaining = world.cycle.config.day_duration
	world.expansion.sites[2].hp = 180
	for site: ConstructionSite in world.construction.sites:
		if site.data.blocks_enemies: site.hp = site.max_hp
	world.bank.scrap = 500
	world.bank.parts = world.bank.parts_capacity
	if world.core.upgrade_blocker().is_empty():
		verify(not world.interaction.night_call_available(), "Con mejora posible no se ofrece adelantar la noche")
		verify(world.interaction.required_hold(-1) == GameRules.INTERACT_HOLD, "La mejora conserva su tiempo de E")
		verify(world.interaction.perform_interaction(-1) and world.core.ordered and world.cycle.phase == "DÍA", "E en el núcleo mejora en vez de saltar el día")
		verify(not world.interaction.night_call_available(), "Con el núcleo en obras no se adelanta la noche")
	else:
		verify(false, "Preparación de mejora inesperadamente bloqueada: " + world.core.upgrade_blocker())

	# Congelado por depuración no se salta.
	world.core.ordered = false
	world.cycle.debug_frozen = true
	verify(not world.cycle.skip_day() and world.cycle.phase == "DÍA", "El ciclo congelado no se adelanta")
	world.cycle.debug_frozen = false
	world.free()
	await process_frame
	print("Adelantar la noche: %d comprobaciones, fallos: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)
