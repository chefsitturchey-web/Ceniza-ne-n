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
	if index == 0:
		var anticipation: float = 1 if actor.state == Recaudador.State.CHARGE_WINDUP else 0
		var swing: float = clampf(1 - actor.timer / 0.3, 0, 1) if actor.state == Recaudador.State.CLAW else 0
		var hand: Vector2 = Vector2(-34 - anticipation * 7, 7)
		draw_set_transform(hand, -0.5 - anticipation * 0.5 + sin(swing * PI) * 1.8)
		draw_texture_rect(DepotArt.part(2), Rect2(-5, -5, 10, 36), false, Color("d4b18c"))
		draw_set_transform(Vector2.ZERO)
		if actor.state in [Recaudador.State.CHARGE, Recaudador.State.CLAW]:
			draw_arc(Vector2.ZERO, 49, actor.facing.angle() - 0.8, actor.facing.angle() + 0.8, 24, Color("ffce75", 0.6), 3)
	else:
		# Placas orbitales articuladas y brazos de enlace; el rostro permanece estable.
		for panel: int in range(6):
			var angle: float = actor.elapsed * 0.13 + panel * TAU / 6
			var at: Vector2 = Vector2(cos(angle) * 62, sin(angle) * 39 - 23)
			draw_set_transform(at, angle + PI / 2)
			draw_texture_rect(DepotArt.reactor_shutter(), Rect2(-5, -11, 10, 22), false, Color("95acb1"))
			draw_set_transform(Vector2.ZERO)
		for side: int in [-1, 1]:
			var hand: Vector2 = Vector2(side * (55 + sin(actor.elapsed * 1.7 + side) * 5), -15)
			draw_line(Vector2(side * 25, -7), hand, Color("182639"), 5)
			draw_line(Vector2(side * 25, -7), hand, Color("47dacb", 0.55), 1)
			draw_circle(hand, 3, Color("47dacb"))
	if actor.core_exposed:
		draw_arc(Vector2.ZERO, 19, actor.elapsed * 2, actor.elapsed * 2 + 5, 32, Color("47dacb"), 2)
	elif index == 0:
		draw_arc(Vector2.ZERO, 39, actor.facing.angle() - 0.9, actor.facing.angle() + 0.9, 20, Color("ffce75", 0.5), 2)
	draw_set_transform(Vector2.ZERO)
