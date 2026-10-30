class_name CorpseSystem
extends Node

## Owns corpses, decays them, applies their poison aura to the player and
## dispatches reported corpses to a colony builder once the shovel exists.
## Rat spawning is only signalled for now (no consumer).

signal rat_spawn_requested(corpse: Corpse)
signal notice_requested(message: String)

const RAT_INTERVAL: float = 30.0
const REPORT_RANGE: float = 40.0
const REPORT_BASE: int = -800

var cycle: CycleSystem
var player: Player
var director: SiegeDirector
var colony: ColonySystem
var workshop: WorkshopSystem
var corpses: Array[Corpse] = []

func setup(cycle: CycleSystem, player: Player, director: SiegeDirector) -> void:
	self.cycle = cycle
	self.player = player
	self.director = director

func spawn(position: Vector2, kind: StringName, died_day: int) -> Corpse:
	var corpse: Corpse = Corpse.new()
	corpse.kind = kind
	corpse.cycle = cycle
	corpse.died_day = died_day
	add_child(corpse)
	corpse.position = position
	corpse.refresh_stage(cycle.day)
	corpses.append(corpse)
	return corpse

func target_at(x: float) -> int:
	var best: int = -1
	var best_distance: float = REPORT_RANGE
	for index: int in range(corpses.size()):
		var corpse: Corpse = corpses[index]
		if not is_instance_valid(corpse) or corpse.buried:
			continue
		var distance: float = absf(corpse.position.x - x)
		if distance <= best_distance:
			best_distance = distance
			best = index
	return GameRules.NO_TARGET if best == -1 else REPORT_BASE - best

func report(target: int) -> bool:
	var index: int = REPORT_BASE - target
	if index < 0 or index >= corpses.size():
		return false
	var corpse: Corpse = corpses[index]
	if not is_instance_valid(corpse) or corpse.buried:
		return false
	if corpse.reported:
		notice_requested.emit("Muerto ya reportado")
		return false
	corpse.reported = true
	notice_requested.emit("Muerto reportado")
	if workshop != null and workshop.shovel_ready and colony != null and colony.burial_target == null:
		colony.burial_target = corpse
	elif workshop == null or not workshop.shovel_ready:
		notice_requested.emit("Falta la pala")
	return true

func describe(target: int) -> Dictionary:
	var index: int = REPORT_BASE - target
	if index < 0 or index >= corpses.size():
		return {"text": "", "cost": -1}
	var corpse: Corpse = corpses[index]
	if not is_instance_valid(corpse) or corpse.buried or corpse.reported:
		return {"text": "Muerto reportado", "cost": -1}
	return {"text": "Reportar muerto", "cost": -1}

func tick(delta: float) -> void:
	if player == null or cycle == null:
		return
	_prune()
	var poison: float = 0.0
	for corpse: Corpse in corpses:
		corpse.refresh_stage(cycle.day)
		if corpse.stage >= 2:
			corpse.rat_timer += delta
			if corpse.rat_timer >= RAT_INTERVAL:
				corpse.rat_timer = 0.0
				rat_spawn_requested.emit(corpse)
			if absf(player.position.x - corpse.position.x) <= corpse.aura_radius():
				poison = maxf(poison, corpse.poison_dps())
	player.set_poison(poison)
	_dispatch_burial()

## Auto-dispatches the oldest reported corpse once the shovel has been crafted.
func _dispatch_burial() -> void:
	if colony == null or workshop == null or not workshop.shovel_ready:
		return
	if colony.burial_target != null and (not is_instance_valid(colony.burial_target) or colony.burial_target.buried):
		colony.burial_target = null
	if colony.burial_target != null:
		return
	for corpse: Corpse in corpses:
		if corpse.reported and not corpse.buried:
			colony.burial_target = corpse
			return

func _prune() -> void:
	for index: int in range(corpses.size() - 1, -1, -1):
		if not is_instance_valid(corpses[index]) or corpses[index].buried:
			corpses.remove_at(index)
