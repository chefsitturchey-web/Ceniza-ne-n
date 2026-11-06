class_name ElPrefecto
extends Recaudador
## Duelista móvil: el escudo, la salva y la estocada tienen respuestas distintas.
## Lee al jugador: contraataca golpes al escudo, retrasa estocadas contra quien esquiva
## por anticipado, corrige el rumbo a mitad de carga y en su última guardia encadena tres.
var chained_thrust: bool = false
## Última guardia (30 % de vida): más rápido, ventanas más cortas y tres estocadas.
var last_guard: bool = false
var riposte_cooldown: float = 0
var flank_timer: float = 0

func _init() -> void: max_health = 14000

## El cuerpo es el flipbook cuadro por cuadro (CombatFlipbook); no hay marioneta ni imagen fija superpuesta.
func build_visual() -> void: pass

func is_core_exposed() -> bool: return state == State.RECOVER

func hit_multiplier(origin: Vector2) -> float:
	if core_exposed: return 2.0
	return 0.0 if facing.dot((origin - global_position).normalized()) > 0.25 else 0.3

## Ventana de castigo: se acorta en fase 2 y más aún en la última guardia.
func recovery(base: float) -> float:
	return base * (0.65 if last_guard else (0.85 if phase == 2 else 1.0))

## Golpear el escudo frontal provoca un contraataque inmediato, como un parry.
func receive_hit(origin: Vector2, amount: int) -> int:
	var dealt: int = super.receive_hit(origin, amount)
	if health > 0 and not last_guard and health <= max_health * 0.3:
		last_guard = true
		cue_requested.emit("alarm")
		phase_changed.emit(phase)
	if dealt == 0 and health > 0 and target != null and riposte_cooldown <= 0 and state == State.APPROACH:
		riposte_cooldown = 4.0 if phase == 2 else 6.0
		charges_left = 1
		facing = (target.global_position - global_position).normalized()
		last_decision = "riposte"
		change_state(State.CLAW_WINDUP, 0.35)
	return dealt

