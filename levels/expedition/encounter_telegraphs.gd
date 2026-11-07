class_name EncounterTelegraphs
extends Node2D
var boss: Recaudador

var clock: float = 0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

## Brillo de aviso de los jefes finales: halo ancho que late y se vuelve más rápido al final.
## Con destellos reducidos el halo queda fijo.
func glow(remaining: float) -> float:
	if GamePreferences.current().reduced_flashes: return 0.5
	var urgency: float = 1.0 - clampf(remaining / 0.9, 0, 1)
	return 0.35 + 0.65 * absf(sin(clock * lerpf(6, 22, urgency)))

func rune(point: Vector2, radius: float, time: float, maximum: float, color: Color) -> void:
	draw_circle(point, radius, Color(color, 0.08))
	for index: int in 8:
		var angle: float = index * TAU / 8
		draw_arc(point, radius, angle, angle + 0.5, 8, Color(color, 0.85), 2)
		var direction: Vector2 = Vector2.from_angle(angle)
		draw_line(point + direction * (radius - 5), point + direction * radius, color, 2)
	draw_arc(point, maxf(2, radius * clampf(time / maximum, 0, 1)), 0, TAU, 40, Color(color, 0.45), 1)
	var diamond: PackedVector2Array = PackedVector2Array([point + Vector2(0, -5), point + Vector2(4, 0), point + Vector2(0, 5), point - Vector2(4, 0), point + Vector2(0, -5)])
	draw_polyline(diamond, color, 1)

func corridor(origin: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	var end: Vector2 = origin + direction * length
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, end, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty(): end = hit.position
	draw_colored_polygon(PackedVector2Array([origin - normal * width, end - normal * width, end + normal * width, origin + normal * width]), Color(color, 0.09))
	for side: int in [-1, 1]: draw_line(origin + normal * width * side, end + normal * width * side, Color(color, 0.75), 2)
	var count: int = maxi(1, int(origin.distance_to(end) / 32))
	for index: int in count:
		var point: Vector2 = origin.lerp(end, (index + 0.5) / count)
		draw_polyline(PackedVector2Array([point - direction * 7 - normal * 6, point, point - direction * 7 + normal * 6]), Color(color, 0.8), 2)

func corridor_glow(origin: Vector2, direction: Vector2, length: float, width: float, color: Color, strength: float) -> void:
	var normal: Vector2 = direction.orthogonal()
	var end: Vector2 = origin + direction * length
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin, end, 1))
	if not hit.is_empty(): end = hit.position
	for side: int in [-1, 1]: draw_line(origin + normal * (width + 3) * side, end + normal * (width + 3) * side, Color(color, 0.35 * strength), 6)
	draw_line(origin, end, Color(color, 0.18 * strength), 4)

func sweep_warning(radius: float, span: float, color: Color) -> void:
	var start: float = boss.facing.angle() - span * 0.5
	var polygon: PackedVector2Array = PackedVector2Array([boss.position])
	for index: int in 33: polygon.append(boss.position + Vector2.from_angle(start + span * index / 32.0) * radius)
	draw_colored_polygon(polygon, Color(color, 0.10))
	draw_arc(boss.position, radius, start, start + span, 48, Color(color, 0.8), 2)
	for side: int in [-1, 1]:
		var direction: Vector2 = boss.facing.rotated(span * 0.5 * side)
		draw_line(boss.position + direction * 32, boss.position + direction * radius, Color(color, 0.6), 1)

func heat(area: Rect2, active: bool) -> void:
	draw_rect(area, Color("db5030", 0.25 if active else 0.07))
	draw_rect(area, Color("f2a45f", 0.8), false, 2)
	var horizontal: bool = area.size.x > area.size.y
	var count: int = int((area.size.x if horizontal else area.size.y) / 23)
	for index: int in count:
		var point: Vector2 = area.position + (Vector2((index + 0.5) * area.size.x / count, area.size.y / 2) if horizontal else Vector2(area.size.x / 2, (index + 0.5) * area.size.y / count))
		if active:
			var height: float = 14 + sin(boss.elapsed * 13 + index * 2.3) * 6
			draw_colored_polygon(PackedVector2Array([point + Vector2(-9, 4), point + Vector2(-6, -height * 0.5), point + Vector2(-2, -height), point + Vector2(2, -height * 0.5), point + Vector2(6, -height * 1.3), point + Vector2(9, 4)]), Color("f18b3f", 0.8))
			draw_colored_polygon(PackedVector2Array([point + Vector2(-5, 3), point + Vector2(0, -height * 0.65), point + Vector2(5, 3)]), Color("fbe1a1", 0.9))
		else:
			draw_line(point - Vector2(5, 3), point + Vector2(5, 3), Color("e1ae7a", 0.7), 2)
			draw_line(point - Vector2(5, -3), point + Vector2(5, -3), Color("e1ae7a", 0.7), 2)

