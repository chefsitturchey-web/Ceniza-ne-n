extends SceneTree

var checks: int = 0
var failures: int = 0
var loaded: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func check_directory(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		if file.ends_with(".tres"):
			loaded += 1
			verify(load(path.path_join(file)) != null, "Carga: " + file)
	for directory: String in DirAccess.get_directories_at(path):
		check_directory(path.path_join(directory))

func run_checks() -> void:
	check_directory("res://data")
	for id: String in ["errante", "corredor"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		var runner: bool = id == "corredor"
		verify(data.id == id and data.health == (60 if runner else 100), id + ": identidad y vida")
		verify(data.speed == (56.0 if runner else 32.0) and data.damage == (8 if runner else 12), id + ": velocidad y daño")
		verify(data.reward == 3 and data.health_per_night == 20, id + ": recompensa y escalado")
		verify(data.windup == 0.5 and data.cooldown == 1.1 and data.attack_visual_duration == 1.6, id + ": tiempos de ataque")
		verify(data.hurt_duration == 0.32 and data.flash_duration == 0.12, id + ": reacción visual")
		verify(data.player_notice_range == 30.0 and data.player_hit_range == 38.0 and data.wall_range == 24.0 and data.core_range == 35.0, id + ": alcances")
		verify(data.spawn_distance == 650.0 and data.scene.resource_path == "res://entities/enemies/%s.tscn" % id, id + ": escena y aparición")
		verify(data.move_animation == (&"correr" if runner else &"caminar"), id + ": animación")
	for id: String in ["wall", "turret"]:
		var data: StructureData = load("res://data/structures/%s.tres" % id)
		var wall: bool = id == "wall"
		verify(data.id == id and data.cost == (20 if wall else 25) and data.health == (240 if wall else 100), id + ": costo y vida")
		verify(data.repair_cost == 8 and data.energy == (0 if wall else 2), id + ": reparación y energía")
		verify(data.offset == (240.0 if wall else 180.0) and data.blocks_enemies == wall and data.scene != null, id + ": ubicación y escena")
		verify(data.damage == (0 if wall else 18) and data.attack_range == (0.0 if wall else 260.0), id + ": daño y alcance")
		verify(data.interval == 1.1 and data.overloaded_interval == 0.35, id + ": cadencia")
	for id: String in ["builder", "collector"]:
		var data: WorkerData = load("res://data/workers/%s.tres" % id)
		var builder: bool = id == "builder"
		verify(data.id == id and data.cost == 15 and data.speed == (75.0 if builder else 65.0), id + ": costo y velocidad")
		verify(data.cargo == (0 if builder else 8) and data.gather_time == 3.0, id + ": carga y recolección")
		verify(data.gather_distance == 330.0 and data.home_distance == (55.0 if builder else 35.0) and data.scene != null, id + ": destinos y escena")
	for id: String in ["standard", "district"]:
		var data: CycleConfig = load("res://data/cycles/%s.tres" % id)
		verify(data.day_duration == (90.0 if id == "standard" else 10.0) and data.warning_duration == 10.0 and data.night_duration == 60.0 and data.nights == 3, id + ": tiempos conservados")
		verify(data.dawn_scrap == 25 and data.dawn_core_heal == 40 and data.dawn_player_health == 100, id + ": amanecer")
	for night: int in range(1, 4):
		var data: WaveData = load("res://data/waves/night_%d.tres" % night)
		verify(data.enemies.size() == [12, 18, 23][night - 1] and data.sides.size() == data.enemies.size(), "Tamaño de oleada %d" % night)
		verify(data.cadence == 2.2 - night * 0.4, "Cadencia exacta de oleada %d" % night)
		for index: int in range(data.enemies.size()):
			verify((index >= 8 + night * 4 or data.enemies[index].id == (&"corredor" if index % 3 == 2 else &"errante")) and data.sides[index] == (-1.0 if index % 2 == 0 else 1.0), "Secuencia de oleada %d/%d" % [night, index])
	print("Resources: %d cargados; %d comprobaciones; %d fallos" % [loaded, checks, failures])
	quit(1 if failures > 0 else 0)
