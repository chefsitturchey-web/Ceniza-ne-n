class_name ScavengeSystem
extends Node

## Spawns lootable props from the zone data and pays out parts/scrap when the
## player holds E near a prop that still has charges left.

signal notice_requested(message: String)

const TARGET_RANGE: float = 42.0
const TARGET_BASE: int = -500
## Horizontal jitter applied to each prop anchor, so props land on a random
## position every run while keeping the fixed count per zone.
const JITTER: float = 80.0

var bank: ResourceBank
var props: Array[ScavengeProp] = []
var rng: RandomNumberGenerator

func setup(zone: ZoneData, bank: ResourceBank) -> void:
	self.bank = bank
	if zone.props.is_empty():
		return
	rng = RandomNumberGenerator.new()
	rng.randomize()
	for index: int in range(zone.prop_spots.size()):
		var spot: Vector2 = zone.prop_spots[index]
		var prop: ScavengeProp = ScavengeProp.new()
		prop.data = zone.props[index % zone.props.size()]
		add_child(prop)
		# Anchors are fixed reachability points; the jitter band (spot.x +- JITTER)
		# must stay clear of higher-priority POI ranges checked earlier in
		# InteractionSystem.interaction_target(). The +550 anchor was moved to +660
		# because the railway station (+560, range 55 -> [505, 615]) shadowed it.
		prop.position = Vector2(spot.x + rng.randf_range(-JITTER, JITTER), GameRules.FLOOR_Y)
		props.append(prop)

func target_at(x: float) -> int:
	var best: int = -1
	var best_distance: float = TARGET_RANGE
	for index: int in range(props.size()):
		if props[index].depleted:
			continue
		var distance: float = absf(props[index].position.x - x)
		if distance <= best_distance:
			best_distance = distance
			best = index
	return GameRules.NO_TARGET if best == -1 else TARGET_BASE - best

func interact(target: int) -> bool:
	var index: int = TARGET_BASE - target
	if index < 0 or index >= props.size():
		return false
	var prop: ScavengeProp = props[index]
	var data: PropData = prop.data
	if not prop.extract():
		return false
	bank.add_parts(data.parts_per_charge)
	var message: String = "+%d piezas" % data.parts_per_charge
	if data.scrap_per_charge > 0:
		bank.deposit(data.scrap_per_charge)
		message += ", +%d chatarra" % data.scrap_per_charge
	notice_requested.emit(message)
	return true

func describe(target: int) -> Dictionary:
	var index: int = TARGET_BASE - target
	if index < 0 or index >= props.size():
		return {"text": "", "cost": -1}
	var prop: ScavengeProp = props[index]
	if prop.depleted:
		return {"text": "%s: agotado" % prop.data.label, "cost": -1}
	return {"text": "%s: %d extracciones" % [prop.data.label, prop.charges_left], "cost": -1}
