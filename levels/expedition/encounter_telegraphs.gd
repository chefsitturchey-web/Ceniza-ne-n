class_name EncounterTelegraphs
extends Node2D

var boss: Recaudador

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(boss) or boss.health <= 0:
		return
	if boss is SantaCaldera:
		var boiler: SantaCaldera = boss as SantaCaldera
		var active: bool = boiler.state == Recaudador.State.CLAW
		for area: Rect2 in boiler.heat_areas:
			draw_rect(area, Color(1, 0.36, 0.12, 0.36 if active else 0.08))
			draw_rect(area, Color("e89e54") if active else Color("ffce75"), false, 2)
			var center: Vector2 = area.get_center()
			draw_line(center - Vector2(9, 9), center + Vector2(9, 9), Color("ffce75"), 2)
			draw_line(center + Vector2(-9, 9), center + Vector2(9, -9), Color("ffce75"), 2)
	elif boss is CoroSumergido:
		var choir: CoroSumergido = boss as CoroSumergido
		for relay: ChoirRelay in choir.relays:
			if relay.health > 0:
				draw_line(choir.position, relay.global_position, Color("dd6482", 0.45), 2)
		for wave: Dictionary in choir.waves:
			draw_arc(choir.position, wave.radius, 0, TAU, 80, Color("dd6482", 0.85), 2)
		for mark: Dictionary in choir.marks:
			draw_circle(mark.position, 25, Color("dd6482", 0.5 if mark.time <= 0 else 0.12))
			draw_arc(mark.position, 25, 0, TAU, 24, Color("ffce75") if mark.time > 0 else Color("dd6482"), 1)
			draw_line(mark.position - Vector2(6, 0), mark.position + Vector2(6, 0), Color("dd6482"), 1)
