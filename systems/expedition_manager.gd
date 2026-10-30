class_name ExpeditionManager
extends Node

const ARENA: PackedScene = preload("res://levels/expedition/recaudador_arena.tscn")
var district: District
var station: RailwayStation
var repeaters: Array[EnemyRepeater] = []
var arena: CanvasLayer
var suspended: Dictionary = {}
var active: bool = false
var victory_resolved: bool = false
var next_checkpoint: Dictionary = {}

func setup(world: District) -> void:
	district = world
	station = world.get_node("Station") as RailwayStation
	station.arrived.connect(func() -> void: district.play("train_arrive"))
	for path: String in ["LeftRepeater", "RightRepeater"]:
		var repeater: EnemyRepeater = world.get_node(path) as EnemyRepeater
		repeaters.append(repeater)
		repeater.destroyed.connect(_repeater_destroyed)

func _repeater_destroyed() -> void:
	district.presenter.show_notice("Repetidor destruido")
	district.play("portal_destroyed")
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
	return repeaters.all(func(repeater: EnemyRepeater) -> bool: return repeater.health.current == 0) and (district.civic == null or district.civic.gates.all(func(gate: EnemyRepeater) -> bool: return gate.health.current == 0))

func can_travel() -> bool:
	if district.story != null and not district.story.ready_to_travel(): return false
	return not active and all_destroyed() and station.train_arrived and district.cycle.phase == "DÍA" and (district.civic == null or district.civic.stabilized()) and not district.session.finished and district.player.health > 0 and not get_tree().paused

func start() -> bool:
	if not can_travel():
		return false
	if district.session.save_system != null:
		district.session.save_system.save_game()
	active = true
	district.experience.hud.hide()
	if district.story != null: district.story.hud.hide()
	if district.mobility != null: district.mobility.hud.hide()
	victory_resolved = false
	arena = ARENA.instantiate() as CanvasLayer
	arena.configure(district.player, district.zone_index)
	arena.resolved.connect(resolve)
	arena.continued.connect(continue_district)
	arena.menu_requested.connect(leave_to_menu)
	# Hermana del distrito: no hereda la suspension ni la camara del mundo.
	district.get_parent().add_child(arena)
	_suspend(district)
	district.hide()
	district.get_node("HUD").hide()
	return true

func _suspend(node: Node) -> void:
	if node is GameSound:
		return
	suspended[node] = node.process_mode
	node.process_mode = Node.PROCESS_MODE_DISABLED
	for child: Node in node.get_children():
		_suspend(child)

func resolve(victory: bool) -> void:
	if not active:
		return
	if victory:
		if victory_resolved:
			return
		victory_resolved = true
		district.experience.gain(40)
		district.modules.cores += 1
		if district.zone_index < CampaignRoute.COUNT - 1:
			next_checkpoint = CampaignRoute.handoff(district.zone_index + 1, district.neural.snapshot(), district.bank.scrap, district.colony.workers, district.mobility.snapshot())
			var saved: bool = true
			if district.session.save_system != null:
				saved = district.session.save_system.save_handoff(next_checkpoint)
			arena.show_completed(CampaignRoute.zone(district.zone_index + 1).title)
			if not saved:
				arena.label("Avance en memoria: no se pudo guardar en disco.", Rect2(50, 275, 540, 20))
		else:
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
	district.experience.hud.show()
	if district.story != null: district.story.hud.show()
	if district.mobility != null: district.mobility.hud.show()
	district.get_node("HUD").show()

func continue_district() -> void:
	if next_checkpoint.is_empty():
		leave_to_menu()
		return
	var path: String = district.session.save_system.save_path if district.session.save_system != null else "user://partida.json"
	CampaignRoute.queue_handoff(next_checkpoint, path, district.session.persistence_enabled)
	if arena != null:
		arena.queue_free()
		arena = null
	active = false
	get_tree().paused = false
	get_tree().change_scene_to_file(CampaignRoute.SCENES[district.zone_index + 1])

func _exit_tree() -> void:
	if is_instance_valid(arena):
		arena.queue_free()

func leave_to_menu() -> void:
	if arena != null:
		arena.queue_free()
		arena = null
	active = false
	get_tree().paused = false
	district.session.return_to_menu()

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
