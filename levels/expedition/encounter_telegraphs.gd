class_name EncounterTelegraphs
extends Node2D

var boss: Recaudador

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(boss) or boss.health <= 0:
		return
	if boss is MadreCero:
		var mother: MadreCero = boss as MadreCero
		for relay: NetworkRelay in mother.relays:
			if relay.health > 0: draw_line(mother.position, relay.position, Color("47dacb", 0.2), 1)
			if mother.guard_time > 0: draw_arc(relay.position, 28, 0, TAU, 32, Color("47dacb"), 2)
		for mark: Dictionary in mother.marks:
			draw_circle(mark.position, 34, Color("dd6482", 0.13))
			draw_arc(mark.position, 34, 0, TAU, 32, Color("ffce75"), 2)
			draw_arc(mark.position, maxf(2, mark.time / 1.5 * 34), 0, TAU, 32, Color("dd6482"), 1)
	elif boss is ElPrefecto:
		if boss.state == Recaudador.State.CHARGE_WINDUP:
			draw_line(boss.position, boss.position + boss.charge_direction * 240, Color("ffce75", 0.7), 16)
		elif boss.state in [Recaudador.State.CLAW_WINDUP, Recaudador.State.CLAW]:
			draw_circle(boss.position, 90, Color("dd6482", 0.12))
			draw_arc(boss.position, 90, 0, TAU, 48, Color("ffce75"), 2)
	elif boss is SantaCaldera:
		var boiler: SantaCaldera = boss as SantaCaldera
		var active: bool = boiler.state == Recaudador.State.CLAW
		if boiler.state == Recaudador.State.CHARGE_WINDUP:
			var side: Vector2 = boiler.charge_direction.orthogonal() * 28
			var end: Vector2 = boiler.position + boiler.charge_direction * 260
			draw_colored_polygon(PackedVector2Array([boiler.position + side, end + side, end - side, boiler.position - side]), Color("dd6482", 0.22))
			draw_line(boiler.position, end, Color("ffce75"), 2)
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
