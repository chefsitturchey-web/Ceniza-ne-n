class_name ResourceBank
extends Node

signal changed(scrap: int, used: int, capacity: int)
@export var scrap: int = GameRules.INITIAL_SCRAP
@export var energy_capacity: int = GameRules.ENERGY_CAPACITY
var sites: Array[ConstructionSite] = []
var expansion: ExpansionSystem

func available_capacity() -> int:
	return energy_capacity + (expansion.energy_bonus() if expansion != null else 0)

func energy_used() -> int:
	var used: int = expansion.energy_used() if expansion != null else 0
	for site: ConstructionSite in sites:
		if (site.hp > 0 and site.powered) or site.ordered:
			used += site.data.energy
	return used

func deposit(amount: int) -> void:
	scrap += amount
	changed.emit(scrap, energy_used(), available_capacity())

func spend(amount: int) -> bool:
	if scrap < amount:
		return false
	deposit(-amount)
	return true
