class_name SessionController
extends Node

signal finished_changed(won: bool)
signal frame_finished
var cycle: CycleSystem
var bank: ResourceBank
var core: ColonyCore
var player: Player
var colony: ColonySystem
var defenses: DefenseSystem
var interaction: InteractionSystem
var overload: OverloadSystem
var presenter: HudPresenter
var expedition: ExpeditionManager
var finished: bool = false
var won: bool = false
var persistence_enabled: bool = true
var debug_practice: bool = false
var save_system: SaveSystem
var neural: NeuralSystem
var clinic_panel: ClinicPanel
var options: SettingsPanel
var briefing: BriefingPanel
var zone_index: int = 0
var campaign: Dictionary = CampaignRoute.initial_state()
var terrain: ZoneHazards
var expansion: ExpansionSystem
var experience: ExperienceSystem
var civic: CivicSystem
var corpse_system: CorpseSystem
var pest_system: PestSystem
var trap_system: TrapSystem

func initialize() -> void:
	var debugger: Node = get_node_or_null("/root/DebugTools")
	if debugger != null and debugger.consume_practice_launch(get_parent()): return
	var transfer: Dictionary = CampaignRoute.take(zone_index)
	if not transfer.is_empty():
		persistence_enabled = transfer.persistence
		var importer: SaveSystem = SaveSystem.new()
		importer.session = self
		importer.save_path = transfer.path
		add_child(importer)
		importer.apply_handoff(transfer.data)
		if persistence_enabled:
			save_system = importer
			cycle.phase_changed.connect(on_phase_changed)
			save_system.save_game()
		else:
			importer.queue_free()
		presenter.show_notice("Llegada a " + CampaignRoute.zone(zone_index).title)
		return
	if not persistence_enabled:
		return
	if save_system == null:
		save_system = SaveSystem.new()
		if not CampaignRoute.resume_path.is_empty():
			save_system.save_path = CampaignRoute.resume_path
			CampaignRoute.resume_path = ""
		add_child(save_system)
	save_system.session = self
	cycle.phase_changed.connect(on_phase_changed)
	if save_system.has_save():
		var info: Dictionary = SaveSystem.checkpoint_info(save_system.save_path)
		if not info.is_empty() and info.get("zone", 0) != zone_index:
			presenter.show_notice("Vista de otra zona: guardado conservado")
			save_system = null
			persistence_enabled = false
			return
		if save_system.load_game():
			save_system.save_game()
			presenter.show_notice("Partida cargada")
			return
		# La copia precede al nuevo guardado: un documento inválido no se pierde.
		if not SaveSystem.archive_checkpoint(save_system.save_path, false):
			presenter.show_notice("Guardado no válido: no se sobrescribirá")
			save_system = null
			persistence_enabled = false
			return
	on_phase_changed(cycle.phase, cycle.day)

func on_phase_changed(phase: String, _day: int) -> void:
	if phase == "DÍA" and save_system != null and save_system.save_game():
		presenter.show_notice("Partida guardada")

func restart() -> void:
	if save_system != null:
		CampaignRoute.resume_path = save_system.save_path
	if save_system != null and won:
		save_system.delete_save()
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func resume_game() -> void:
	get_tree().paused = false
	GamePreferences.current().block_gameplay_input()
	presenter.publish()

func _process(delta: float) -> void:
	if interaction.equipment_shop != null and (interaction.equipment_shop.opened or interaction.equipment_shop.closed_frame == Engine.get_process_frames()): return
	if GamePreferences.current().debug_input_blocked(): return
	if interaction.story != null and (interaction.story.novel.opened or interaction.story.novel.closed_frame == Engine.get_process_frames()): return
	if interaction.story != null and (interaction.story.journal.opened or interaction.story.journal.closed_frame == Engine.get_process_frames()): return
	if experience != null and experience.panel.opened: return
	if briefing != null and (briefing.opened or briefing.closed_frame == Engine.get_process_frames()):
		return
	if options != null and (options.opened or options.closed_frame == Engine.get_process_frames()):
		return
	if clinic_panel != null and clinic_panel.opened:
		return
	if clinic_panel != null and clinic_panel.closed_frame == Engine.get_process_frames():
		return
	if expedition != null and expedition.active:
		return
	if Input.is_action_just_pressed("restart") and finished:
		restart()
		return
	if Input.is_action_just_pressed("pause") and not finished:
		get_tree().paused = not get_tree().paused
		if not get_tree().paused:
			GamePreferences.current().block_gameplay_input()
	if get_tree().paused or finished:
		presenter.publish()
		return
	if core.tier > 0 and core.health <= 0:
		finish(false)
		return
	presenter.tick(delta)
	if experience != null:
		experience.tick(delta)
		if get_tree().paused: return
	overload.tick(delta)
	if core.tier > 0: cycle.update_phase(delta)
	if finished:
		return
	colony.update_workers(delta)
	var world: District = get_parent() as District
	if world != null and world.frontier != null: world.frontier.tick(delta)
	if world != null and world.settlements != null: world.settlements.tick(delta)
	if corpse_system != null:
		corpse_system.tick(delta)
	if trap_system != null:
		trap_system.tick(delta)
	if pest_system != null:
		pest_system.tick(delta)
	if civic != null and Input.is_action_just_pressed("escort"):
		civic.advance_side = 0 if civic.advance_side != 0 else (-1 if player.position.x < 0 else 1)
		presenter.show_notice("Escolta: retirada" if civic.advance_side == 0 else "Escolta: atacar entrada del frente")
	if civic != null: civic.tick(delta)
	if interaction.story != null: interaction.story.tick(delta)
	if interaction.mobility != null: interaction.mobility.tick(delta)
	if expansion != null:
		expansion.tick(delta)
	if terrain != null:
		terrain.tick(delta)
	defenses.update_defenses(delta)
	interaction.update_interaction(delta)
	if Input.is_action_just_pressed("toggle_power") and player.health > 0:
		var target: int = interaction.interaction_target()
		if target >= 0 and target < interaction.construction.sites.size():
			interaction.construction.toggle_power(interaction.construction.sites[target])
	if expedition != null and expedition.active:
		return
	if Input.is_action_just_pressed("overload") and player.health > 0:
		overload.activate_overload()
	defenses.update_beams(delta)
	presenter.publish()
	frame_finished.emit()

func on_dawn(config: CycleConfig) -> void:
	bank.deposit(config.dawn_scrap)
	core.health_component.heal(config.dawn_core_heal)
	player.health = config.dawn_player_health

func win() -> void:
	finish(true)

func finish(victory: bool) -> void:
	if save_system != null and victory:
		save_system.delete_save()
	finished = true
	won = victory
	player.enabled = false
	presenter.publish()
	finished_changed.emit(won)
	frame_finished.emit()
