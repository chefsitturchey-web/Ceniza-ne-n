extends SceneTree

const DIRECTORIES: Array[String] = ["core", "components", "data", "entities", "systems", "ui", "levels", "tests"]
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func scan(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		if not file.ends_with(".gd") or file == "static_check.gd":
			continue
		var script: GDScript = load(path.path_join(file)) as GDScript
		checks += 1
		# El proceso es nuevo: load ya compila cada script y sus dependencias.
		# Recompilar clases usadas por el autoload conserva referencias antiguas.
		if script == null or not script.can_instantiate():
			failures += 1
	for directory: String in DirAccess.get_directories_at(path):
		scan(path.path_join(directory))

func run_checks() -> void:
	for directory: String in DIRECTORIES:
		scan("res://" + directory)
	print("Compilación: %d scripts; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
