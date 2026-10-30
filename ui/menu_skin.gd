class_name MenuSkin
extends RefCounted
static var frame: Texture2D

static func panel() -> StyleBoxTexture:
	if frame == null: frame = load("res://assets/ui/frames/menu_panel.svg")
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = frame
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 24)
		style.set_content_margin(side, 0)
	return style

static func button(control: Button) -> void:
	control.mouse_entered.connect(func() -> void:
		if control.disabled or GamePreferences.current().reduced_flashes: return
		control.create_tween().tween_property(control, "modulate", Color("fff1c9"), 0.12))
	control.mouse_exited.connect(func() -> void:
		control.create_tween().tween_property(control, "modulate", Color.WHITE, 0.2))
