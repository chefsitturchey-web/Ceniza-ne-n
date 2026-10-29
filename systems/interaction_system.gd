class_name InteractionSystem
extends Node

signal notice_requested(message: String)
const STATION_TARGET: int = -2
const CLINIC_TARGET: int = -3
var clinic: NeuralClinic
var clinic_panel: ClinicPanel
var expedition: ExpeditionManager
var construction: ConstructionSystem
var colony: ColonySystem
var cycle: CycleSystem
var bank: ResourceBank
var player: Player
var expansion: ExpansionSystem
var civic: CivicSystem
var story: StoryDirector
var mobility: MobilitySystem
var scavenge: ScavengeSystem
const MOBILITY_TARGET: int = -5
var committed_target: int = GameRules.NO_TARGET
var hold_time: float = 0.0
var hold_target: int = GameRules.NO_TARGET

func interaction_target() -> int:
	if story != null:
		var story_target: int = story.target_at(player.position.x)
		if story_target != GameRules.NO_TARGET: return story_target
	if civic != null:
		var civic_target: int = civic.target_at(player.position.x)
		if civic_target != GameRules.NO_TARGET: return civic_target
	if clinic != null and absf(player.position.x - clinic.position.x) < 30:
		return CLINIC_TARGET
	if expedition != null and absf(player.position.x - expedition.station.position.x) < 55:
		return STATION_TARGET
	if absf(player.position.x) < GameRules.CORE_INTERACT_RANGE:
		return -1
	if expansion != null:
		var expansion_target: int = expansion.target_at(player.position.x)
		if expansion_target != GameRules.NO_TARGET:
			return expansion_target
	var best: int = GameRules.NO_TARGET
	var distance: float = GameRules.SITE_INTERACT_RANGE
	for index: int in range(construction.sites.size()):
		var candidate: float = absf(player.position.x - construction.sites[index].x)
		if candidate < distance:
			distance = candidate
			best = index
	var prop_target: int = scavenge.target_at(player.position.x) if scavenge != null else GameRules.NO_TARGET
	if prop_target != GameRules.NO_TARGET: return prop_target
	if best == GameRules.NO_TARGET and mobility != null and mobility.target_at(player.position.x): return MOBILITY_TARGET
	return best

func update_interaction(delta: float) -> void:
	for site: ConstructionSite in construction.defensive_sites(): site.payment_fraction = 0
	var target: int = interaction_target()
	if target != committed_target or not Input.is_action_pressed("interact"): committed_target = GameRules.NO_TARGET
	if target != hold_target or not Input.is_action_pressed("interact") or player.health <= 0:
		hold_time = 0.0
		hold_target = target
		return
	if committed_target == target: return
	if target == GameRules.NO_TARGET:
		return
	hold_time += delta
	if target >= 0 and target < construction.sites.size(): construction.sites[target].payment_fraction = hold_time / GameRules.INTERACT_HOLD
	elif target <= -340 and target > -346 and civic != null: civic.walls[-340 - target].payment_fraction = hold_time / GameRules.INTERACT_HOLD
	if hold_time >= GameRules.INTERACT_HOLD:
		perform_interaction(target)
		committed_target = target
		hold_time = 0.0

func perform_interaction(target: int) -> bool:
	if target == MOBILITY_TARGET and mobility != null: return mobility.interact()
	if target <= -400 and target >= -402 and story != null: return story.interact(target)
	if target <= -500:
		return scavenge.interact(target) if scavenge != null else false
	if target <= -300 and civic != null: return civic.interact(target)
	if expansion != null and target <= -100:
		return expansion.interact(target)
	if target == CLINIC_TARGET:
		if cycle.phase != "DÍA":
			notice_requested.emit("Clínica disponible de día")
			return false
		return clinic_panel != null and clinic_panel.open_panel()
	if target == STATION_TARGET:
		return expedition != null and expedition.start()
	if target == -1:
		if cycle.phase != "DÍA":
			notice_requested.emit("Solo de día")
			return false
		if player.health < Player.MAX_HEALTH:
			player.health = Player.MAX_HEALTH
			notice_requested.emit("Salud restaurada")
			return true
		if colony.core != null: return colony.core.request_upgrade()
		if colony.workers.size() >= GameRules.POPULATION:
			notice_requested.emit("Colonia completa")
			return false
		if civic != null:
			notice_requested.emit("Recluta en los campamentos; paga herramientas en el taller")
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
