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
	# Banco de combate aislado de las reglas de colonia.
	world.player.combat_enabled = true
	world.player.hitbox.enabled = true
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var runner: SiegeEnemy = world.director.spawn_enemy(1.0, load("res://data/enemies/corredor.tres"))
	runner.set_physics_process(false)
	verify(runner.sprite != null and runner.sprite.sprite_frames.get_animation_names().size() == 6, "Corredor instancia seis animaciones")
	runner._physics_process(0.1)
	verify(runner.sprite.animation == &"correr" and runner.sprite.flip_h, "Corredor corre hacia el núcleo")
	world.player.position.x = runner.position.x - 20.0
	runner._physics_process(0.1)
	verify(runner.state == SiegeEnemy.State.WINDUP and runner.sprite.animation == &"ataque", "Estado y animación de anticipación")
	var health: int = world.player.health
	runner._physics_process(0.4)
	verify(world.player.health == health, "La animación no adelanta el daño")
	runner._physics_process(0.2)
	verify(runner.state == SiegeEnemy.State.ATTACK and world.player.health == health - 8, "Mismo instante y daño del corredor")
	runner.take_damage(1)
	verify(runner.sprite.animation == &"daño", "Reacción de daño")
	runner.take_damage(1000)
	verify(runner.state == SiegeEnemy.State.DEAD and runner.sprite.animation == &"destruccion" and not runner.is_in_group(GameRules.ENEMIES), "Muerte visual sin amenaza")
	verify(not runner.sprite.sprite_frames.get_animation_loop(&"ataque") and not runner.sprite.sprite_frames.get_animation_loop(&"destruccion"), "Ataque y destrucción sin bucle")
	runner._physics_process(3.0)
	verify(runner.is_queued_for_deletion(), "Cadáver se elimina aunque no avance el renderizador")
	var builder: ColonyWorker = world.colony.workers[0]
	verify(builder.visual.sprite != null and builder.visual.sprite.sprite_frames.get_animation_names().size() == 5, "Constructor instancia cinco animaciones")
	verify(builder.visual.sprite.animation == &"reposo", "Constructor comienza en reposo")
	world.interaction.perform_interaction(0)
	world.colony.update_workers(0.1)
	verify(builder.visual.sprite.animation == &"caminar" and builder.visual.sprite.flip_h, "Constructor camina a su obra")
	for step: int in range(34):
		world.colony.update_workers(0.1)
	verify(builder.visual.sprite.animation == &"reparar", "Constructor trabaja al llegar")
	for step: int in range(50):
		world.colony.update_workers(0.1)
	verify(world.construction.sites[0].hp == 240, "Animación no cambia la duración de obra")
	verify(builder.visual.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and builder.visual.sprite.position == Vector2(0, -21), "Anclaje y filtro del constructor")
	verify(world.colony.workers[1].visual is EntityVisual and world.player.visual is EntityVisual, "Interfaz visual común para provisionales")
	world.player.invulnerable = 0.0
	world.player.take_damage(1000)
	verify(world.player.state == Player.State.DEAD, "Estado muerto del jugador")
	world.player._physics_process(4.1)
	verify(world.player.state == Player.State.IDLE, "Reenlace vuelve a reposo")
	world.player.attack()
	verify(world.player.state == Player.State.ATTACK, "Estado ataque del jugador")
	world.player.dodge()
	verify(world.player.state == Player.State.DODGE, "Esquiva conserva prioridad sobre ataque")
	world.free()
	print("Integración visual: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
