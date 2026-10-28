class_name GamePreferences
extends Node
## Ajustes globales de presentación; nunca guardan estado de una partida.
signal changed
const DEFAULTS: Dictionary = {"master": 1.0, "music": 1.0, "sfx": 1.0, "muted": false,
	"fullscreen": false, "window_size": 0, "reduced_flashes": false, "particles": true}
const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
var values: Dictionary = DEFAULTS.duplicate()
var config_path: String = "user://opciones.cfg"
var base_volumes: Dictionary = {}
var last_error: Error = OK
var particles: bool:
	get: return values.particles
var reduced_flashes: bool:
	get: return values.reduced_flashes
var muted: bool:
	get: return values.muted

static func current() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Preferences")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: String in ["Master", "Music", "SFX"]:
		var index: int = AudioServer.get_bus_index(bus)
		if index >= 0:
			base_volumes[bus] = AudioServer.get_bus_volume_db(index)
	load_settings()
	apply_all()

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	values = DEFAULTS.duplicate()
	if config.load(config_path) != OK:
		return
	for key: String in DEFAULTS:
		var value: Variant = config.get_value("preferences", key, DEFAULTS[key])
		if valid_value(key, value):
			values[key] = value

func valid_value(key: String, value: Variant) -> bool:
	if not DEFAULTS.has(key):
		return false
	if key in ["master", "music", "sfx"]:
		return (value is float or value is int) and is_finite(float(value)) and value >= 0 and value <= 1
	if key == "window_size":
		return value is int and value >= 0 and value < SIZES.size()
	return value is bool

func update_value(key: String, value: Variant) -> bool:
	if not valid_value(key, value):
		return false
	values[key] = value
	apply_all(key in ["fullscreen", "window_size"])
	changed.emit()
	return save_settings()

func save_settings() -> bool:
	var config: ConfigFile = ConfigFile.new()
	for key: String in values:
		config.set_value("preferences", key, values[key])
	last_error = config.save(config_path)
	return last_error == OK

func apply_all(display: bool = true) -> void:
	for pair: Array in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var index: int = AudioServer.get_bus_index(pair[0])
		if index < 0:
			continue
		var amount: float = values[pair[1]]
		AudioServer.set_bus_volume_db(index, float(base_volumes.get(pair[0], 0.0)) + linear_to_db(maxf(amount, 0.0001)))
		AudioServer.set_bus_mute(index, amount == 0 or (pair[0] == "Master" and muted))
	if not display or DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not values.fullscreen:
		var available: Rect2i = DisplayServer.screen_get_usable_rect()
		var desired: Vector2i = SIZES[int(values.window_size)]
		var factor: float = minf(1.0, minf(float(available.size.x) / desired.x, float(available.size.y) / desired.y))
		DisplayServer.window_set_size(Vector2i(Vector2(desired) * factor))
		DisplayServer.window_set_position(available.position + (available.size - DisplayServer.window_get_size()) / 2)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		update_value("muted", not muted)
		get_viewport().set_input_as_handled()
