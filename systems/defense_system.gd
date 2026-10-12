class_name DefenseSystem
extends Node

var sites: Array[ConstructionSite] = []
var player: Player
var overload: OverloadSystem
var drone_timer: float = 0.0
var beams: Array[Dictionary] = []

func update_beams(delta: float) -> void:
	for index: int in range(beams.size() - 1, -1, -1):
		beams[index].time -= delta
		if beams[index].time <= 0:
			beams.remove_at(index)

func nearest_enemy(x: float, distance_limit: float) -> Node2D:
	var best: Node2D = null
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		var distance: float = absf(enemy.position.x - x)
		if distance < distance_limit:
			distance_limit = distance
			best = enemy
	return best

func fire_from(origin: Vector2, target: Node2D, damage: int, electric: bool = false) -> void:
	beams.append({"from": origin, "to": target.position + Vector2(0, -16), "time": GameRules.BEAM_DURATION})
	var hurtbox: HurtboxComponent = target.get_node("Hurtbox") as HurtboxComponent
	if target is SiegeEnemy:
		(target as SiegeEnemy).receive_shot(damage, origin, electric)
	else:
		hurtbox.receive(damage)

func update_defenses(delta: float) -> void:
	for site: ConstructionSite in sites:
		if site.data.damage == 0 or site.hp <= 0:
			continue
		site.shot = maxf(0.0, site.shot - delta)
		if site.shot == 0.0:
			var target: Node2D = nearest_enemy(site.x, site.data.attack_range)
			if target != null:
				site.fire_effects()
				fire_from(Vector2(site.x, GameRules.FLOOR_Y - 42), target, site.data.damage, overload.overloaded(site.x))
				site.shot = site.data.overloaded_interval if overload.overloaded(site.x) else site.data.interval
	drone_timer = maxf(0.0, drone_timer - delta)
	if drone_timer == 0.0 and player.health > 0:
		var target: Node2D = nearest_enemy(player.position.x, GameRules.DRONE_RANGE)
		if target != null:
			fire_from(player.position + Vector2(-18, -48), target, GameRules.DRONE_DAMAGE)
			drone_timer = GameRules.DRONE_INTERVAL
