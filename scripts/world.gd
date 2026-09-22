extends Node2D
## Escenario provisional construido con formas, sin assets externos.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const TRAINING_ENEMY: Script = preload("res://scripts/training_enemy.gd")
const FLOOR_Y: float = 260.0

func _ready() -> void:
	configure_input()
	add_solid(Vector2(0, FLOOR_Y + 20), Vector2(1920, 40))
	add_solid(Vector2(-968, 100), Vector2(16, 400))
	add_solid(Vector2(968, 100), Vector2(16, 400))
	var player: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	player.position = Vector2(0, FLOOR_Y)
	add_child(player)
	var enemy := Node2D.new()
	enemy.set_script(TRAINING_ENEMY)
	enemy.position = Vector2(150, FLOOR_Y)
	add_child(enemy)
	create_hud()

func configure_input() -> void:
	add_movement_action("move_left", KEY_A, KEY_LEFT, -1.0, JOY_BUTTON_DPAD_LEFT)
	add_movement_action("move_right", KEY_D, KEY_RIGHT, 1.0, JOY_BUTTON_DPAD_RIGHT)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var key := InputEventKey.new()
		key.physical_keycode = KEY_J
		InputMap.action_add_event("attack", key)
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_X
		InputMap.action_add_event("attack", button)

func add_movement_action(action: StringName, letter: Key, arrow: Key, axis_value: float, button: JoyButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	for keycode in [letter, arrow]:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(action, key_event)
	var axis_event := InputEventJoypadMotion.new()
	axis_event.axis = JOY_AXIS_LEFT_X
	axis_event.axis_value = axis_value
	InputMap.action_add_event(action, axis_event)
	var button_event := InputEventJoypadButton.new()
	button_event.button_index = button
	InputMap.action_add_event(action, button_event)

func add_solid(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 14)
	label.text = "CENIZA NEÓN · Práctica de combate\nMover: A / D o flechas · Mando: stick o cruceta\nAtacar: J / X (Xbox) / Cuadrado (PS) · Detener: F8"
	layer.add_child(label)

func _draw() -> void:
	for index in range(24):
		var x: float = -960.0 + index * 80.0
		var height: float = 60.0 + float((index * 37) % 95)
		draw_rect(Rect2(x, FLOOR_Y - height, 55, height), Color("111c2d"))
		draw_rect(Rect2(x + 12, FLOOR_Y - height + 12, 4, 16), Color("26495d"))
	draw_rect(Rect2(-960, FLOOR_Y, 1920, 80), Color("202c39"))
	draw_line(Vector2(-960, FLOOR_Y), Vector2(960, FLOOR_Y), Color("4c8591"), 2.0)
	# Referencia visual del futuro núcleo; todavía no es un edificio interactivo.
	draw_rect(Rect2(-30, FLOOR_Y - 65, 60, 65), Color("304356"))
	draw_rect(Rect2(-14, FLOOR_Y - 52, 28, 32), Color("e89e54"))
	for x in [-400.0, 400.0]:
		draw_line(Vector2(x, FLOOR_Y), Vector2(x, FLOOR_Y - 45), Color("b075ae"), 3.0)
