class_name InputSetup
extends RefCounted

static func configure_input() -> void:
	if not InputMap.has_action("mount"): add_action("mount", KEY_V, JOY_BUTTON_LEFT_STICK)
	if not InputMap.has_action("toggle_power"): add_action("toggle_power", KEY_T, JOY_BUTTON_B)
	if not InputMap.has_action("escort"): add_action("escort", KEY_F, JOY_BUTTON_DPAD_UP)
	add_action("move_left", KEY_A, JOY_BUTTON_DPAD_LEFT)
	add_action("move_right", KEY_D, JOY_BUTTON_DPAD_RIGHT)
	for entry: Array in [["move_left", KEY_LEFT, -1.0], ["move_right", KEY_RIGHT, 1.0]]:
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], key)
		var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = entry[2]
		InputMap.action_add_event(entry[0], axis)
	add_action("attack", KEY_J, JOY_BUTTON_X)
	add_action("dodge", KEY_SPACE, JOY_BUTTON_A)
	add_action("sprint", KEY_SHIFT, JOY_BUTTON_DPAD_DOWN)
	add_action("interact", KEY_E, JOY_BUTTON_Y)
	add_action("overload", KEY_Q, JOY_BUTTON_LEFT_SHOULDER)
	add_action("pause", KEY_ESCAPE, JOY_BUTTON_START)
	add_action("restart", KEY_R, JOY_BUTTON_BACK)

static func add_action(action: StringName, keycode: Key, button: JoyButton) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.2)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = keycode
	InputMap.action_add_event(action, key)
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = button
	InputMap.action_add_event(action, pad)
