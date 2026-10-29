class_name PropData
extends Resource

## Data-driven definition of a lootable prop in the district.

@export var id: StringName
@export var label: String
@export var charges: int = 1
@export var work_time: float = 2.5
@export var parts_per_charge: int = 3
@export var scrap_per_charge: int = 2
@export var size: Vector2 = Vector2(16, 14)
@export var fill: Color = Color(0.19, 0.22, 0.34)
