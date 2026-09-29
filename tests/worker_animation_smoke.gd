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
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var builder: Dictionary = world.workers[0]
	verify(builder.role == "builder", "El primer habitante es constructor")
	var visual: Node2D = builder.get("visual") as Node2D
	verify(visual != null, "El constructor tiene capa visual")
	var sprite: AnimatedSprite2D = visual.get_node("AnimatedSprite2D") as AnimatedSprite2D
	verify(sprite != null, "El constructor usa AnimatedSprite2D")
	verify(sprite.position == Vector2(0, -21), "Pies anclados al suelo")
	verify(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Pixel art sin suavizado")
	verify(sprite.sprite_frames.get_animation_names().size() == 5, "Cinco animaciones del constructor")
	verify(not world.workers[1].has("visual"), "El recuperador conserva su representación provisional")
	world.update_workers(0.1)
	verify(sprite.animation == &"caminar", "Se desplaza al punto de espera")
	world.sites[0].ordered = true
	builder.x = world.sites[0].x
	world.update_workers(0.1)
	verify(sprite.animation == &"reparar", "Repara al llegar a la obra")
	world.queue_free()
	await process_frame
	print("Constructor: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
