class_name InteractionSystem
extends Node

signal notice_requested(message: String)
var construction: ConstructionSystem
var colony: ColonySystem
var cycle: CycleSystem
var bank: ResourceBank
var player: Player
var hold_time: float = 0.0
var hold_target: int = GameRules.NO_TARGET

func interaction_target() -> int:
	if absf(player.position.x) < GameRules.CORE_INTERACT_RANGE:
		return -1
	var best: int = GameRules.NO_TARGET
	var distance: float = GameRules.SITE_INTERACT_RANGE
	for index: int in range(construction.sites.size()):
		var candidate: float = absf(player.position.x - construction.sites[index].x)
		if candidate < distance:
			distance = candidate
			best = index
	return best

func update_interaction(delta: float) -> void:
	var target: int = interaction_target()
	if target != hold_target or not Input.is_action_pressed("interact") or player.health <= 0:
		hold_time = 0.0
		hold_target = target
		return
	if target == GameRules.NO_TARGET:
		return
	hold_time += delta
	if hold_time >= GameRules.INTERACT_HOLD:
		perform_interaction(target)
		hold_time = 0.0

func perform_interaction(target: int) -> bool:
	if target == -1:
		if cycle.phase != "DÍA":
			notice_requested.emit("Solo de día")
			return false
		if player.health < Player.MAX_HEALTH:
			player.health = Player.MAX_HEALTH
			notice_requested.emit("Salud restaurada")
			return true
		if colony.workers.size() >= GameRules.POPULATION:
			notice_requested.emit("Colonia completa")
			return false
		var data: WorkerData = colony.builder_data if colony.workers.size() == GameRules.INITIAL_POPULATION else colony.collector_data
		if bank.scrap < data.cost:
			notice_requested.emit("Necesitas %d chatarra" % data.cost)
			return false
		bank.spend(data.cost)
		colony.add_worker(data.id)
		notice_requested.emit("Habitante reclutado")
		return true
	return construction.order(target)
