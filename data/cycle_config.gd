class_name CycleConfig
extends Resource

@export var day_duration: float = 90.0
## Día de fundación (día 1 de cada colonia): levantar murallas, generador, núcleo Nv.2 y torretas.
## 0 = igual que los demás días.
@export var first_day_duration: float = 0.0
@export var warning_duration: float = 10.0
@export var night_duration: float = 60.0
@export var nights: int = 3
@export var dawn_scrap: int = 25
@export var dawn_core_heal: int = 40
@export var dawn_player_health: int = 100

func day_length(day: int) -> float:
	return first_day_duration if day <= 1 and first_day_duration > 0.0 else day_duration
