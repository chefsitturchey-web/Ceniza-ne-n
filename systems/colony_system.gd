class_name ColonySystem
extends Node

signal worker_added(worker: ColonyWorker)
@export var builder_data: WorkerData
@export var collector_data: WorkerData
var workers: Array[ColonyWorker] = []
var sites: Array[ConstructionSite] = []
var cycle: CycleSystem
var bank: ResourceBank
var overload: OverloadSystem

func add_worker(role: StringName) -> void:
	var data: WorkerData = builder_data if role == &"builder" else collector_data
	var worker: ColonyWorker = data.scene.instantiate() as ColonyWorker
	worker.data = data
	worker.side = -1.0 if workers.size() < GameRules.INITIAL_POPULATION else 1.0
	worker.position.y = GameRules.FLOOR_Y
	workers.append(worker)
	add_child(worker)
	worker_added.emit(worker)

func update_workers(delta: float) -> void:
	for index: int in range(workers.size()):
		var worker: ColonyWorker = workers[index]
		var previous_x: float = worker.x
		if worker.role == "collector":
			var gather_destination: float = worker.side * worker.data.gather_distance if cycle.phase == "DÍA" and worker.cargo == 0 else worker.side * worker.data.home_distance
			worker.x = move_toward(worker.x, gather_destination, worker.data.speed * delta)
			if absf(worker.x - gather_destination) < GameRules.GATHER_ARRIVAL_DISTANCE:
				if absf(gather_destination) > GameRules.COLLECTOR_OUTSIDE_THRESHOLD:
					worker.gather += delta
					if worker.gather >= worker.data.gather_time:
						worker.cargo = worker.data.cargo
						worker.gather = 0.0
				else:
					bank.deposit(worker.cargo)
					worker.cargo = 0
			worker.update_visual(previous_x, false)
			continue
		# Una reserva por obra impide que los constructores dupliquen tareas.
		if worker.job >= 0:
			var job: ConstructionSite = sites[worker.job]
			if not job.ordered or unsafe_at(job.x):
				worker.job = -1
		if worker.job == -1:
			for site_index: int in range(sites.size()):
				if not sites[site_index].ordered or unsafe_at(sites[site_index].x):
					continue
				var reserved: bool = false
				for other: ColonyWorker in workers:
					if other.job == site_index:
						reserved = true
				if not reserved:
					worker.job = site_index
					break
		var destination: float = worker.side * worker.data.home_distance
		if worker.job >= 0:
			destination = sites[worker.job].x
		worker.x = move_toward(worker.x, destination, worker.data.speed * delta)
		if worker.job >= 0 and absf(worker.x - destination) < GameRules.BUILD_ARRIVAL_DISTANCE:
			var job: ConstructionSite = sites[worker.job]
			job.progress += delta * (GameRules.OVERLOAD_WORK_RATE if overload.overloaded(job.x) else 1.0)
			if job.progress >= GameRules.BUILD_TIME:
				job.complete_work()
				worker.job = -1

		worker.update_visual(previous_x, worker.job >= 0 and absf(worker.x - destination) < GameRules.BUILD_ARRIVAL_DISTANCE)

func unsafe_at(x: float) -> bool:
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if absf(enemy.position.x - x) < GameRules.UNSAFE_RANGE:
			return true
	return false
