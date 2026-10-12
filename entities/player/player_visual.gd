class_name PlayerVisual
extends EntityVisual

var actor: Player

func _draw() -> void:
	if sprite != null:
		return
	if actor.health <= 0:
		draw_circle(Vector2(0, -8), 7, Color("47dacb"))
		return
	if actor.slash_remaining > 0.0:
		var hit_rect: Rect2 = actor.get_attack_rect()
		hit_rect.position -= actor.global_position
		draw_rect(hit_rect, Color(1.0, 0.8, 0.45, 0.65))
	var color: Color = Color.WHITE if actor.invulnerable > 0.0 else Color("47dacb")
	draw_rect(Rect2(-8, -30, 16, 26), color)
	draw_rect(Rect2(-7, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(2, -4, 5, 4), Color("8299a8"))
	draw_rect(Rect2(-6, -27, 12, 8), Color("17283b"))
	draw_line(Vector2(0, -23), Vector2(actor.facing * 7, -23), Color("ffce75"), 3.0)
