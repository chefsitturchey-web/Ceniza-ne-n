class_name MadreCero
extends Recaudador
## El enlace se abre protegiendo infraestructura, no golpeando un escudo inmóvil.
var relays: Array[NetworkRelay] = []
var marks: Array[Dictionary] = []
var charge: float = 0
var exposure: float = 0
var pulse: float = 2
var guard_time: float = 0
var guard_cooldown: float = 0
var support_units: int = 0
var visual: FinalBossVisual
var pulse_index: int = 0

func _init() -> void: max_health = 10000

func build_visual() -> void:
	visual = FinalBossVisual.new()
	visual.actor = self
	visual.index = 1
	puppet.add_child(visual)

func install_relays(parent: Node2D) -> void:
	for point: Vector2 in [Vector2(145, 135), Vector2(495, 135), Vector2(320, 345)]:
		var relay: NetworkRelay = NetworkRelay.new()
		relay.position = point
		parent.add_child(relay)
		relays.append(relay)

func active_relays() -> int:
	var result: int = 0
	for relay: NetworkRelay in relays:
		if relay.health > 0: result += 1
	return result

func is_core_exposed() -> bool: return exposure > 0

func hit_multiplier(_origin: Vector2) -> float: return 2.0 if core_exposed else 0.0

func clear_hazards() -> void: marks.clear()

func repair_nearest() -> bool:
	if target == null or target.stamina < 25: return false
	var nearest: NetworkRelay
	var distance: float = 65
	for relay: NetworkRelay in relays:
		var separation: float = relay.global_position.distance_to(target.global_position)
		if relay.health < 120 and separation < distance:
			nearest = relay
			distance = separation
	if nearest == null: return false
	target.stamina -= 25
	nearest.health = mini(120, nearest.health + 45)
	cue_requested.emit("upgrade")
	return true

func overload_relays() -> bool:
	if target == null or target.stamina < 35 or guard_cooldown > 0: return false
	target.stamina -= 35
	guard_time = 4
	guard_cooldown = 12
	cue_requested.emit("upgrade")
	return true

func _physics_process(delta: float) -> void:
	if health <= 0 or target == null or target.health <= 0: return
	elapsed += delta
	guard_time = maxf(0, guard_time - delta)
	guard_cooldown = maxf(0, guard_cooldown - delta)
	if Input.is_action_just_pressed("interact"): repair_nearest()
	if Input.is_action_just_pressed("overload"): overload_relays()
	facing = (target.global_position - global_position).normalized()
	var destination: Vector2 = Vector2(320, 215) + Vector2.from_angle(elapsed * 0.3) * 85
	velocity = (destination - global_position).limit_length(45)
	move_and_slide()
	if exposure > 0:
		exposure = maxf(0, exposure - delta)
		state = State.RECOVER
	else:
		state = State.APPROACH
		if active_relays() >= 2: charge += delta * (1.15 if support_units >= 4 else 1.0)
		if charge >= 18:
			charge = 0
			exposure = 7
			marks.clear()
			cue_requested.emit("upgrade")
		pulse -= delta
		if pulse <= 0 and not relays.is_empty():
			var index: int = pulse_index % relays.size()
			marks.append({"position": relays[index].global_position, "time": 1.5, "relay": index})
			if phase == 2: marks.append({"position": target.global_position, "time": 1.3, "relay": -1})
			pulse_index += 1
			pulse = 2.1 if phase == 2 else 3.0
			cue_requested.emit("alarm")
	for index: int in range(marks.size() - 1, -1, -1):
		marks[index].time -= delta
		if marks[index].time > 0: continue
		var mark: Dictionary = marks[index]
		if mark.position.distance_to(target.global_position) < 34: target.take_damage(18)
		if mark.relay >= 0:
			var damage: int = 0 if guard_time > 0 else (14 if support_units > 0 else 24)
			relays[mark.relay].health = maxi(0, relays[mark.relay].health - damage)
		effects.emit_pixels(mark.position, 10, Color("dd6482"))
		marks.remove_at(index)
	visual.queue_redraw()
	queue_redraw()

func status_text() -> String:
	if core_exposed: return "MADRE CERO VULNERABLE: rompe el protocolo"
	if active_relays() < 2: return "Reconecta relés: acércate y pulsa E (25 resistencia)"
	return "Protege 2 relés · Enlace %d/18 · E reparar · Q escudo (%ds)" % [int(charge), ceili(guard_cooldown)]
