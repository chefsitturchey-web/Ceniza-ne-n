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
var finished: bool = false
var won: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart") and finished:
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pause") and not finished:
		get_tree().paused = not get_tree().paused
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
	finished = true
	won = victory
	player.enabled = false
	presenter.publish()
	finished_changed.emit(won)
	frame_finished.emit()
