class_name ColonyWorker
extends Node2D

@export var data: WorkerData
var job: int = -1
var external_job: int = -1
var gather: float = 0.0
var cargo: int = 0
var side: float = -1.0
var visual: WorkerVisual
var x: float:
	get: return position.x
	set(value): position.x = value
var role: StringName:
	get: return data.id
var health_component: HealthComponent
var damage_accum: float = 0.0
var wander_target: float = 0.0
var wander_timer: float = 0.0
var hp: int:
	get: return health_component.current

func _ready() -> void:
	health_component = HealthComponent.new()
	health_component.maximum = GameRules.WORKER_HEALTH
	add_child(health_component)
	health_component.reset()
	visual = WorkerVisual.new()
	visual.actor = self
	add_child(visual)
	visual.bind(get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)
	visual.play_visual(&"reposo")

func apply_dps(dps: float, delta: float) -> void:
	damage_accum += dps * delta
	var whole: int = floori(damage_accum)
	if whole > 0:
		damage_accum -= whole
		health_component.take_damage(whole)

func update_visual(previous_x: float, working: bool) -> void:
	var moving: bool = not is_equal_approx(previous_x, x)
	visual.walking = moving
	visual.working = working and not moving
	if moving:
		visual.face(x < previous_x)
	var colony: ColonySystem = get_parent() as ColonySystem
	visual.fleeing = colony != null and colony.unsafe_at(previous_x)
	visual.refresh_state()
	visual.queue_redraw()
