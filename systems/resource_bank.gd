class_name ResourceBank
extends Node

signal changed(scrap: int, used: int, capacity: int)
signal parts_changed(parts: int)
signal parts_spilled(amount: int)
@export var scrap: int = GameRules.INITIAL_SCRAP
@export var energy_capacity: int = GameRules.ENERGY_CAPACITY
var parts: int = 0
var stored_parts: int = 0
var parts_capacity: int = 24
var sites: Array[ConstructionSite] = []
var expansion: ExpansionSystem

func available_capacity() -> int:
	var core_bonus: int = maxi(0, expansion.district.core.tier - 1) * 4 if expansion != null else 0
	return energy_capacity + core_bonus + (expansion.energy_bonus() if expansion != null else 0)

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

func add_parts(amount: int) -> void:
	var accepted: int = mini(maxi(0, amount), maxi(0, parts_capacity - parts))
	parts += accepted
	parts_changed.emit(parts)
	if amount > accepted: parts_spilled.emit(amount - accepted)

func spend_parts(amount: int) -> bool:
	if amount < 0 or parts + stored_parts < amount:
		return false
	var from_store: int = mini(stored_parts, amount)
	stored_parts -= from_store
	parts -= amount - from_store
	parts_changed.emit(parts)
	return true
