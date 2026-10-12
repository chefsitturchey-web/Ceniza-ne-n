class_name WaveData
extends Resource

@export var enemies: Array[EnemyData] = []
@export var sides: Array[float] = []
# Conserva la operación original y su redondeo; evita adelantar un tick de simulación.
@export var cadence_base: float = 2.2
@export var cadence_decrement: float = 0.4
@export var cadence_steps: int = 1
var cadence: float:
	get: return cadence_base - cadence_steps * cadence_decrement
