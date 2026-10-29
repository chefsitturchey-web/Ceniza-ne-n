class_name ColonySystem
extends Node

signal worker_added(worker: ColonyWorker)
signal notice_requested(message: String)

const BURY_DURATION: float = 3.0

@export var builder_data: WorkerData
@export var collector_data: WorkerData
var workers: Array[ColonyWorker] = []
var sites: Array[ConstructionSite] = []
var cycle: CycleSystem
var bank: ResourceBank
var overload: OverloadSystem
var civic: CivicSystem
var core: ColonyCore
var corpse_system: CorpseSystem
## Corpse reported by the player that a builder must bury before resuming work.
var burial_target: Corpse

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
	var core_crew: int = 0
	var burial_crew: int = 0
	var dead: Array[ColonyWorker] = []
	for index: int in range(workers.size()):
		var worker: ColonyWorker = workers[index]
		_damage_from_enemies(worker, delta)
		if worker.hp <= 0:
			dead.append(worker)
			continue
		var previous_x: float = worker.x
		if worker.role == "collector":
			var gather_destination: float = worker.side * worker.data.gather_distance if cycle.phase == "DÍA" and worker.cargo == 0 else worker.side * worker.data.home_distance
			if unsafe_at(gather_destination): gather_destination = worker.side * worker.data.home_distance
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
			var gathering: bool = cycle.phase == "DÍA" and worker.cargo == 0 and absf(gather_destination) > GameRules.COLLECTOR_OUTSIDE_THRESHOLD and absf(worker.x - gather_destination) < GameRules.GATHER_ARRIVAL_DISTANCE
			worker.update_visual(previous_x, gathering)
			continue
		# Un solo constructor entierra; espera si el cadáver sigue en zona peligrosa.
		if burial_target != null and is_instance_valid(burial_target) and not burial_target.buried and burial_crew < 1 and not unsafe_at(burial_target.position.x):
			burial_crew += 1
			worker.job = -1
			worker.external_job = -1
			worker.x = move_toward(worker.x, burial_target.position.x, worker.data.speed * delta)
			var arrived: bool = absf(worker.x - burial_target.position.x) < GameRules.BUILD_ARRIVAL_DISTANCE
			if arrived:
				burial_target.bury_progress += delta
				if burial_target.bury_progress >= BURY_DURATION:
					burial_target.bury()
					burial_target = null
					notice_requested.emit("Muerto sepultado")
			worker.update_visual(previous_x, arrived)
			continue
		# Una reserva por obra impide que los constructores dupliquen tareas.
		if core != null and core.ordered and core_crew < 2 and not unsafe_at(core.position.x):
			core_crew += 1
			worker.job = -1
			worker.external_job = -1
			worker.x = move_toward(worker.x, core.position.x, worker.data.speed * delta)
			var arrived: bool = absf(worker.x - core.position.x) < GameRules.BUILD_ARRIVAL_DISTANCE
			if arrived:
				core.progress = minf(ColonyCore.BUILD_TIME, core.progress + delta)
				if core.progress >= ColonyCore.BUILD_TIME: core.complete_work()
			worker.update_visual(previous_x, arrived)
			continue
		if civic != null and worker.job == -1 and work_external(worker, delta):
			continue
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
	for worker: ColonyWorker in dead:
		if corpse_system != null:
			corpse_system.spawn(worker.position, &"worker", cycle.day)
		workers.erase(worker)
		worker.queue_free()

func _damage_from_enemies(worker: ColonyWorker, delta: float) -> void:
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if absf(enemy.position.x - worker.x) < GameRules.UNSAFE_RANGE:
			worker.apply_dps(GameRules.WORKER_DANGER_DPS, delta)
			break

func unsafe_at(x: float) -> bool:
	if civic != null and cycle.phase != "DÍA" and absf(x) > civic.frontier(signf(x)): return true
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if absf(enemy.position.x - x) < GameRules.UNSAFE_RANGE:
			return true
	return false

func work_external(worker: ColonyWorker, delta: float) -> bool:
	for base: ConstructionSite in sites:
		if base.ordered and not unsafe_at(base.x):
			worker.external_job = -1
			return false
	var candidates: Array[Node2D] = civic.jobs()
	if worker.external_job >= 0:
		var current: Node2D = candidates[worker.external_job]
		if not current.ordered or unsafe_at(current.position.x) or (cycle.phase != "DÍA" and absf(current.position.x) > civic.frontier(signf(current.position.x))): worker.external_job = -1
	if worker.external_job < 0:
		for index: int in range(candidates.size()):
			var candidate: Node2D = candidates[index]
			if not candidate.ordered or unsafe_at(candidate.position.x) or not civic.safe_to_build(candidate.position.x): continue
			if cycle.phase != "DÍA" and absf(candidate.position.x) > civic.frontier(signf(candidate.position.x)): continue
			var assigned: int = 0
			for other: ColonyWorker in workers:
				if other.external_job == index: assigned += 1
			if assigned < 2:
				worker.external_job = index
				break
	if worker.external_job < 0: return false
	var site: Node2D = candidates[worker.external_job]
	var previous: float = worker.x
	worker.x = move_toward(worker.x, site.position.x, worker.data.speed * delta)
	var arrived: bool = absf(worker.x - site.position.x) < GameRules.BUILD_ARRIVAL_DISTANCE
	if arrived:
		site.progress += delta * (GameRules.OVERLOAD_WORK_RATE if overload.overloaded(site.position.x) else 1)
		if site is ConstructionSite and site.progress >= GameRules.BUILD_TIME:
			site.complete_work()
			worker.external_job = -1
	worker.update_visual(previous, arrived)
	return true
