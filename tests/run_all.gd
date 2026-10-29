extends SceneTree

const SUITES: Array[String] = [
	"static_check", "unit_animation_test", "visual_novel_test", "fortress_progression_test", "mobility_test", "commander_test", "story_finale_test", "expansion_test", "campaign_bosses_test", "polish_integration_test", "menu_settings_test", "modules_test", "machine_rig_test", "neural_audio_test", "expedition_test", "recaudador_test",
	"save_system_test", "effects_test", "hud_clean_test", "enemies_gdd_test",
	"combat_smoke", "siege_smoke", "errante_animation_smoke",
	"health_component_test", "resource_test", "director_test", "visual_integration_test",
	"fresh_colony_simulation", "fresh_colony_simulation --foundry", "fresh_colony_simulation --flooded", "fresh_colony_simulation --citadel", "fresh_colony_simulation --network", "session_simulation", "session_simulation --assist"
]
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_all")

func run_all() -> void:
	for suite: String in SUITES:
		var parts: PackedStringArray = suite.split(" ")
		var arguments: PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--log-file", ProjectSettings.globalize_path("res://validation-%s.log" % parts[0]),
			"--script", "res://tests/%s.gd" % parts[0], "--quit-after", "1800"]
		if parts.size() > 1:
			arguments.append_array(["--", parts[1]])
		var output: Array = []
		var code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
		# El archivo conserva UTF-8 también cuando OS.execute usa la página ANSI de Windows.
		var log_path: String = "res://validation-%s.log" % parts[0]
		var transcript: String = FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else "".join(output)
		print("--- %s (salida %d) ---" % [suite, code])
		print(transcript.strip_edges())
		# El sandbox de Windows puede negar su almacén de certificados; no es GDScript.
		var errors: String = transcript.replace("ERROR: Failed to read the root certificate store.", "")
		var completed: bool = "PASS:" in transcript or "0 fallos" in transcript or "fallos: 0" in transcript or "victoria=" in transcript
		if code != 0 or not completed or "ERROR:" in errors or "WARNING:" in errors:
			failures += 1
	print("TOTAL: %d suites; %d fallos" % [SUITES.size(), failures])
	quit(1 if failures > 0 else 0)
