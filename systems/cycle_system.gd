class_name CycleSystem
extends Node

signal dawn(config: CycleConfig)
signal phase_changed(phase: String, day: int)
signal victory_requested
signal notice_requested(message: String)
@export var config: CycleConfig
var director: SiegeDirector
var day: int = 1
var phase: String = "DÍA"
var phase_remaining: float = 0.0

func initialize() -> void:
	phase_remaining = config.day_duration

func update_phase(delta: float) -> void:
	phase_remaining = maxf(0.0, phase_remaining - delta)
	if phase == "NOCHE":
		director.tick(delta)
	if phase_remaining > 0.0:
		return
	var previous_phase: String = phase
	if phase == "DÍA":
		phase = "AVISO"
		phase_remaining = config.warning_duration
		notice_requested.emit("¡Ataque por ambos frentes! Los recuperadores regresan.")
	elif phase == "AVISO":
		phase = "NOCHE"
		phase_remaining = config.night_duration
		director.start(day)
	elif director.is_cleared():
		if day == config.nights:
			victory_requested.emit()
		else:
			day += 1
			phase = "DÍA"
			phase_remaining = config.day_duration
			dawn.emit(config)
			notice_requested.emit("Amanecer: +25 chatarra. Repara y prepara el siguiente asedio.")
	if phase != previous_phase:
		phase_changed.emit(phase, day)
