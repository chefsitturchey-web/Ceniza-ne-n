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

func _ready() -> void:
	visual = WorkerVisual.new()
	visual.actor = self
	add_child(visual)
	visual.bind(get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D)
	visual.play_visual(&"reposo")

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
