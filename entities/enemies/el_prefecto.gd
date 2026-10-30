class_name ElPrefecto
extends Recaudador
## Duelista móvil: el escudo, la salva y la estocada tienen respuestas distintas.
var visual: FinalBossVisual
var chained_thrust: bool = false

func _init() -> void: max_health = 8000

func build_visual() -> void:
	visual = FinalBossVisual.new()
	visual.actor = self
	puppet.add_child(visual)

func is_core_exposed() -> bool: return state == State.RECOVER

func hit_multiplier(origin: Vector2) -> float:
	if core_exposed: return 2.0
	return 0.0 if facing.dot((origin - global_position).normalized()) > 0.25 else 0.4

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0: return
	elapsed += delta
	tactics.observe(target, delta)
	timer -= delta
	var difference: Vector2 = target.global_position - global_position
	match state:
		State.APPROACH:
			facing = difference.normalized()
			var tangent: Vector2 = facing.orthogonal() * (1 if next_pattern % 2 == 0 else -1)
			var destination: Vector2 = target.global_position - facing * 120 + tangent * 90
			velocity = tactics.steer(self, destination, 125 if phase == 2 else 90)
			move_and_slide()
			if timer <= 0:
				last_decision = tactics.choose({"volley": 10.0 if tactics.clear_shot(self, target.global_position) and difference.length() > 150 else 3.0, "thrust": 9.0 if difference.length() > 95 else 5.0, "sweep": 14.0 if difference.length() < 100 else -8.0}, 4.5)
				charge_direction = (tactics.predicted(target, 0.32) - global_position).normalized()
				facing = charge_direction
				if last_decision == "sweep":
					charges_left = 1
					change_state(State.CLAW_WINDUP, 0.85)
				else: change_state(State.VOLLEY_WINDUP if last_decision == "volley" else State.CHARGE_WINDUP, 1.0)
		State.VOLLEY_WINDUP:
			if timer <= 0:
				volleys = 0
				shot_timer = 0
				change_state(State.VOLLEY, 1.5)
		State.VOLLEY:
			shot_timer -= delta
			if shot_timer <= 0 and volleys < (4 if phase == 2 else 3):
				fire_fan()
				volleys += 1
				shot_timer = 0.35
			if timer <= 0: change_state(State.RECOVER, 2.4)
		State.CHARGE_WINDUP:
			if timer <= 0:
				if not chained_thrust: charges_left = 2 if phase == 2 else 1
				chained_thrust = false
				change_state(State.CHARGE, 0.48)
				cue_requested.emit("dash")
		State.CHARGE:
			var before: Vector2 = global_position
			velocity = charge_direction * 460
			move_and_slide()
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
			if nearest.distance_to(target.global_position) < 40: target.take_damage(24, charge_direction * 160)
			if timer <= 0 or get_slide_collision_count() > 0:
				change_state(State.CLAW_WINDUP, 0.7)
		State.CLAW_WINDUP:
			# El barrido queda fijado al comenzar su aviso, también si esquivas detrás.
			if timer <= 0: change_state(State.CLAW, 0.3)
		State.CLAW:
			if difference.length() < 90 and facing.dot(difference.normalized()) > -0.2: target.take_damage(20, difference.normalized() * 100)
			if timer <= 0:
				charges_left -= 1
				if charges_left > 0:
					charge_direction = difference.normalized()
					facing = charge_direction
					chained_thrust = true
					change_state(State.CHARGE_WINDUP, 0.85)
				else: change_state(State.RECOVER, 3.2)
		State.RECOVER:
			if timer <= 0:
				next_pattern += 1
				change_state(State.APPROACH, 2.0)
	update_puppet(delta)

func update_puppet(_delta: float) -> void:
	visual.queue_redraw()
	queue_redraw()

func status_text() -> String:
	match state:
		State.RECOVER: return "ESCUDO AGOTADO: castiga su recuperación"
		State.CHARGE_WINDUP: return "ESTOCADA: abandona la línea dorada"
		State.CLAW_WINDUP, State.CLAW: return "BARRIDO: sal del círculo de alcance"
		State.VOLLEY_WINDUP, State.VOLLEY: return "SALVA: busca cobertura, su escudo sigue activo"
	return "EL PREFECTO: rodea el escudo y observa sus pies"
