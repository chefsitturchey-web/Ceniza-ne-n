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

func prepare_heat() -> void:
	heat_areas.clear()
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
	timer -= delta
	facing = (target.global_position - global_position).normalized()
	match state:
		State.APPROACH:
			if timer <= 0: prepare_heat()
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
			if timer <= 0: change_state(State.APPROACH, 1.3)
	update_puppet(delta)

func update_puppet(_delta: float) -> void:
	puppet.position.y = roundf(sin(elapsed * 2))
	machine.queue_redraw()
	queue_redraw()

func status_text() -> String:
	match state:
		State.CLAW_WINDUP: return "REJILLAS MARCADAS: sal de las franjas antes de que ardan"
		State.CLAW: return "CALOR ACTIVO: busca los corredores sin fuego"
		State.RECOVER: return "PURGA DE ENFRIAMIENTO: núcleo expuesto"
		State.VOLLEY_WINDUP, State.VOLLEY: return "ESCORIA: evita el abanico de proyectiles"
	return "Santa Caldera prepara las rejillas; observa el suelo"

func _draw() -> void:
	if health > 0:
		draw_circle(Vector2(0, 24), 46, Color(0, 0, 0, 0.4))