## Retraso variable de la estocada: castiga las esquivas anticipadas.
func thrust_windup() -> float:
	if tactics.dodge_happy() and phase == 2: return 1.35 if tactics.decisions % 2 == 0 else 0.6
	return 1.0 if phase == 1 else 0.85

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0: return
	elapsed += delta
	tactics.observe(target, delta)
	tactics.track_cover(self, target, delta)
	riposte_cooldown = maxf(0, riposte_cooldown - delta)
	timer -= delta
	var difference: Vector2 = target.global_position - global_position
	match state:
		State.APPROACH:
			facing = difference.normalized()
			# Rodea al jugador y, si se esconde, flanquea la cobertura en lugar de esperar.
			flank_timer += delta
			var side: float = 1.0 if int(flank_timer / 2.5) % 2 == 0 else -1.0
			var tangent: Vector2 = facing.orthogonal() * side * (160.0 if tactics.hidden_time > 1.2 else 90.0)
			var destination: Vector2 = target.global_position - facing * 120 + tangent
			velocity = tactics.steer(self, destination, 175 if last_guard else (155 if phase == 2 else 110))
			move_and_slide()
			if timer <= 0:
				var visible: bool = tactics.clear_shot(self, target.global_position)
				var stationary: bool = tactics.stationary_time > 1.0
				last_decision = tactics.choose({
					"volley": (12.0 if stationary else 10.0) if visible and difference.length() > 150 else 3.0,
					"thrust": 13.0 if tactics.hidden_time > 1.2 else (9.0 if difference.length() > 95 else 5.0),
					"sweep": 14.0 if difference.length() < 100 else -8.0}, 3.5 if last_guard else 4.5)
				charge_direction = (tactics.predicted(target, 0.32) - global_position).normalized()
				facing = charge_direction
				if last_decision == "sweep":
					charges_left = 1
					change_state(State.CLAW_WINDUP, 0.7 if phase == 2 else 0.85)
				elif last_decision == "volley": change_state(State.VOLLEY_WINDUP, 0.85 if phase == 2 else 1.0)
				else: change_state(State.CHARGE_WINDUP, thrust_windup())
		State.VOLLEY_WINDUP:
			if timer <= 0:
				volleys = 0
				shot_timer = 0
				change_state(State.VOLLEY, 1.5)
		State.VOLLEY:
			shot_timer -= delta
			facing = Vector2.from_angle(rotate_toward(facing.angle(), difference.angle(), 1.6 * delta))
			if shot_timer <= 0 and volleys < (5 if last_guard else (4 if phase == 2 else 3)):
				fire_fan()
				volleys += 1
				shot_timer = 0.3 if last_guard else 0.35
			if timer <= 0: change_state(State.RECOVER, recovery(1.4))
		State.CHARGE_WINDUP:
			# Encara al jugador mientras carga para que moverse pronto no baste.
			charge_direction = Vector2.from_angle(rotate_toward(charge_direction.angle(), (tactics.predicted(target, 0.3) - global_position).angle(), 2.4 * delta))
			facing = charge_direction
			if timer <= 0:
				if not chained_thrust: charges_left = 3 if last_guard else (2 if phase == 2 else 1)
				chained_thrust = false
				change_state(State.CHARGE, 0.48)
		State.CHARGE:
			var before: Vector2 = global_position
			if phase == 2:
				charge_direction = Vector2.from_angle(rotate_toward(charge_direction.angle(), difference.angle(), 1.2 * delta))
				facing = charge_direction
			velocity = charge_direction * (500 if last_guard else 460)
			move_and_slide()
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, before, global_position)
			if nearest.distance_to(target.global_position) < 46: target.take_damage(28 if last_guard else 24, charge_direction * 160)
			for index: int in get_slide_collision_count():
				var cover: ArenaCover = get_slide_collision(index).get_collider() as ArenaCover
				if cover != null: cover.receive_damage(120)
			if timer <= 0 or get_slide_collision_count() > 0:
				change_state(State.CLAW_WINDUP, 0.55 if phase == 2 else 0.7)
		State.CLAW_WINDUP:
			# El barrido queda fijado al comenzar su aviso, también si esquivas detrás.
			if timer <= 0: change_state(State.CLAW, 0.3)
		State.CLAW:
			if difference.length() < melee_reach() and facing.dot(difference.normalized()) > -0.2: target.take_damage(22 if last_guard else 20, difference.normalized() * 100)
			if timer <= 0:
				charges_left -= 1
				if charges_left > 0:
					charge_direction = difference.normalized()
					facing = charge_direction
					chained_thrust = true
					change_state(State.CHARGE_WINDUP, 0.6 if last_guard else 0.85)
				elif last_decision == "riposte": change_state(State.APPROACH, 0.8)
				else: change_state(State.RECOVER, recovery(1.8))
		State.RECOVER:
			if timer <= 0:
				next_pattern += 1
				change_state(State.APPROACH, 0.9 if last_guard else 1.25)
	update_puppet(delta)

func update_puppet(_delta: float) -> void:
	queue_redraw()

func status_text() -> String:
	match state:
		State.RECOVER: return "ESCUDO AGOTADO: castiga su recuperación"
		State.CHARGE_WINDUP: return "ESTOCADA: abandona la línea dorada; puede retrasarla"
		State.CLAW_WINDUP, State.CLAW: return "CONTRAATAQUE: no golpees su escudo" if last_decision == "riposte" else "BARRIDO: sal del círculo de alcance"
		State.VOLLEY_WINDUP, State.VOLLEY: return "SALVA: busca cobertura, su escudo sigue activo"
	return "ÚLTIMA GUARDIA: tres estocadas seguidas" if last_guard else "EL PREFECTO: rodea el escudo y observa sus pies"
