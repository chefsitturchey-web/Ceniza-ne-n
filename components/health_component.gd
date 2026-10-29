class_name HealthComponent
extends Node

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
signal died
@export var maximum: int = 100
var current: int = 100
var debug_invincible: bool = false

func reset(value: int = -1) -> void:
	current = maximum if value < 0 else clampi(value, 0, maximum)

func take_damage(amount: int) -> void:
	if debug_invincible or amount <= 0 or current <= 0:
		return
	var applied: int = mini(amount, current)
	current -= applied
	damaged.emit(applied, current)
	if current == 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0 or current <= 0:
		return
	var applied: int = mini(amount, maximum - current)
	if applied > 0:
		current += applied
		healed.emit(applied, current)
