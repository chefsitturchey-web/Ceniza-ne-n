extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	var world: District = load("res://levels/main.tscn").instantiate() as District
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	var enemy: SiegeEnemy = world.director.spawn_enemy(1, load("res://data/enemies/errante.tres") as EnemyData)
	enemy.set_physics_process(false)
	var sprite: AnimatedSprite2D = enemy.get_node("AnimatedSprite2D")
	verify(sprite.sprite_frames.get_animation_names().size() == 5, "Cinco animaciones cargadas")
	verify(sprite.position == Vector2(0, -21), "Pies anclados al suelo")
	verify(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Pixel art sin suavizado")
	enemy._physics_process(0.1)
	verify(sprite.animation == &"caminar" and sprite.flip_h, "Caminar hacia la izquierda")
	enemy.position.x = -400
	enemy._physics_process(0.1)
	verify(not sprite.flip_h, "Caminar hacia la derecha")
	world.player.position.x = -380
	enemy._physics_process(0.1)
	verify(sprite.animation == &"ataque" and enemy.windup > 0, "Ataque con anticipación")
	verify(not sprite.sprite_frames.get_animation_loop(&"ataque"), "Ataque sin bucle")
	var original_health: int = world.player.health
	enemy._physics_process(0.6)
	verify(world.player.health == original_health - enemy.damage, "El ataque conserva su daño")
	enemy.take_damage(1)
	verify(sprite.animation == &"daño", "Animación de daño")
	enemy._physics_process(0.4)
	verify(sprite.animation == &"reposo", "Reposo durante recuperación")
	var original_scrap: int = world.bank.scrap
	enemy.take_damage(1000)
	verify(sprite.animation == &"destruccion" and not enemy.is_queued_for_deletion(), "Mostrar muerte antes de borrar")
	verify(not enemy.is_in_group("enemies"), "La muerte deja de contar como amenaza")
	enemy.take_damage(1000)
	verify(world.bank.scrap == original_scrap + 3, "Una sola recompensa por enemigo")
	verify(not sprite.sprite_frames.get_animation_loop(&"destruccion"), "Destrucción sin bucle")
	await create_timer(2.3).timeout
	verify(not is_instance_valid(enemy), "Desaparición al terminar la animación")
	var runner: SiegeEnemy = world.director.spawn_enemy(-1, load("res://data/enemies/corredor.tres") as EnemyData)
	runner.set_physics_process(false)
	verify(runner.get_node_or_null("AnimatedSprite2D") != null, "Corredor utiliza su escena animada")
	runner.take_damage(1000)
	verify(not runner.is_in_group(GameRules.ENEMIES) and runner.sprite.animation == &"destruccion", "Corredor muerto deja de ser amenaza y muestra destrucción")
	world.queue_free()
	await process_frame
	print("Animaciones: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
