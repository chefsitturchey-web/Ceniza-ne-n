class_name FieldAlly
extends Node2D

var role: String = "ranger"
var home: ExpansionOutpost
var hp: int = 90
var respawn: float = 0
var cooldown: float = 0
var facing: float = 1
var shot: float = 0
var beam_to: Vector2
var visual: FieldUnitVisual

func _ready() -> void:
	add_to_group(GameRules.ALLIES)
	visual = FieldUnitVisual.new()
	visual.actor = self
	visual.role = role
	add_child(visual)

func take_damage(amount: int) -> void:
	if hp <= 0: return
	hp = maxi(0, hp - maxi(0, amount))
	queue_redraw()
	if hp == 0:
		respawn = 18
		remove_from_group(GameRules.ALLIES)

func tick(delta: float) -> void:
	queue_redraw()
	shot = maxf(0, shot - delta)
	cooldown = maxf(0, cooldown - delta)
	if home.hp <= 0 or not home.expansion.powered(home): return
	if hp <= 0:
		respawn = maxf(0, respawn - delta)
		if respawn == 0:
			hp = 90
			position = home.position
			add_to_group(GameRules.ALLIES)
		return
	var world: Node2D = home.expansion.district
	var destination: float = home.position.x
	var enemy: SiegeEnemy
	var nearest: float = 260
	if role == "ranger":
		for candidate: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES):
			var distance: float = absf(candidate.position.x - home.position.x)
			if distance < nearest:
				nearest = distance
				enemy = candidate as SiegeEnemy
		if enemy != null:
			if absf(enemy.position.x - position.x) > 0.1:
				facing = signf(enemy.position.x - position.x)
			destination = enemy.position.x - facing * 145
			if absf(enemy.position.x - position.x) <= 180 and cooldown <= 0:
				enemy.receive_shot(16, global_position + Vector2(0, -24))
				beam_to = enemy.position + Vector2(0, -20)
				cooldown = 0.9
				shot = 0.12
				world.sound.play_cue("shot", -10)
	else:
		var patient: Node2D
		var best: float = 260
		if world.player.health > 0 and world.player.health < Player.MAX_HEALTH and absf(world.player.position.x - home.position.x) < best:
			patient = world.player
			best = absf(world.player.position.x - home.position.x)
		for candidate: Node in get_tree().get_nodes_in_group(GameRules.ALLIES):
			if candidate == self or candidate.hp >= 90: continue
			var distance: float = absf(candidate.position.x - home.position.x)
			if distance < best:
				best = distance
				patient = candidate as Node2D
		if patient != null:
			destination = patient.position.x
			if absf(patient.position.x - position.x) < 80 and cooldown <= 0:
				if patient is Player: patient.health = mini(Player.MAX_HEALTH, patient.health + 8)
				else: patient.hp = mini(90, patient.hp + 8)
				beam_to = patient.position + Vector2(0, -20)
				cooldown = 3
				shot = 0.35
	if absf(destination - position.x) > 2:
		facing = signf(destination - position.x)
	position.x = move_toward(position.x, clampf(destination, home.position.x - 260, home.position.x + 260), delta * 85)

func snapshot() -> Dictionary:
	return {"hp": hp, "x": position.x, "respawn": respawn, "cooldown": cooldown}

func restore(data: Dictionary) -> void:
	hp = int(data.hp)
	position.x = float(data.x)
	respawn = float(data.respawn)
	cooldown = float(data.cooldown)
	if hp <= 0: remove_from_group(GameRules.ALLIES)

func _draw() -> void:
	if shot > 0 and hp > 0:
		draw_line(Vector2(facing * 14, -24), to_local(beam_to), Color("47dacb") if role == "medic" else Color("ffce75"), 1)
