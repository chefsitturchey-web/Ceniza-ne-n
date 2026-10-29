class_name ZoneHazards
extends Node2D

const CENTERS: Array[float] = [-650.0, -400.0, 400.0, 650.0]
var zone_index: int = 1
var player: Player
var cycle: CycleSystem
var elapsed: float = 0.0
var burn_cooldown: float = 0.0
var previous_phase: String = ""

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
	for center: float in CENTERS:
		if absf(player.position.x - center) > 45.0 or player.health <= 0:
			continue
		if zone_index == 2 and player.position.y >= GameRules.FLOOR_Y - 6.0:
			player.terrain_speed_factor = 0.82
		elif zone_index == 1 and heat_stage() == 2 and burn_cooldown <= 0.0 and player.position.y > GameRules.FLOOR_Y - 24.0:
			player.take_damage(18)
			burn_cooldown = 0.8
	queue_redraw()

func _draw() -> void:
	for center: float in CENTERS:
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
		else:
			draw_rect(Rect2(center - 48, floor_y - 2, 96, 9), Color("182e40"))
			for ripple: int in range(5):
				var shift: float = sin(elapsed * 2.0 + ripple) * 5.0
				draw_line(Vector2(center - 38 + shift, floor_y + ripple * 2), Vector2(center + 32 + shift, floor_y + ripple * 2), Color(0.28, 0.85, 0.8, 0.28 - ripple * 0.04))