## Golpes cuerpo a cuerpo: rojo propio y forma exacta del daño, que se llena hasta el impacto.
func melee_warning() -> void:
	var move: Dictionary = boss.melee
	var color: Color = Color("ff5a4a")
	var winding: bool = boss.melee_winding()
	var progress: float = boss.melee_progress() if winding else 1.0
	var strength: float = glow(float(move.time)) if winding else 1.0
	var direction: Vector2 = move.direction
	var reach: float = float(move.reach)
	match String(move.kind):
		"swing":
			var arc: float = float(move.arc)
			var start: float = direction.angle() - arc
			var outer: PackedVector2Array = PackedVector2Array([boss.position])
			var inner: PackedVector2Array = PackedVector2Array([boss.position])
			for index: int in 33:
				var ray: Vector2 = Vector2.from_angle(start + arc * 2 * index / 32.0)
				outer.append(boss.position + ray * reach)
				inner.append(boss.position + ray * maxf(2, reach * progress))
			draw_colored_polygon(outer, Color(color, 0.1 if winding else 0.3))
			draw_colored_polygon(inner, Color(color, 0.16))
			draw_arc(boss.position, reach + 3, start, start + arc * 2, 48, Color(color, 0.35 * strength), 6)
			draw_arc(boss.position, reach, start, start + arc * 2, 48, Color(color, 0.9), 2)
			for side: int in [-1, 1]:
				draw_line(boss.position + direction.rotated(arc * side) * 26, boss.position + direction.rotated(arc * side) * reach, Color(color, 0.7), 1)
		"slam", "shove":
			draw_circle(boss.position, reach, Color(color, 0.08 + (0.14 * progress if winding else 0.25)))
			draw_arc(boss.position, reach + 3, 0, TAU, 64, Color(color, 0.35 * strength), 6)
			draw_arc(boss.position, reach, 0, TAU, 64, Color(color, 0.9), 2)
			draw_arc(boss.position, maxf(2, reach * progress), 0, TAU, 64, Color(color, 0.55), 2)
		"lunge":
			if winding:
				corridor_glow(boss.position, direction, float(move.travel) + 30, reach, color, strength)
				corridor(boss.position, direction, float(move.travel) + 30, reach, color)

func _draw() -> void:
	if not is_instance_valid(boss) or boss.health <= 0: return
	if boss.melee_active(): melee_warning()
	if boss is MadreCero:
		var mother: MadreCero = boss as MadreCero
		for relay: NetworkRelay in mother.relays:
			if relay.health > 0: draw_line(mother.position, relay.position, Color("47dacb", 0.2), 1)
			if mother.guard_time > 0: rune(relay.position, 28, mother.guard_time, 4, Color("47dacb"))
		for mark: Dictionary in mother.marks:
			var strength: float = glow(mark.time)
			draw_circle(mark.position, 42, Color("ed4fa0", 0.06 + 0.14 * (1.0 - clampf(mark.time / 1.5, 0, 1))))
			draw_arc(mark.position, 46, 0, TAU, 48, Color("e888b0", 0.35 * strength), 6)
			rune(mark.position, 42, mark.time, 1.5, Color("e888b0"))
	elif boss is CoroSumergido:
		var choir: CoroSumergido = boss as CoroSumergido
		for relay: ChoirRelay in choir.relays:
			if relay.health > 0: draw_line(choir.position, relay.global_position, Color("6ab9d0", 0.3), 2)
		for wave: Dictionary in choir.waves:
			var origin: Vector2 = wave.get("origin", choir.position)
			var gap: float = float(wave.get("gap", -PI))
			# Width 18 matches the damaging +/-9 annulus and the exact safe gap.
			draw_arc(origin, wave.radius, gap + 0.3, gap + TAU - 0.3, 100, Color("409cb2", 0.22), 18)
			draw_arc(origin, wave.radius, gap + 0.3, gap + TAU - 0.3, 100, Color("83e7e0", 0.7), 3)
			for index: int in 32:
				var angle: float = gap + 0.3 + index / 31.0 * (TAU - 0.6)
				var point: Vector2 = origin + Vector2.from_angle(angle) * wave.radius
				draw_line(point - Vector2.from_angle(angle) * 6, point + Vector2.from_angle(angle) * 6, Color("ade8e5", 0.4), 1)
			for side: int in [-1, 1]:
				var point: Vector2 = origin + Vector2.from_angle(gap + side * 0.3) * wave.radius
				draw_colored_polygon(PackedVector2Array([point + Vector2(0, -4), point + Vector2(4, 0), point + Vector2(0, 4), point - Vector2(4, 0)]), Color("77f1cd"))
		for mark: Dictionary in choir.marks:
			if mark.time > 0: rune(mark.position, 32, mark.time, 0.9, Color("76d4db"))
	elif boss is SantaCaldera:
		var boiler: SantaCaldera = boss as SantaCaldera
		if boiler.state == Recaudador.State.CHARGE_WINDUP: corridor(boss.position, boss.charge_direction, 400, 64, Color("efab72"))
		for area: Rect2 in boiler.heat_areas: heat(area, boiler.state == Recaudador.State.CLAW)
	else:
		var prefect: bool = boss is ElPrefecto
		var color: Color = Color("9dc9f0") if prefect else Color("ecc087")
		if boss.state == Recaudador.State.CHARGE_WINDUP:
			if prefect: corridor_glow(boss.position, boss.charge_direction, 520, 46, color, glow(boss.timer))
			corridor(boss.position, boss.charge_direction, 520, 46 if prefect else 52, color)
		elif boss.state == Recaudador.State.CLAW_WINDUP:
			if prefect:
				var start: float = boss.facing.angle() - 1.77
				draw_arc(boss.position, boss.melee_reach() + 3, start, start + 3.54, 48, Color(color, 0.35 * glow(boss.timer)), 7)
			sweep_warning(boss.melee_reach(), 3.54 if prefect else 3.42, color)
		elif boss.state == Recaudador.State.VOLLEY_WINDUP:
			for index: int in (7 if boss.phase == 2 else 5):
				var direction: Vector2 = boss.facing.rotated((index - (3 if boss.phase == 2 else 2)) * 0.19)
				var point: Vector2 = boss.position + direction * 66
				draw_polyline(PackedVector2Array([point - direction * 8 - direction.orthogonal() * 3, point, point - direction * 8 + direction.orthogonal() * 3]), color, 2)
