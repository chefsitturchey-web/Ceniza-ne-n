class_name HudPresenter
extends Node

const INITIAL_NOTICE_DURATION: float = 7.0
const NOTICE_DURATION: float = 4.0
signal updated(text: String, hint: String, result: String)
var player: Player
var cycle: CycleSystem
var bank: ResourceBank
var core: ColonyCore
var colony: ColonySystem
var construction: ConstructionSystem
var overload: OverloadSystem
var interaction: InteractionSystem
var session: SessionController
var notice: String = "Construye ambas murallas y torretas antes de la noche."
var notice_time: float = INITIAL_NOTICE_DURATION

func tick(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)

func show_notice(message: String) -> void:
	notice = message
	notice_time = NOTICE_DURATION

func publish() -> void:
	var left_count: int = 0
	var right_count: int = 0
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if enemy.position.x < 0:
			left_count += 1
		else:
			right_count += 1
	var text: String = "CENIZA NEÓN  |  %s %d/%d · %ds  |  Chatarra %d  |  Energía %d/%d\n" % [cycle.phase, cycle.day, cycle.config.nights, ceili(cycle.phase_remaining), bank.scrap, bank.energy_used(), bank.energy_capacity]
	text += "Vida %d  ·  Resistencia %d  ·  Núcleo %d/%d  ·  Habitantes %d/%d\n" % [player.health, int(player.stamina), core.health, GameRules.CORE_HEALTH, colony.workers.size(), GameRules.POPULATION]
	text += "Amenazas  ◀ %d / %d ▶  |  Sobrecarga IZQ %s / DER %s\n" % [left_count, right_count, overload.overload_status(true), overload.overload_status(false)]
	text += "A/D mover · J ataque · Espacio esquiva · E obra · Q sobrecarga · Esc pausa"
	var context: String = "Defiende el núcleo. Sobrevive a tres noches."
	var target: int = interaction.interaction_target()
	if target == -1:
		context = "Mantén E: curarte / reclutar (15 chatarra, solo de día)."
	elif target >= 0:
		var site: ConstructionSite = construction.sites[target]
		var title: String = site.data.display_name
		if site.data.energy > 0:
			title += " (%d energía)" % site.data.energy
		if site.ordered:
			context = "%s · Obra %d%% · Esperando trabajo seguro" % [title, int(site.progress / GameRules.BUILD_TIME * 100)]
		elif site.hp == site.max_hp:
			context = "%s · %d/%d de integridad" % [title, site.hp, site.max_hp]
		else:
			context = "%s · Mantén E: %s (%d chatarra)" % [title, "construir" if site.hp == 0 else "reparar", site.cost if site.hp == 0 else site.data.repair_cost]
	if interaction.hold_time > 0.0:
		context += "  %d%%" % int(interaction.hold_time / GameRules.INTERACT_HOLD * 100)
	var hint_text: String = context + "\n" + (notice if notice_time > 0.0 else "Mando: X ataque · A esquiva · Y obra · LB sobrecarga · Start pausa")
	var result_text: String = ""
	if player.health <= 0:
		result_text = "Reenlace en %d s\n¡La colonia sigue defendiéndose!" % ceili(player.respawn_remaining)
	if get_tree().paused:
		result_text = "PAUSA\nEsc / Start para continuar"
	if session.finished:
		result_text = ("DISTRITO ESTABILIZADO" if session.won else "NÚCLEO DESTRUIDO") + "\n\nR / Select: nueva partida"
	updated.emit(text, hint_text, result_text)
