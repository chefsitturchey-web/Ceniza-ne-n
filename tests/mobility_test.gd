extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run_checks")

func verify(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	world.get_node("Session").persistence_enabled = false
	root.add_child(world)
	world.story.present_dialogue = false
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.experience.present_choices = false
	world.bank.scrap = 500
	var ride: MobilitySystem = world.mobility
	world.player.position.x = MobilitySystem.PAD_X
	verify(not ride.interact() and not ride.owned and world.bank.scrap == 500, "El transporte exige núcleo Nv.2 sin cobrar antes")
	world.core.restore({"tier": 2, "ordered": false, "progress": 0})
	world.player.position.x = 0
	verify(not ride.interact(), "No se compra una plataforma desde otra ubicación")
	world.player.position.x = MobilitySystem.PAD_X
	verify(world.interaction.interaction_target() == InteractionSystem.MOBILITY_TARGET, "E detecta el taller de transporte")
	verify(world.interaction.perform_interaction(InteractionSystem.MOBILITY_TARGET) and world.bank.scrap == 455 and ride.mounted, "Compra única por 45 y monta")
	verify(world.player.speed == 220 and world.player.travel_speed_factor == 1.45, "Conserva la velocidad del Inspector y aplica un factor de viaje")
	await physics_frame
	Input.action_press("move_right")
	for step: int in range(6): world.player._physics_process(0.1)
	Input.action_release("move_right")
	verify(world.player.velocity.x > world.player.speed * Player.COLONY_MOVEMENT_FACTOR and world.player.visual.sprite.animation == &"reposo", "El pasajero supera la marcha de colonia sin correr encima")
	ride.tick(10)
	verify(is_equal_approx(ride.charge, 60), "Moverse consume batería según el tiempo")
	ride.charge = 0.1
	ride.tick(1)
	verify(ride.charge == 0 and world.player.travel_speed_factor < 1, "Batería agotada tiene una consecuencia visible")
	verify(ride.toggle_mount() and world.player.travel_speed_factor == 1 and not ride.mounted, "Desmontar recupera la marcha normal")
	var parked: float = ride.parked_x
	world.player.position.x = parked + 100
	verify(not ride.toggle_mount(), "El vehículo permanece donde se dejó; no se teletransporta al Portador")
	world.player.position.x = parked
	verify(ride.toggle_mount(), "Se recupera al volver junto a él")
	world.player.position.x = 0
	world.player.velocity = Vector2.ZERO
	ride.tick(5)
	verify(ride.charge == 100 and world.player.travel_speed_factor == 1.45, "Detenerse en el núcleo recarga la batería")
	world.player.position.x = 120
	ride.toggle_mount()
	world.player.position.x = 0
	verify(world.interaction.interaction_target() == -1, "Aparcar conserva las interacciones con el núcleo")
	var save: SaveSystem = SaveSystem.new()
	save.session = world.session
	save.save_path = "user://mobility_test.json"
	world.add_child(save)
	ride.charge = 66
	verify(save.save_game(), "Guarda propiedad, batería y aparcamiento")
	ride.restore({})
	verify(save.load_game() and ride.owned and not ride.mounted and ride.charge == 66 and ride.parked_x == 120, "El transporte restaura su estado exacto")
	var transfer: Dictionary = CampaignRoute.handoff(1, world.neural.snapshot(), 10, world.colony.workers, ride.snapshot())
	verify(CampaignRoute.valid_handoff(transfer) and transfer.mobility.owned and not transfer.mobility.mounted and transfer.mobility.parked_x == 0, "El tren lleva la plataforma al núcleo de la siguiente colonia")
	var bad: Dictionary = ride.snapshot()
	bad.charge = NAN
	verify(not MobilitySystem.valid(bad), "Rechaza batería no finita")
	bad = ride.snapshot()
	bad.owned = false
	bad.mounted = true
	verify(not MobilitySystem.valid(bad), "No restaura un vehículo montado sin propiedad")
	world.player.position.x = 120
	ride.toggle_mount()
	load("res://tests/game_fixture.gd").stabilize(world)
	world.expedition.restore({"destroyed": [true, true], "train_arrived": true})
	verify(world.expedition.start(), "Viaja a un jefe con transporte adquirido")
	verify(world.expedition.arena.player.speed == 220 and not ride.hud.visible and not world.story.hud.visible, "En arena mantiene combate a pie y oculta el HUD de colonia")
	world.expedition.resolve(false)
	verify(ride.owned and ride.mounted, "Volver de una derrota conserva el vehículo de la colonia")
	world.player.health = 0
	ride.tick(0)
	verify(not ride.mounted and world.player.travel_speed_factor == 1, "Morir deja la plataforma aparcada y termina el aumento de velocidad")
	world.player.health = 100
	world.player.position.x = ride.parked_x
	ride.toggle_mount()
	world.player.refresh_state()
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/fortress"))
		world.player.position.x = 70
		var camera: Camera2D = world.player.get_node("Camera2D") as Camera2D
		camera.position_smoothing_enabled = false
		camera.force_update_scroll()
		world.presenter.publish()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/fortress/plataforma.png")
	save.delete_save()
	world.free()
	await process_frame
	print("Movilidad: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
