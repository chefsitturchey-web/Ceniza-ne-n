class_name DefenseSystem
extends Node

var sites: Array[ConstructionSite] = []
var player: Player
var overload: OverloadSystem
var drone_timer: float = 0.0
var beams: Array[Dictionary] = []
var drone_rank: int = 0
var modules: ModuleSystem
signal shot_fired(origin: Vector2)

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
	shot_fired.emit(origin)
	beams.append({"from": origin, "to": target.position + Vector2(0, -16), "time": GameRules.BEAM_DURATION, "electric": electric})
	var hurtbox: HurtboxComponent = target.get_node("Hurtbox") as HurtboxComponent
	if target is SiegeEnemy:
		(target as SiegeEnemy).receive_shot(damage, origin, electric)
	else:
		hurtbox.receive(damage)

func update_defenses(delta: float) -> void:
	for site: ConstructionSite in sites:
		if site.data.damage == 0 or site.hp <= 0 or not site.powered:
			continue
		var target: Node2D = nearest_enemy(site.x, FortressRules.reach(site))
		if site.turret_visual != null:
			if target != null:
				site.turret_visual.track(target.global_position + Vector2(0, -16))
			else:
				site.turret_visual.clear_target()
		site.shot = maxf(0.0, site.shot - delta)
		if site.shot == 0.0:
			if target != null:
				site.fire_effects()
				fire_from(site.muzzle_position(), target, FortressRules.damage(site), overload.overloaded(site.x))
				site.shot = FortressRules.interval(site, overload.overloaded(site.x))
	# La colonia se defiende con tropas y edificios; el equipo personal va al jefe.
	if not player.combat_enabled: return
	drone_timer = maxf(0.0, drone_timer - delta)
	if drone_timer == 0.0 and player.health > 0 and (modules == null or "drone" in modules.equipped):
		var reach: float = modules.range_for("drone") if modules != null else GameRules.DRONE_RANGE
		var target: Node2D = nearest_enemy(player.position.x, reach)
		if target != null:
			var amount: int = modules.damage_for("drone") if modules != null else GameRules.DRONE_DAMAGE
			fire_from(player.position + Vector2(-18, -48), target, amount + drone_rank * 4)
			if modules != null and modules.evolved.drone:
				var next: Node2D = nearest_enemy(player.position.x, reach)
				if next != null:
					fire_from(player.position + Vector2(18, -44), next, maxi(1, roundi((amount + drone_rank * 4) * 0.65)))
			drone_timer = GameRules.DRONE_INTERVAL * (1.0 - drone_rank * 0.1)
	if modules != null:
		modules.update_lateral(delta)
