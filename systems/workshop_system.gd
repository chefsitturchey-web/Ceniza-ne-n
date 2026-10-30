class_name WorkshopSystem
extends Node

## Dedicated tool workshop. Crafts a shovel (unlocks corpse burial) or arms one
## rat trap at its fixed spot, paying scrap and parts up front.

signal notice_requested(message: String)

const TARGET_BASE: int = -700
const TARGET_RANGE: float = 42.0

var bank: ResourceBank
var trap_system: TrapSystem
var shovel_ready: bool = false

var recipes: Array[Dictionary] = [
	{"id": "pala", "label": "Pala", "scrap": 4, "parts": 8, "spot": Vector2(-495, 260)},
	{"id": "trampa", "label": "Trampa", "scrap": 15, "parts": 6, "spot": Vector2(-465, 260)},
]

func setup(bank: ResourceBank, trap_system: TrapSystem) -> void:
	self.bank = bank
	self.trap_system = trap_system

func target_at(x: float) -> int:
	var best: int = -1
	var best_distance: float = TARGET_RANGE
	for index: int in range(recipes.size()):
		var spot: Vector2 = recipes[index]["spot"]
		var distance: float = absf(spot.x - x)
		if distance <= best_distance:
			best_distance = distance
			best = index
	return GameRules.NO_TARGET if best == -1 else TARGET_BASE - best

func interact(target: int) -> bool:
	var index: int = TARGET_BASE - target
	if index < 0 or index >= recipes.size():
		return false
	var recipe: Dictionary = recipes[index]
	var scrap_cost: int = recipe["scrap"]
	var parts_cost: int = recipe["parts"]
	var id: String = recipe["id"]
	if bank.scrap < scrap_cost:
		notice_requested.emit("Falta chatarra")
		return false
	if bank.parts < parts_cost:
		notice_requested.emit("Faltan piezas")
		return false
	if id == "pala" and shovel_ready:
		notice_requested.emit("Ya tienes la pala")
		return false
	if id == "trampa" and not trap_system.has_unarmed():
		notice_requested.emit("Trampas ya armadas")
		return false
	bank.spend(scrap_cost)
	bank.spend_parts(parts_cost)
	if id == "pala":
		shovel_ready = true
		notice_requested.emit("Pala fabricada")
	elif id == "trampa":
		trap_system.arm_trap()
	return true

func describe(target: int) -> Dictionary:
	var index: int = TARGET_BASE - target
	if index < 0 or index >= recipes.size():
		return {"text": "", "cost": -1}
	var recipe: Dictionary = recipes[index]
	var id: String = recipe["id"]
	if id == "pala" and shovel_ready:
		return {"text": "Pala: ya fabricada", "cost": -1}
	var label: String = recipe["label"]
	var scrap_cost: int = recipe["scrap"]
	var parts_cost: int = recipe["parts"]
	return {"text": "Fabricar %s (%d + %d piezas)" % [label, scrap_cost, parts_cost], "cost": scrap_cost}
