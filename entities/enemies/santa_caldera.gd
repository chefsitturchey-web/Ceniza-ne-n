class_name SantaCaldera
extends Recaudador

var heat_areas: Array[Rect2] = []
var pattern: int = 0
var heat_tick: float = 0.0
var machine: BossMachineVisual

func _init() -> void:
	max_health = 8500

func build_visual() -> void:
	machine = BossMachineVisual.new()
	machine.actor = self
	machine.kind = "caldera"
	puppet.add_child(machine)

func is_core_exposed() -> bool:
	return state == State.RECOVER

func clear_hazards() -> void:
	heat_areas.clear()

func hit_multiplier(_origin: Vector2) -> float:
	return 2.0 if core_exposed else 0.35

func prepare_heat(adaptive: bool = false) -> void:
	heat_areas.clear()
	if adaptive:
		pattern = 0 if absf(tactics.observed_velocity.x) > absf(tactics.observed_velocity.y) else 1
	if pattern % 2 == 0:
		for x: float in [95.0, 290.0, 485.0]:
			heat_areas.append(Rect2(x, 70, 70 if phase == 1 else 90, 360))
	else:
		for y: float in [85.0, 215.0, 345.0]:
			heat_areas.append(Rect2(45, y, 550, 50 if phase == 1 else 65))
	pattern += 1
	change_state(State.CLAW_WINDUP, 1.2 if phase == 1 else 0.95)

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0:
		return
	elapsed += delta
	tactics.observe(target, delta)
	timer -= delta
	facing = (target.global_position - global_position).normalized()
	match state:
		State.APPROACH:
			var offset: Vector2 = Vector2.from_angle(elapsed * 0.35 + pattern) * 130
			var destination: Vector2 = (target.global_position + offset).clamp(Vector2(90, 95), Vector2(550, 385))
			velocity = tactics.steer(self, destination, 85 if phase == 2 else 65)
			move_and_slide()
			if timer <= 0:
				last_decision = tactics.choose({"heat": 9.0 + tactics.stationary_time, "charge": 12.0 if facing.dot(tactics.observed_velocity.normalized()) < -0.5 else 5.0, "volley": 10.0 if global_position.distance_to(target.global_position) > 210 else 4.0}, 7)
				match last_decision:
					"charge":
						charges_left = 2 if phase == 2 else 1
						charge_direction = (tactics.predicted(target) - global_position).normalized()
						change_state(State.CHARGE_WINDUP, 1.1)
					"volley": change_state(State.VOLLEY_WINDUP, 0.9)
					_: prepare_heat(true)
		State.CLAW_WINDUP:
			if timer <= 0:
				heat_tick = 0
				change_state(State.CLAW, 2.6)
		State.CLAW:
			heat_tick -= delta
			if heat_tick <= 0:
				heat_tick = 0.35
				for area: Rect2 in heat_areas:
					if area.has_point(target.global_position):
						target.take_damage(18)
			if timer <= 0:
				heat_areas.clear()
				change_state(State.RECOVER, 4.0)
		State.RECOVER:
			if timer <= 0: change_state(State.VOLLEY_WINDUP, 0.8)
		State.VOLLEY_WINDUP:
			if timer <= 0:
				volleys = 0
				shot_timer = 0
				change_state(State.VOLLEY, 1.6)
		State.VOLLEY:
			shot_timer -= delta
			if shot_timer <= 0 and volleys < 3:
				fire_fan()
				volleys += 1
				shot_timer = 0.45
			if timer <= 0:
				charges_left = 2 if phase == 2 else 1
				charge_direction = (target.global_position - global_position).normalized()
				change_state(State.CHARGE_WINDUP, 1.1)
		State.CHARGE_WINDUP:
			if timer <= 0:
				change_state(State.CHARGE, 0.7)
				cue_requested.emit("dash_caldera")
		State.CHARGE:
			velocity = charge_direction * (390 if phase == 2 else 330)
			move_and_slide()
			if global_position.distance_to(target.global_position) < 55:
				target.take_damage(22, charge_direction * 150)
			if timer <= 0 or get_slide_collision_count() > 0:
				effects.emit_pixels(global_position, 15, Color("ffce75"))
				charges_left -= 1
				if charges_left > 0:
					charge_direction = (target.global_position - global_position).normalized()
					change_state(State.CHARGE_WINDUP, 0.8)
				else: change_state(State.APPROACH, 1.8)
	update_puppet(delta)

func update_puppet(delta: float) -> void:
	puppet.position.y = roundf(sin(elapsed * 2))
	puppet.rotation = lerp_angle(puppet.rotation, facing.angle() - PI / 2, minf(1, delta * 2))
	machine.queue_redraw()
	queue_redraw()

func status_text() -> String:
	match state:
		State.CLAW_WINDUP: return "REJILLAS MARCADAS: sal de las franjas antes de que ardan"
		State.CLAW: return "CALOR ACTIVO: busca los corredores sin fuego"
		State.RECOVER: return "PURGA DE ENFRIAMIENTO: núcleo expuesto"
		State.VOLLEY_WINDUP, State.VOLLEY: return "ESCORIA: evita el abanico de proyectiles"
		State.CHARGE_WINDUP: return "ARREMETIDA: sal del corredor marcado"
		State.CHARGE: return "¡APÁRTATE! La Caldera atraviesa la plataforma"
	return "Santa Caldera prepara las rejillas; observa el suelo"

func _draw() -> void:
	if health > 0:
		draw_circle(Vector2(0, 24), 46, Color(0, 0, 0, 0.4))
