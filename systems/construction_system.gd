class_name ConstructionSystem
extends Node

signal notice_requested(message: String)
@export var blueprints: Array[StructureData] = []
var sites: Array[ConstructionSite] = []
var bank: ResourceBank

func create_sites() -> void:
	for side: float in [-1.0, 1.0]:
		for data: StructureData in blueprints:
			var site: ConstructionSite = data.scene.instantiate() as ConstructionSite
			site.data = data
			site.position = Vector2(side * data.offset, GameRules.FLOOR_Y)
			sites.append(site)
			add_child(site)

func order(target: int) -> bool:
	if target < 0 or target >= sites.size():
		return false
	var site: ConstructionSite = sites[target]
	if site.ordered or site.hp == site.max_hp:
		return false
	var cost: int = site.cost if site.hp == 0 else site.data.repair_cost
	if bank.scrap < cost:
		notice_requested.emit("Falta chatarra")
		return false
	if site.hp == 0 and bank.energy_used() + site.data.energy > bank.energy_capacity:
		notice_requested.emit("Falta energía")
		return false
	bank.spend(cost)
	site.ordered = true
	site.progress = 0.0
	notice_requested.emit("Obra encargada")
	return true

func damage_site(index: int, amount: int) -> void:
	sites[index].take_damage(amount)
