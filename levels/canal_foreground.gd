class_name CanalForeground
extends Node2D

func _ready() -> void:
	z_index = 3
	var surface: ShaderMaterial = ShaderMaterial.new()
	surface.shader = preload("res://components/canal_reflection.gdshader")
	material = surface

func _process(_delta: float) -> void:
	var line: Vector2 = get_global_transform_with_canvas() * Vector2(0, GameRules.FLOOR_Y + 12)
	(material as ShaderMaterial).set_shader_parameter("waterline", line.y / get_viewport_rect().size.y)

func _draw() -> void:
	draw_rect(Rect2(-2000, GameRules.FLOOR_Y + 12, 4000, 240), Color.WHITE)
