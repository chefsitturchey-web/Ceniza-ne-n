class_name SettlementSupport
extends Node2D

var system: SettlementSystem
var kind: int = 0
var tier: int = 0
var ordered: bool = false
var progress: float = 0
var elapsed: float = 0
var art: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art = load("res://assets/world/settlements/supports.png")

func duration() -> float: return 30.0 if tier == 0 else 45.0

func tick(delta: float) -> void:
	elapsed += delta
	if ordered and progress >= duration():
		tier += 1
		ordered = false
		progress = 0
		system.refresh_bonuses()
		system.world.sound.play_cue("upgrade", -10)
		system.world.presenter.show_notice(system.SPECS[kind].title + " recuperado · " + system.effect(kind, tier))
		system.world.expansion.checkpoint()
	queue_redraw()

func _draw() -> void:
	var frame: int = kind * 2 + maxi(0, tier - 1)
	var tint: Color = Color.WHITE if tier > 0 else Color("687782")
	draw_texture_rect_region(art, Rect2(-48, -91, 96, 96), Rect2(frame * 96, 0, 96, 96), tint)
	if tier == 0:
		draw_line(Vector2(-40, -19), Vector2(40, -19), Color("b18a54"), 2)
		for index: int in 7: draw_line(Vector2(-36 + index * 11, -21), Vector2(-31 + index * 11, -17), Color("182639"), 2)
	else:
		var color: Color = [Color("ffce75"), Color("d58665"), Color("47dacb")][kind]
		draw_circle(Vector2(-29, -48), 9, Color(color, 0.08 + sin(elapsed * 2) * 0.02))
		for index: int in tier: draw_rect(Rect2(29 + index * 4, -24, 2, 4), color)
		if kind == 0:
			var direction: Vector2 = Vector2.from_angle(elapsed * 2) * 5
			draw_line(Vector2(20, -30) - direction, Vector2(20, -30) + direction, color, 1)
		elif kind == 2:
			draw_set_transform(Vector2(0, 3), 0, Vector2(1, 0.12))
			draw_arc(Vector2.ZERO, 260, 0, TAU, 64, Color("47dacb", 0.09), 2)
			draw_set_transform(Vector2.ZERO)
	if ordered:
		for side: int in [-1, 1]: draw_line(Vector2(side * 45, 0), Vector2(side * 45, -82), Color("8299a8"), 2)
		draw_arc(Vector2(0, -89), 6, -PI / 2, -PI / 2 + TAU * clampf(progress / duration(), 0, 1), 18, Color("47dacb"), 2)
