class_name StructureData
extends Resource

@export var id: StringName
@export var display_name: String = "Muralla"
@export var cost: int = 20
@export var health: int = 240
@export var repair_cost: int = 8
@export var energy: int = 0
@export var offset: float = 240.0
@export var scene: PackedScene
## Sprite apoyado en el suelo; sin él se dibuja la forma provisional.
@export var texture: Texture2D
@export var blocks_enemies: bool = true
@export var attack_range: float = 0.0
@export var damage: int = 0
@export var interval: float = 1.1
@export var overloaded_interval: float = 0.35
