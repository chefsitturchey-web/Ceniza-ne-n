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
var dismissed: bool = false
var corpse_spawned: bool = false

func _ready() -> void:
	add_to_group(GameRules.ALLIES)
	visual = FieldUnitVisual.new()
	visual.actor = self
	visual.role = role
	add_child(visual)

func take_damage(amount: int) -> void:
	if hp <= 0 or amount <= 0: return
	if role == "guardian": amount = maxi(1, ceili(amount * 0.35))
	hp = maxi(0, hp - maxi(0, amount))
	if hp > 0 and visual != null: visual.pulse_hurt()
	queue_redraw()
	if hp == 0:
		remove_from_group(GameRules.ALLIES)
		if not corpse_spawned:
			corpse_spawned = true
			var world: District = home.expansion.district as District
			if world != null and world.corpse_system != null:
				world.corpse_system.spawn(global_position, &"ally", world.cycle.day)
		demobilize()

func demobilize() -> void:
	if dismissed: return
	dismissed = true
	home.staffed = home.staff_count() > 0
	if home.expansion.district.civic != null:
		home.expansion.district.civic.villagers.append({"x": position.x, "side": signf(home.position.x), "recover": 1.25})
		home.expansion.district.presenter.show_notice("Unidad desarmada: necesita una nueva herramienta")

func tick(delta: float) -> void:
	queue_redraw()
	shot = maxf(0, shot - delta)
	cooldown = maxf(0, cooldown - delta)
	if hp <= 0:
		demobilize()
		return
	if home.hp <= 0 or not home.staffed or not home.expansion.powered(home): return
	var world: Node2D = home.expansion.district
	var destination: float = home.position.x
	var anchor: float = home.position.x
	if world.civic != null and role in ["ranger", "guardian"]:
		anchor = signf(home.position.x) * maxf(absf(home.position.x), world.civic.frontier(signf(home.position.x)) - (35 if role == "ranger" else -8))
		destination = anchor
	if world.story != null and world.story.convoy_active and world.story.convoy_health > 0 and home.position.x < 0 and world.civic.advance_side == 0 and role in ["ranger", "guardian"]:
		anchor = world.story.convoy_x + (30 if role == "guardian" else 90)
		destination = anchor
	var enemy: SiegeEnemy
	var nearest: float = 260
	var assaulting: bool = world.civic != null and world.civic.advance_side == int(signf(home.position.x)) and role in ["ranger", "guardian"]
	if world.civic != null and world.civic.advance_side == int(signf(home.position.x)) and role in ["ranger", "guardian"] and world.defenses.nearest_enemy(position.x, 180) == null:
		var portal: EnemyRepeater
		for gate: EnemyRepeater in world.civic.gates + world.expedition.repeaters:
			if gate.health.current <= 0 or signf(gate.position.x) != signf(home.position.x): continue
			if portal == null or absf(gate.position.x) < absf(portal.position.x): portal = gate
		if portal != null:
			facing = signf(portal.position.x - position.x)
			position.x = move_toward(position.x, portal.position.x - facing * (30 if role == "guardian" else 110), delta * 70)
			if absf(portal.position.x - position.x) < (45 if role == "guardian" else 150) and cooldown <= 0:
				portal.hurtbox.receive(14 + world.modules.command_damage())
				beam_to = portal.position + Vector2(0, -30)
				shot = 0.12
				cooldown = 1.2
			return
	if assaulting: anchor = position.x
	if role in ["ranger", "guardian"]:
		for candidate: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES):
			var distance: float = absf(candidate.position.x - anchor)
			if distance < nearest:
				nearest = distance
				enemy = candidate as SiegeEnemy
		if enemy != null:
			if absf(enemy.position.x - position.x) > 0.1:
				facing = signf(enemy.position.x - position.x)
			destination = enemy.position.x - facing * (30 if role == "guardian" else 145)
			if absf(enemy.position.x - position.x) <= (42 if role == "guardian" else 180) and cooldown <= 0:
				if role == "guardian": enemy.take_damage(22 + world.modules.command_damage())
				else: enemy.receive_shot(16 + world.modules.command_damage(), global_position + Vector2(0, -24))
				beam_to = enemy.position + Vector2(0, -20)
				cooldown = 0.9
				shot = 0.12
				world.sound.play_cue("shot", -10)
	elif role == "technician":
		if world.story != null and world.story.relay_ordered and not world.story.completed[1] and world.cycle.phase == "DÍA":
			anchor = StoryDirector.RELAY_X
			destination = anchor
			if absf(position.x - anchor) < 50:
				world.story.work_relay(delta)
				shot = 0.1
				beam_to = Vector2(anchor, GameRules.FLOOR_Y - 25)
		if home.hp < home.MAX_HEALTH and cooldown <= 0 and absf(position.x - home.position.x) < 60:
			home.hp = mini(home.MAX_HEALTH, home.hp + 8)
			beam_to = home.position + Vector2(0, -24)
			shot = 0.3
			cooldown = 3
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
	position.x = move_toward(position.x, clampf(destination, anchor - 260, anchor + 260), delta * 85)

func snapshot() -> Dictionary:
	return {"hp": hp, "x": position.x, "respawn": respawn, "cooldown": cooldown}

func restore(data: Dictionary) -> void:
	hp = int(data.hp)
	position.x = float(data.x)
	respawn = float(data.respawn)
	cooldown = float(data.cooldown)
	if hp <= 0: remove_from_group(GameRules.ALLIES)

func _draw() -> void:
	if shot > 0 and hp > 0 and role != "guardian":
		draw_line(Vector2(facing * (22 if role == "ranger" else 12), -20), to_local(beam_to), Color("47dacb") if role in ["medic", "technician"] else Color("ffce75"), 1)
