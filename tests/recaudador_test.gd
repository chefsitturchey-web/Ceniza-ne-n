extends SceneTree

var failures: int = 0
var checks: int = 0
var outcomes: Array[bool] = []
const ARENA: PackedScene = preload("res://levels/expedition/recaudador_arena.tscn")

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func create_arena() -> RecaudadorArena:
	var arena: RecaudadorArena = ARENA.instantiate() as RecaudadorArena
	root.add_child(arena)
	arena.boss.set_physics_process(false)
	arena.player.set_physics_process(false)
	# Esta suite mide ataques manuales y patrones; los módulos tienen suite propia.
	arena.modules.set_physics_process(false)
	arena.set_process(false)
	arena.resolved.connect(func(victory: bool) -> void: outcomes.append(victory))
	return arena

func run_checks() -> void:
	var arena: RecaudadorArena = create_arena()
	var boss: Recaudador = arena.boss
	var player: TopdownPlayer = arena.player
	await physics_frame
	await process_frame
	verify(arena.viewport.world_2d != root.world_2d, "Mundo fisico aislado de la colonia")
	verify(boss.receive_hit(boss.position + Vector2.DOWN * 50, 50) == 0 and boss.health == boss.max_health, "Escudo bloquea frente")
	verify(boss.receive_hit(boss.position + Vector2.UP * 50, 100) == 25, "Espalda recibe 25 por ciento")
	verify(boss.receive_hit(boss.position + Vector2.RIGHT * 50, 100) == 25, "Lado recibe 25 por ciento")
	var prior_health: int = boss.health
	arena.strike(boss.position + Vector2.UP * 55, Vector2.DOWN, 100, 42)
	verify(boss.health == prior_health - 25, "Arco de hoja alcanza al jefe")
	prior_health = boss.health
	arena.strike(boss.position + Vector2.UP * 55, Vector2.UP, 100, 42)
	arena.strike(boss.position + Vector2.UP * 150, Vector2.DOWN, 100, 42)
	verify(boss.health == prior_health, "Arco respeta direccion y alcance")
	boss.position = Vector2(205, 160)
	arena.strike(Vector2(155, 160), Vector2.RIGHT, 100, 42)
	verify(boss.health == prior_health, "Cobertura bloquea tambien golpes de hoja")
	boss.position = Vector2(320, 60)
	boss.charge_direction = Vector2.UP
	boss.charges_left = 1
	boss.change_state(Recaudador.State.CHARGE, 1.8)
	boss._physics_process(0.1)
	verify(boss.state == Recaudador.State.STUNNED and boss.core_exposed and boss.timer == 2.5, "Embestida real contra pared abre nucleo 2.5 s")
	verify(boss.receive_hit(boss.position + boss.facing * 50, 50) == 100, "Nucleo expuesto recibe x2 incluso de frente")
	boss._physics_process(2.49)
	verify(boss.core_exposed, "Ventana no termina antes de 2.5 s")
	boss._physics_process(0.02)
	verify(not boss.core_exposed, "Compuerta cierra tras ventana")
	boss.health = boss.max_health / 2 + 1
	boss.phase = 1
	boss.facing = Vector2.DOWN
	verify(boss.phase == 1, "Fase 1 sobre umbral")
	boss.receive_hit(boss.position + Vector2.UP * 50, 4)
	verify(boss.health == boss.max_health / 2 and boss.phase == 2, "Fase 2 exacta al 50 por ciento")
	boss.next_pattern = 2
	boss.change_state(Recaudador.State.RECOVER, 0)
	boss._physics_process(0.01)
	verify(boss.charges_left == 2 and boss.state == Recaudador.State.CHARGE_WINDUP, "Fase 2 prepara dos embestidas")
	boss.stun()
	boss._physics_process(2.51)
	verify(boss.charges_left == 1 and boss.state == Recaudador.State.CHARGE_WINDUP, "Segunda embestida conserva aviso")
	var shots: Array[Vector2] = []
	boss.fired.connect(func(_origin: Vector2, direction: Vector2) -> void: shots.append(direction))
	boss.phase = 1
	boss.fire_fan()
	verify(shots.size() == 5, "Abanico fase 1")
	shots.clear()
	boss.phase = 2
	boss.fire_fan()
	verify(shots.size() == 7, "Abanico fase 2 mas denso")
	for child: Node in arena.world.get_children():
		if child is RecaudadorBullet:
			child.queue_free()
	player.stamina = 100
	player.dodge()
	player.take_damage(40)
	verify(player.health == 100 and player.stamina == 80, "Esquiva cuesta 20 e impide dano")
	player.dodge_remaining = 0
	player.dodge_cooldown_remaining = 0
	player.stamina = 19
	player.dodge()
	verify(player.dodge_remaining == 0, "No esquiva sin resistencia")
	player.invulnerable = 0
	player.take_damage(10)
	verify(player.health == 90 and arena.damage_edges.player_flash > 0, "Dano dispara vineta")
	var event: InputEventAction = InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	arena._input(event)
	verify(paused and arena.pause_panel.visible and not boss.can_process(), "Pausa suspende combate")
	arena._input(event)
	verify(not paused and not arena.pause_panel.visible, "Pausa reanuda")
	await process_frame
	await process_frame
	player.invulnerable = 0
	player.dodge_remaining = 0
	player.position = Vector2(320, 350)
	Input.action_press("arena_up")
	Input.action_press("move_right")
	player._physics_process(0.1)
	Input.action_release("arena_up")
	Input.action_release("move_right")
	verify(player.facing.x > 0 and player.facing.y < 0 and is_equal_approx(player.velocity.length(), player.speed), "Movimiento diagonal normalizado")
	player.facing = Vector2.UP
	player.velocity = Vector2.UP * player.speed
	player.update_visual()
	verify(player.sprite.texture == TopdownPlayer.VIEWS[1] and not player.runner.visible, "Carrera norte usa vista preparada para animacion")
	player.facing = Vector2.LEFT
	player.update_visual()
	verify(player.runner.visible and player.runner.animation == &"correr" and player.runner.flip_h, "Carrera oeste reutiliza animacion lateral")
	var bullet: RecaudadorBullet = RecaudadorBullet.new()
	bullet.position = Vector2(140, 160)
	bullet.velocity = Vector2(200, 0)
	arena.world.add_child(bullet)
	bullet.set_physics_process(false)
	await physics_frame
	await process_frame
	bullet._physics_process(0.3)
	verify(bullet.spent and bullet.is_queued_for_deletion(), "Bala choca y se destruye contra pilar real")
	var border_bullet: RecaudadorBullet = RecaudadorBullet.new()
	border_bullet.position = Vector2(45, 80)
	border_bullet.velocity = Vector2(-200, 0)
	arena.world.add_child(border_bullet)
	border_bullet.set_physics_process(false)
	await physics_frame
	await process_frame
	border_bullet._physics_process(0.3)
	verify(border_bullet.spent, "Bordes destruyen balas")
	if "--capture" in OS.get_cmdline_user_args():
		boss.position = Vector2(320, 200)
		boss.stun()
		boss.update_puppet(0.3)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/recaudador-arena.png")
	boss.stun()
	boss.receive_hit(boss.position + Vector2.UP * 50, boss.max_health)
	verify(arena.ending and outcomes.is_empty(), "Muerte inicia cartel antes de resolver")
	arena._process(2.3)
	arena._process(2.3)
	verify(outcomes == [true], "Matar jefe emite resolved true una sola vez")
	verify(arena.completed and arena.result_shade.visible, "Arena ejecutada sola muestra final navegable")
	verify(DebrisEmitter.live_count <= DebrisEmitter.LIMIT, "Explosion respeta limite global")
	arena.free()
	await process_frame
	verify(DebrisEmitter.live_count == 0, "Salir libera todas las particulas")
	outcomes.clear()
	arena = create_arena()
	arena.player.take_damage(100)
	verify(arena.banner.text == "SENAL PERDIDA", "Muerte jugador muestra cartel")
	arena._process(1.3)
	arena._process(1.3)
	verify(outcomes == [false], "Muerte jugador emite resolved false una sola vez")
	verify(arena.completed and arena.find_children("*", "Button", true, false).size() >= 5, "Derrota en arena independiente ofrece reintento y menú")
	arena.free()
	await process_frame
	print("Recaudador: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
