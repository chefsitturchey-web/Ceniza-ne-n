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
var save_system: SaveSystem
var neural: NeuralSystem
var clinic_panel: ClinicPanel
var options: SettingsPanel
var briefing: BriefingPanel

func initialize() -> void:
	if not persistence_enabled:
		return
	if save_system == null:
		save_system = SaveSystem.new()
		add_child(save_system)
	save_system.session = self
	cycle.phase_changed.connect(on_phase_changed)
	if save_system.has_save():
		if save_system.load_game():
			presenter.show_notice("Partida cargada")
			return
		# La copia precede al nuevo guardado: un documento inválido no se pierde.
		if not SaveSystem.archive_checkpoint(save_system.save_path, false):
			presenter.show_notice("Guardado no válido: no se sobrescribirá")
			save_system = null
			return
	on_phase_changed(cycle.phase, cycle.day)

func on_phase_changed(phase: String, _day: int) -> void:
	if phase == "DÍA" and save_system != null and save_system.save_game():
		presenter.show_notice("Partida guardada")

func restart() -> void:
	if save_system != null:
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
	if core.health <= 0:
		finish(false)
		return
	presenter.tick(delta)
	overload.tick(delta)
	cycle.update_phase(delta)
	if finished:
		return
	colony.update_workers(delta)
	defenses.update_defenses(delta)
	interaction.update_interaction(delta)
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
	if save_system != null:
		save_system.delete_save()
	finished = true
	won = victory
	player.enabled = false
	presenter.publish()
	finished_changed.emit(won)
	frame_finished.emit()
