class_name FinalBossVisual
extends Node2D
const ART: Texture2D = preload("res://assets/expedition/boss/final_bosses_v1.png")
var actor: Recaudador
var index: int = 0

func _process(_delta: float) -> void: queue_redraw()

func _draw() -> void:
	if actor.health <= 0: return
	var size: float = 108 if index == 0 else 150
	var bob: float = sin(actor.elapsed * (9 if actor.velocity.length() > 1 else 2)) * 1.5
	draw_set_transform(Vector2(0, bob), sin(actor.elapsed * 3) * 0.025)
	draw_texture_rect_region(ART, Rect2(-size * 0.5, -size * 0.65, size, size), GameArt.region(ART, 2, 1, index), Color(1.3, 1.25, 1.18))
	if actor.core_exposed:
		draw_arc(Vector2.ZERO, 19, actor.elapsed * 2, actor.elapsed * 2 + 5, 32, Color("47dacb"), 2)
	elif index == 0:
		draw_arc(Vector2.ZERO, 39, actor.facing.angle() - 0.9, actor.facing.angle() + 0.9, 20, Color("ffce75", 0.5), 2)
	draw_set_transform(Vector2.ZERO)
