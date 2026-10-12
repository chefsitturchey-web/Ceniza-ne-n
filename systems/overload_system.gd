class_name OverloadSystem
extends Node

signal changed(left_active: bool, right_active: bool)
signal notice_requested(message: String)
var bank: ResourceBank
var player: Player
var overload_left: float = 0.0
var overload_right: float = 0.0
var cooldown_left: float = 0.0
var cooldown_right: float = 0.0

func tick(delta: float) -> void:
	overload_left = maxf(0.0, overload_left - delta)
	overload_right = maxf(0.0, overload_right - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)
	cooldown_right = maxf(0.0, cooldown_right - delta)
	changed.emit(overload_left > 0.0, overload_right > 0.0)

func overloaded(x: float) -> bool:
	return overload_left > 0.0 if x < 0.0 else overload_right > 0.0

func activate_overload() -> void:
	var left: bool = player.position.x < 0.0
	if (cooldown_left if left else cooldown_right) > 0.0:
		notice_requested.emit("Ese frente está enfriándose.")
		return
	if bank.energy_used() == 0:
		notice_requested.emit("Construye una torreta para utilizar la sobrecarga.")
		return
	if left:
		overload_left = GameRules.OVERLOAD_DURATION
		cooldown_left = GameRules.OVERLOAD_COOLDOWN
	else:
		overload_right = GameRules.OVERLOAD_DURATION
		cooldown_right = GameRules.OVERLOAD_COOLDOWN
	changed.emit(overload_left > 0.0, overload_right > 0.0)
	notice_requested.emit("Sobrecarga: seis segundos de disparo y trabajo acelerados.")

func overload_status(left: bool) -> String:
	var active: float = overload_left if left else overload_right
	var cooldown: float = cooldown_left if left else cooldown_right
	if active > 0.0:
		return "ACTIVA %ds" % ceili(active)
	return "%ds" % ceili(cooldown) if cooldown > 0.0 else "LISTA"
