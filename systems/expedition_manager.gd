class_name ExpeditionManager
extends Node

const ARENA: PackedScene = preload("res://levels/expedition/boss_stub.tscn")
var district: District
var station: RailwayStation
var repeaters: Array[EnemyRepeater] = []
var arena: CanvasLayer
var suspended: Dictionary = {}
var active: bool = false

func setup(world: District) -> void:
	district = world
	station = world.get_node("Station") as RailwayStation
	for path: String in ["LeftRepeater", "RightRepeater"]:
		var repeater: EnemyRepeater = world.get_node(path) as EnemyRepeater
		repeaters.append(repeater)
		repeater.destroyed.connect(_repeater_destroyed)

func _repeater_destroyed() -> void:
	district.presenter.show_notice("Repetidor destruido")
	if all_destroyed():
		station.unlocked = true
		# Deja visible el aviso del segundo repetidor antes del aviso del tren.
		notice_delay = 1.2

var notice_delay: float = 0.0
func _process(delta: float) -> void:
	if notice_delay > 0:
		notice_delay -= delta
		if notice_delay <= 0:
			district.presenter.show_notice("Tren en camino")

func all_destroyed() -> bool:
	return repeaters.all(func(repeater: EnemyRepeater) -> bool: return repeater.health.current == 0)

func can_travel() -> bool:
	return not active and all_destroyed() and station.train_arrived and district.cycle.phase == "DÍA" and not district.session.finished and district.player.health > 0 and not get_tree().paused

func start() -> bool:
	if not can_travel():
		return false
	active = true
	arena = ARENA.instantiate() as CanvasLayer
	arena.resolved.connect(resolve)
	arena.continued.connect(continue_district)
	# Hermana del distrito: no hereda la suspension ni la camara del mundo.
	district.get_parent().add_child(arena)
	_suspend(district)
	district.hide()
	district.get_node("HUD").hide()
	return true

func _suspend(node: Node) -> void:
	suspended[node] = node.process_mode
	node.process_mode = Node.PROCESS_MODE_DISABLED
	for child: Node in node.get_children():
		_suspend(child)

func resolve(victory: bool) -> void:
	if not active:
		return
	if victory:
		if district.session.save_system != null:
			district.session.save_system.delete_save()
		arena.show_completed()
		return
	arena.queue_free()
	arena = null
	for node: Node in suspended:
		node.process_mode = suspended[node]
	suspended.clear()
	active = false
	district.show()
	district.get_node("HUD").show()

func continue_district() -> void:
	arena.queue_free()
	district.session.restart()

func snapshot() -> Dictionary:
	return {"destroyed": [repeaters[0].health.current == 0, repeaters[1].health.current == 0], "train_arrived": station.train_arrived}

func restore(data: Dictionary) -> void:
	for index: int in range(2):
		repeaters[index].restore(data.get("destroyed", [false, false])[index])
	station.restore(all_destroyed(), data.get("train_arrived", false))
	notice_delay = 0

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var broken: Variant = data.get("destroyed", [false, false])
	var parked: Variant = data.get("train_arrived", false)
	return broken is Array and broken.size() == 2 and broken[0] is bool and broken[1] is bool and parked is bool and (not parked or (broken[0] and broken[1]))
