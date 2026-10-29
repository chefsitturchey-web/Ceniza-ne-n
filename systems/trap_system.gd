class_name TrapSystem
extends Node

## Owns craftable rat traps. The player fabricates a trap by holding E near a
## spot, paying scrap and parts; armed traps then catch pests on their own.

signal notice_requested(message: String)

const TRAP_SPOTS: Array[float] = [-260.0, 260.0]
const TRAP_COST: int = 15
const TRAP_PARTS: int = 6
const TRAP_RANGE: float = 24.0
const TRAP_COOLDOWN: float = 6.0
const TRAP_TARGET_BASE: int = -600
const TRAP_TARGET_RANGE: float = 42.0

var bank: ResourceBank
var traps: Array[RatTrap] = []

func setup(bank: ResourceBank) -> void:
	self.bank = bank
	for spot: float in TRAP_SPOTS:
		var trap: RatTrap = RatTrap.new()
		add_child(trap)
		trap.position = Vector2(spot, GameRules.FLOOR_Y)
		trap.refresh_visual()
		traps.append(trap)

func target_at(x: float) -> int:
	var best: int = -1
	var best_distance: float = TRAP_TARGET_RANGE
	for index: int in range(traps.size()):
		var distance: float = absf(traps[index].position.x - x)
		if distance <= best_distance:
			best_distance = distance
			best = index
	return GameRules.NO_TARGET if best == -1 else TRAP_TARGET_BASE - best

func interact(target: int) -> bool:
	var index: int = TRAP_TARGET_BASE - target
	if index < 0 or index >= traps.size():
		return false
	var trap: RatTrap = traps[index]
	if trap.armed:
		notice_requested.emit("Trampa ya armada")
		return false
	if bank.scrap < TRAP_COST:
		notice_requested.emit("Falta chatarra")
		return false
	if bank.parts < TRAP_PARTS:
		notice_requested.emit("Faltan piezas")
		return false
	bank.spend(TRAP_COST)
	bank.spend_parts(TRAP_PARTS)
	trap.armed = true
	trap.refresh_visual()
	notice_requested.emit("Trampa armada")
	return true

func describe(target: int) -> Dictionary:
	var index: int = TRAP_TARGET_BASE - target
	if index < 0 or index >= traps.size():
		return {"text": "", "cost": -1}
	var trap: RatTrap = traps[index]
	if trap.armed:
		return {"text": "Trampa: armada", "cost": -1}
	return {"text": "Trampa: fabricar", "cost": TRAP_COST}

func traps_armed() -> Array[RatTrap]:
	var result: Array[RatTrap] = []
	for trap: RatTrap in traps:
		if trap.armed and trap.cooldown <= 0.0:
			result.append(trap)
	return result

func tick(delta: float) -> void:
	for trap: RatTrap in traps:
		if trap.cooldown > 0.0:
			trap.cooldown = maxf(0.0, trap.cooldown - delta)
			trap.refresh_visual()
