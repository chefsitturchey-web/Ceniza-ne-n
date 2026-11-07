extends SceneTree
## Progresión con efecto doble (colonia y jefes), curva de jefes y cierre de campaña.
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func arena_for(index: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate() as RecaudadorArena
	arena.zone_index = index
	arena.present_story = false
	root.add_child(arena)
	arena.boss.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.set_process(false)
	return arena

func run_checks() -> void:
	GamePreferences.current().briefing_requested = false
	var world: District = load("res://levels/main.tscn").instantiate() as District
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	load("res://tests/game_fixture.gd").found_colony(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var gear: ModuleSystem = world.modules
	verify(is_equal_approx(gear.turret_damage_factor(), 1.06), "El dron inicial ya refuerza las torretas")
	gear.levels.drone = 3
	verify(is_equal_approx(gear.turret_damage_factor(), 1.18), "Cada nivel del dron suma un 6 % de daño de torreta")
	gear.levels.tesla = 2
	verify(gear.wall_shock() == 0, "Un módulo sin equipar no actúa en la colonia")
	gear.equipped.append("tesla")
	verify(gear.wall_shock() == 6, "Tesla equipada electrifica las murallas")
	var capacity: int = world.bank.available_capacity()
	gear.passives.battery = true
	gear.passive_levels.battery = 3
	verify(world.bank.available_capacity() == capacity + 2, "La batería auxiliar amplía la energía de la colonia")
	gear.passives.bearing = true
	gear.passive_levels.bearing = 5
	world.neural.changed.emit()
	verify(is_equal_approx(world.colony.work_factor, 1.3), "El rodamiento acelera a los constructores")
	var options: Array[Dictionary] = world.experience.options()
	verify(options.all(func(option: Dictionary) -> bool: return "Colonia" in option.text or "Jefes" in option.text or option.type == "scrap"), "Las cartas explican su efecto en colonia y contra jefes")
	world.free()
	await process_frame

	var health: Array[int] = []
	for index: int in CampaignRoute.COUNT:
		var arena: RecaudadorArena = arena_for(index)
		health.append(arena.boss.max_health)
		if index == 3:
			var prefect: ElPrefecto = arena.boss as ElPrefecto
			prefect.change_state(Recaudador.State.APPROACH, 2)
			prefect.facing = (arena.player.global_position - prefect.global_position).normalized()
			verify(prefect.receive_hit(arena.player.global_position, 50) == 0 and prefect.state == Recaudador.State.CLAW_WINDUP and prefect.last_decision == "riposte", "Golpear el escudo del Prefecto provoca un contraataque")
			prefect.change_state(Recaudador.State.RECOVER, 1)
			prefect.receive_hit(arena.player.global_position, int(prefect.max_health * 0.4))
			verify(prefect.last_guard and prefect.recovery(1.8) < 1.8 * 0.85, "La última guardia acorta las ventanas de castigo")
			for step: int in 6: prefect.tactics.observe(arena.player, 0.2)
			verify(prefect.tactics.dodges == 0, "Sin esquivas no hay lectura de hábitos")
		if index == 4:
			var mother: MadreCero = arena.boss as MadreCero
			mother.health = int(mother.max_health * 0.25)
			mother._physics_process(0.1)
			verify(mother.last_protocol, "MADRE CERO entra en su último protocolo")
			arena.show_completed()
			verify(arena.banner.text == "FIN DE LA CAMPAÑA", "Vencer a MADRE CERO muestra el cierre de campaña")
		arena.free()
		await process_frame
	var ascending: bool = true
	for index: int in range(1, health.size()): ascending = ascending and health[index] > health[index - 1]
	verify(ascending, "Cada jefe resiste más que el anterior: %s" % str(health))
	verify(TopdownPlayer.ARENA_PACE < 1.0 and TopdownPlayer.ARENA_STAMINA_REGEN < 1.0, "La arena es más pausada y recupera resistencia más despacio")
	print("Progresión y jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
