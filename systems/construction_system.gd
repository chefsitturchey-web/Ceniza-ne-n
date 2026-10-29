class_name ConstructionSystem
extends Node

signal notice_requested(message: String)
@export var blueprints: Array[StructureData] = []
var sites: Array[ConstructionSite] = []
var bank: ResourceBank
var external_sites: Array[ConstructionSite] = []
var viewer: Player
var core: ColonyCore

func defensive_sites() -> Array[ConstructionSite]:
	var result: Array[ConstructionSite] = sites.duplicate()
	result.append_array(external_sites)
	return result

func create_sites() -> void:
	for side: float in [-1.0, 1.0]:
		for data: StructureData in blueprints:
			var site: ConstructionSite = data.scene.instantiate() as ConstructionSite
			site.data = data
			site.viewer = viewer
			site.core = core
			site.z_index = -1
			site.position = Vector2(side * data.offset, GameRules.FLOOR_Y)
			sites.append(site)
			add_child(site)

func order(target: int) -> bool:
	if target < 0 or target >= sites.size():
		return false
	var site: ConstructionSite = sites[target]
	return order_site(site)

func order_site(site: ConstructionSite) -> bool:
	var upgrade: bool = site.hp == site.max_hp and site.tier < 3
	if upgrade and core != null and site.tier >= core.tier:
		notice_requested.emit("Necesitas núcleo Nv.%d para mejorar esta defensa" % (site.tier + 1))
		return false
	if site.ordered or (site.hp == site.max_hp and not upgrade):
		return false
	var cost: int = site.tier * 25 if upgrade else (site.cost if site.hp == 0 else site.data.repair_cost)
	if bank.scrap < cost:
		notice_requested.emit("Falta chatarra")
		return false
	if site.hp == 0 and site.data.energy > 0 and bank.energy_used() + site.data.energy > bank.available_capacity():
		notice_requested.emit("Falta energía")
		return false
	bank.spend(cost)
	site.ordered = true
	site.upgrade_pending = upgrade
	site.progress = 0.0
	notice_requested.emit("Obra encargada")
	return true

func toggle_power(site: ConstructionSite) -> bool:
	if site.kind != &"turret" or site.hp <= 0 or site.ordered: return false
	if not site.powered and bank.energy_used() + site.data.energy > bank.available_capacity():
		notice_requested.emit("Falta energía para reactivar")
		return false
	site.powered = not site.powered
	bank.changed.emit(bank.scrap, bank.energy_used(), bank.available_capacity())
	notice_requested.emit("Torreta activa" if site.powered else "Energía de torreta liberada")
	return true

func damage_site(index: int, amount: int) -> void:
	defensive_sites()[index].take_damage(amount)
