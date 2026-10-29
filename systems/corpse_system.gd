class_name CorpseSystem
extends Node

## Owns corpses, decays them, applies their poison aura to the player and
## drives the gravedigger. Rat spawning is only signalled for now (no consumer).

signal rat_spawn_requested(corpse: Corpse)

const RAT_INTERVAL: float = 30.0

var cycle: CycleSystem
var player: Player
var director: SiegeDirector
var gravedigger: Gravedigger
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
	if gravedigger != null:
		gravedigger.update(delta)

func _prune() -> void:
	for index: int in range(corpses.size() - 1, -1, -1):
		if not is_instance_valid(corpses[index]) or corpses[index].buried:
			corpses.remove_at(index)
