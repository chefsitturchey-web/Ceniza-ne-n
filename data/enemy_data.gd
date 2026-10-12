class_name EnemyData
extends Resource

@export var id: StringName
@export var health: int = 100
@export var health_per_night: int = 20
@export var speed: float = 32.0
@export var damage: int = 12
@export var reward: int = 3
@export var windup: float = 0.5
@export var cooldown: float = 1.1
@export var attack_visual_duration: float = 1.6
@export var hurt_duration: float = 0.32
@export var flash_duration: float = 0.12
@export var player_notice_range: float = 30.0
@export var player_hit_range: float = 38.0
@export var wall_range: float = 24.0
@export var core_range: float = 35.0
@export var spawn_distance: float = 650.0
@export var scene: PackedScene
@export var move_animation: StringName = &"caminar"
@export var provisional_color: Color = Color("dd6482")
@export var provisional_height: float = 30.0
