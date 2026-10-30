class_name TrapSystem
extends Node

## Owns the rat traps placed at fixed spots. The workshop arms them one at a
## time; armed traps then catch pests on their own.

signal notice_requested(message: String)

const TRAP_SPOTS: Array[float] = [-260.0, 260.0]
const TRAP_RANGE: float = 24.0
const TRAP_COOLDOWN: float = 6.0

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

func arm_trap() -> bool:
	for trap: RatTrap in traps:
		if not trap.armed:
			trap.armed = true
			trap.refresh_visual()
			notice_requested.emit("Trampa armada")
			return true
	notice_requested.emit("Trampas ya armadas")
	return false

func has_unarmed() -> bool:
	for trap: RatTrap in traps:
		if not trap.armed:
			return true
	return false

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
