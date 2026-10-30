class_name ZoneHazards
extends Node2D

const CENTERS: Array[float] = [-650.0, -400.0, 400.0, 650.0]
var zone_index: int = 1
var player: Player
var cycle: CycleSystem
var elapsed: float = 0.0
var burn_cooldown: float = 0.0
var previous_phase: String = ""
var centers: Array[float] = CENTERS.duplicate()

func _ready() -> void:
	for side: float in [-1.0, 1.0]:
		for distance: float in [1850, 2850, 4050, 5350, 6200]:
			centers.append(side * (distance + zone_index * 23))

func heat_stage() -> int:
	if cycle.phase != "NOCHE":
		return 0
	var phase_time: float = fmod(elapsed, 9.0)
	if phase_time < 1.2:
		return 1
	return 2 if phase_time < 3.0 else 0

func tick(delta: float) -> void:
	if cycle.phase != previous_phase:
		elapsed = 0.0
		previous_phase = cycle.phase
	elapsed += delta
	burn_cooldown = maxf(0.0, burn_cooldown - delta)
	player.terrain_speed_factor = 1.0
	for center: float in centers:
		if absf(player.position.x - center) > 45.0 or player.health <= 0:
			continue
		if zone_index == 2 and player.position.y >= GameRules.FLOOR_Y - 6.0:
			player.terrain_speed_factor = 0.82
		elif zone_index == 1 and heat_stage() == 2 and burn_cooldown <= 0.0 and player.position.y > GameRules.FLOOR_Y - 24.0:
			player.take_damage(18)
			burn_cooldown = 0.8
	queue_redraw()

func _draw() -> void:
	for center: float in centers:
		var floor_y: float = GameRules.FLOOR_Y
		if zone_index == 1:
			draw_rect(Rect2(center - 47, floor_y - 3, 94, 7), Color("182639"))
			var stage: int = heat_stage()
			for slit: int in range(11):
				var tint: Color = Color("304356") if stage == 0 else Color("ffce75") if stage == 1 else Color("e86c38")
				draw_rect(Rect2(center - 42 + slit * 8, floor_y - 2, 3, 4), tint)
			if stage > 0:
				draw_rect(Rect2(center - 45, floor_y - 24, 90, 22), Color(1.0, 0.45, 0.15, 0.12 if stage == 1 else 0.32))
				if GamePreferences.current().particles and stage == 2:
					for spark: int in range(8):
						draw_rect(Rect2(center - 40 + spark * 11, floor_y - fmod(elapsed * 32 + spark * 7, 34), 1, 3), Color("ffce75"))
		elif zone_index == 2:
			draw_rect(Rect2(center - 48, floor_y - 2, 96, 9), Color("182e40"))
			for ripple: int in range(5):
				var shift: float = sin(elapsed * 2.0 + ripple) * 5.0
				draw_line(Vector2(center - 38 + shift, floor_y + ripple * 2), Vector2(center + 32 + shift, floor_y + ripple * 2), Color(0.28, 0.85, 0.8, 0.28 - ripple * 0.04))
		else:
			var tint: Color = Color("d5ae65") if zone_index == 3 else Color("47dacb")
			for index: int in 5:
				var start: Vector2 = Vector2(center - 45 + index * 19, floor_y - 1)
				draw_line(start, start + Vector2(14, -4 - index % 2 * 3), tint.darkened(0.5), 2)
				var pulse: float = fposmod(elapsed * 0.4 + index * 0.15, 1)
				draw_circle(start + Vector2(14 * pulse, (-4 - index % 2 * 3) * pulse), 1, tint)
