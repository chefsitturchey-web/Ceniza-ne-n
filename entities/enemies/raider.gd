class_name Raider
extends SiegeEnemy

var special_target: Node2D

func choose_special_target(delta: float) -> bool:
	special_target = null
	if data.id == &"saboteador" and session.expansion != null:
		var distance: float = INF
		for site: ExpansionOutpost in session.expansion.sites:
			if site.hp <= 0 or signf(site.position.x) != signf(position.x): continue
			var candidate: float = absf(site.position.x - position.x)
			if candidate < distance:
				distance = candidate
				special_target = site
	elif data.id == &"artillero":
		var nearest: float = 245
		var candidates: Array[Node2D] = [core]
		if player.health > 0: candidates.append(player)
		for site: ConstructionSite in construction.defensive_sites():
			if site.hp > 0 and site.data.blocks_enemies: candidates.append(site)
		if session.expansion != null:
			for site: ExpansionOutpost in session.expansion.sites:
				if site.hp > 0: candidates.append(site)
		for ally: Node in get_tree().get_nodes_in_group(GameRules.ALLIES): candidates.append(ally as Node2D)
		for candidate: Node2D in candidates:
			var distance: float = absf(candidate.position.x - position.x)
			if distance < nearest:
				nearest = distance
				special_target = candidate
	if not is_instance_valid(special_target): return false
	target_kind = "special"
	face_toward(special_target.position.x)
	var reach: float = 220 if data.id == &"artillero" else 28
	var moving: bool = absf(special_target.position.x - position.x) > reach
	if moving:
		position.x = move_toward(position.x, special_target.position.x, speed * delta)
		set_state(State.APPROACH)
	elif cooldown <= 0:
		set_state(State.WINDUP)
		windup = data.windup
		attack_visual_remaining = data.attack_visual_duration
	update_visual(moving)
	return true

func land_hit() -> void:
	if target_kind != "special":
		super.land_hit()
		return
	if not is_instance_valid(special_target): return
	if data.id == &"artillero":
		var bolt: RaidBolt = RaidBolt.new()
		bolt.session = session
		bolt.damage = damage
		bolt.position = position + Vector2(facing * 32, -24)
		bolt.direction = facing
		get_parent().add_child(bolt)
		if session.expansion != null: session.expansion.district.sound.play_world("artillery_shot", position)
	elif absf(special_target.position.x - position.x) < 38:
		special_target.take_damage(damage * 2)
		if session.expansion != null: session.expansion.district.sound.play_world("saboteur_hit", position)
