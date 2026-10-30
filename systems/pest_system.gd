class_name PestSystem
extends Node

## Spawns skittish rats from decaying corpses and drives them toward powered
## turrets to chew the wiring (short-circuit), unless an armed trap snaps them.

signal notice_requested(message: String)

const MAX_RATS: int = 5
const CHEW_DURATION: float = 6.0
const CHEWS_BEFORE_FLEE: int = 2
const EMERGE_DURATION: float = 0.3
const ARRIVE_DISTANCE: float = 6.0

var corpse_system: CorpseSystem
var construction: ConstructionSystem
var trap_system: TrapSystem
var rats: Array[SewerRat] = []

func setup(corpse_system: CorpseSystem, construction: ConstructionSystem, trap_system: TrapSystem) -> void:
	self.corpse_system = corpse_system
	self.construction = construction
	self.trap_system = trap_system
	corpse_system.rat_spawn_requested.connect(_on_rat_spawn)

func _on_rat_spawn(corpse: Corpse) -> void:
	if rats.size() >= MAX_RATS:
		return
	var rat: SewerRat = SewerRat.new()
	add_child(rat)
	rat.position = corpse.position
	rats.append(rat)

func tick(delta: float) -> void:
	for rat: SewerRat in rats:
		if is_instance_valid(rat):
			_update_rat(rat, delta)
	for index: int in range(rats.size() - 1, -1, -1):
		if not is_instance_valid(rats[index]):
			rats.remove_at(index)

func _update_rat(rat: SewerRat, delta: float) -> void:
	if rat.state in [SewerRat.State.DART, SewerRat.State.HIDE] and (not is_instance_valid(rat.target_site) or rat.target_site.hp <= 0 or not rat.target_site.powered or rat.target_site.shorted):
		rat.target_site = _choose_machine(rat)
		rat.chew_time = 0.0
		if rat.target_site == null: _begin_flee(rat)
		else: rat.state = SewerRat.State.DART
	match rat.state:
		SewerRat.State.EMERGE:
			rat.chew_time += delta
			if rat.chew_time >= EMERGE_DURATION:
				rat.chew_time = 0.0
				rat.target_site = _choose_machine(rat)
				if rat.target_site == null:
					_begin_flee(rat)
				else:
					rat.state = SewerRat.State.DART
		SewerRat.State.DART:
			rat.visible = true
			var previous_x: float = rat.position.x
			rat.position.x = move_toward(rat.position.x, rat.target_site.position.x, rat.speed * delta)
			for trap: RatTrap in trap_system.traps_armed():
				if trap.position.x >= minf(previous_x, rat.position.x) - trap_system.TRAP_RANGE and trap.position.x <= maxf(previous_x, rat.position.x) + trap_system.TRAP_RANGE:
					_catch(rat, trap)
					return
			if absf(rat.position.x - rat.target_site.position.x) <= ARRIVE_DISTANCE:
				rat.visible = false
				rat.chew_time = 0.0
				rat.state = SewerRat.State.HIDE
		SewerRat.State.HIDE:
			rat.chew_time += delta
			if rat.chew_time >= CHEW_DURATION:
				rat.chew_time = 0.0
				rat.target_site.shorted = true
				rat.target_site.powered = false
				rat.target_site.queue_redraw()
				notice_requested.emit("Cortocircuito: máquina fuera de servicio")
				rat.chews += 1
				if rat.chews >= CHEWS_BEFORE_FLEE:
					_begin_flee(rat)
					return
				rat.target_site = _choose_machine(rat)
				if rat.target_site == null:
					_begin_flee(rat)
				else:
					rat.state = SewerRat.State.DART
		SewerRat.State.FLEE:
			rat.position.x = move_toward(rat.position.x, rat.exit_x, rat.speed * delta)
			if absf(rat.position.x) >= GameRules.MAP_HALF_WIDTH + 60.0:
				rat.queue_free()

func _choose_machine(rat: SewerRat) -> ConstructionSite:
	var best: ConstructionSite = null
	var best_distance: float = INF
	for site: ConstructionSite in construction.defensive_sites():
		if site.data.damage <= 0 or site.hp <= 0 or not site.powered or site.shorted:
			continue
		var distance: float = absf(site.position.x - rat.position.x)
		if distance < best_distance:
			best_distance = distance
			best = site
	return best

func _begin_flee(rat: SewerRat) -> void:
	rat.state = SewerRat.State.FLEE
	rat.chew_time = 0.0
	rat.exit_x = (-1.0 if rat.position.x < 0 else 1.0) * (GameRules.MAP_HALF_WIDTH + 80.0)
	rat.visible = true

func _catch(rat: SewerRat, trap: RatTrap) -> void:
	trap.cooldown = trap_system.TRAP_COOLDOWN
	trap.refresh_visual()
	notice_requested.emit("Rata atrapada")
	rat.queue_free()
