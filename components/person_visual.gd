class_name PersonVisual
extends EntityVisual
## Los estados visuales no infligen daño ni modifican la velocidad o la economía.
var unit_role: String = "civilian"
var fatigue: float = 0
var hurt_left: float = 0
var action_left: float = 0
var down_time: float = 0
var last_action: bool = false
var exhausted: bool = false
var current: StringName = &"reposo"
var effects: DebrisEmitter
var sweat_left: float = 0
var gait_distance: float = 0
var motion_left: float = 0

func setup_person(role: String, existing: AnimatedSprite2D = null) -> void:
	unit_role = role
	sprite = existing if existing != null else AnimatedSprite2D.new()
	if existing == null: add_child(sprite)
	sprite.sprite_frames = UnitSpriteLibrary.frames(role)
	sprite.position = UnitSpriteLibrary.OFFSET
	sprite.scale = Vector2.ONE
	sprite.offset = Vector2.ZERO
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation = &"reposo"
	sprite.frame = 0
	sprite.play()
	effects = DebrisEmitter.new()
	add_child(effects)

func pulse_hurt() -> void:
	hurt_left = 0.375
	if sprite != null:
		sprite.play(&"dano")
		sprite.set_frame_and_progress(0, 0)

func pulse_action() -> void:
	action_left = 0.4 if unit_role in ["ranger", "artillero", "saboteador"] else (0.58 if unit_role == "guardian" else 0.67)
	fatigue = minf(1, fatigue + 0.035)

func choose(animation: StringName, rate: float = 1.0) -> void:
	current = animation
	if sprite.animation != animation:
		sprite.play(animation)
		sprite.set_frame_and_progress(0, 0)
	sprite.speed_scale = rate

func update_person(delta: float, distance: float, working: bool, direction: float, action: bool = false, dead: bool = false, carrying: bool = false, fleeing: bool = false) -> void:
	if sprite == null: return
	var moving: bool = distance > 0.01 and distance < 100
	if moving: motion_left = 0.1
	elif delta > 0: motion_left = maxf(0, motion_left - delta)
	var locomotion: bool = moving or motion_left > 0
	sprite.flip_h = direction < 0
	hurt_left = maxf(0, hurt_left - delta)
	action_left = maxf(0, action_left - delta)
	if action and not last_action: pulse_action()
	last_action = action
	if dead:
		down_time += delta
		choose(&"caer")
		sprite.modulate.a = clampf(1.0 - (down_time - 0.85) / 0.35, 0, 1)
		return
	down_time = 0
	sprite.modulate = Color.WHITE
	# Cansancio por esfuerzo real; descansar recupera. Nunca avanza durante una pausa.
	if delta > 0:
		fatigue = clampf(fatigue + (distance * 0.00065 if moving else 0.0) + delta * (0.025 if working or action or action_left > 0 else (-0.09 if not moving else 0.006)), 0, 1)
	if fatigue >= 0.8: exhausted = true
	elif fatigue <= 0.35: exhausted = false
	if hurt_left > 0:
		choose(&"dano")
	elif action_left > 0 or working:
		choose(&"disparar" if unit_role in ["ranger", "artillero", "saboteador"] else (&"proteger" if unit_role == "guardian" else &"reparar"))
	elif locomotion:
		choose(&"huir" if fleeing else (&"cargar" if carrying else &"caminar"))
		# Cada ciclo recorre una zancada real. Un render sin tick físico no reinicia el paso.
		if delta > 0 and moving: gait_distance += distance
		var stride: float = 22.0 if carrying else (32.0 if fleeing else 28.0)
		var count: int = sprite.sprite_frames.get_frame_count(current)
		var progress: float = fposmod(gait_distance / stride * count, count)
		sprite.set_frame_and_progress(int(progress), fposmod(progress, 1))
		sprite.pause()
	elif exhausted:
		choose(&"cansancio")
	else:
		choose(&"reposo")
	sweat_left -= delta
	if exhausted and sweat_left <= 0 and effects != null:
		sweat_left = 0.8
		effects.emit_sweat(global_position + Vector2(direction * 4, -30))
