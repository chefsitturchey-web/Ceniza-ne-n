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
	MenuFx.juice_button(control)
