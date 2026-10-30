class_name ClearanceSite
extends Node2D

var frontier: FrontierSystem
var label: String = "Escombros"
var ordered: bool = false
var cleared: bool = false
var progress: float = 0
var duration: float = 20
var required_tier: int = 1
var variant: int = 0
var elapsed: float = 0
var art: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art = load("res://assets/world/props/" + ["car", "scrap", "spool", "crate", "barrel"][variant % 5] + ".png")

func _process(delta: float) -> void:
	elapsed += delta
	if ordered and progress >= duration:
		ordered = false
		cleared = true
		frontier.district.bank.stored_parts += 4
		frontier.district.bank.parts_changed.emit(frontier.district.bank.parts)
		frontier.district.bank.deposit(6)
		frontier.district.presenter.show_notice("Parcela despejada: +4 piezas al depósito y +6 chatarra")
		frontier.district.story.queue_dialogue("expansion")
		frontier.district.expansion.checkpoint()
	visible = not cleared
	if ordered: queue_redraw()

func _draw() -> void:
	var texture: Texture2D = art
	draw_ellipse_shadow()
	for index: int in 3:
		var size: Vector2 = texture.get_size() * (0.8 if index != 1 else 1.15)
		draw_texture_rect(texture, Rect2(Vector2((index - 1) * 20 - size.x / 2, -size.y), size), false, Color("85929c") if index == 1 else Color("53616d"))
	for index: int in 5:
		draw_line(Vector2(-42 + index * 19, -4), Vector2(-28 + index * 17, -15 - index % 3 * 5), Color("8c674d"), 3)
	if variant == 2:
		for index: int in 3:
			var shift: float = sin(elapsed * 2 + index) * 3
			draw_line(Vector2(-40 + shift, 1 + index * 2), Vector2(35 + shift, 1 + index * 2), Color("47dacb", 0.25), 1)
	elif variant == 3:
		draw_rect(Rect2(-6, -39, 12, 7), Color("182639"))
		draw_line(Vector2(-4, -36), Vector2(4, -36), Color("d26b62"), 2)
	elif variant == 4:
		for index: int in 5:
			draw_line(Vector2(-45 + index * 17, -3), Vector2(-28 + index * 17, -10 - index % 2 * 8), Color("47dacb", 0.5), 1)
	if ordered:
		var x: float = -32 + fposmod(elapsed * 35, 64)
		draw_line(Vector2(x, -25), Vector2(x + 4, -31), Color("ffce75"), 2)
		draw_arc(Vector2(0, -46), 7, -PI / 2, -PI / 2 + TAU * clampf(progress / duration, 0, 1), 20, Color("47dacb"), 2)
	else:
		draw_line(Vector2(-38, -18), Vector2(38, -18), Color("d99b54"), 2)
		for index: int in 7: draw_line(Vector2(-36 + index * 11, -21), Vector2(-31 + index * 11, -16), Color("182639"), 2)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.18))
	draw_circle(Vector2.ZERO, 48, Color(0.02, 0.04, 0.07, 0.6))
	draw_set_transform(Vector2.ZERO)
