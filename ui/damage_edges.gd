extends Control
## Bandas de un píxel: viñeta sin texturas ni filtrado, compatible con Compatibility.
var player_flash: float = 0.0
var core_flash: float = 0.0
var player_hit: int = 0
var core_hit: int = 0
var low_health: bool = false
var elapsed: float = 0.0

func set_state(data: Dictionary) -> void:
	var next_player_hit: int = data.get("player_hit", 0)
	var next_core_hit: int = data.get("core_hit", 0)
	if next_player_hit != player_hit:
		player_flash = 0.28
	if next_core_hit != core_hit:
		core_flash = 0.22
	player_hit = next_player_hit
	core_hit = next_core_hit
	low_health = data.health > 0 and data.health <= data.get("health_max", 100) * 0.35
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed += delta
	player_flash = maxf(0, player_flash - delta)
	core_flash = maxf(0, core_flash - delta)
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.09 + 0.06 * pow(maxf(0, sin(elapsed * 5)), 2) if low_health else 0.0
	var red: float = maxf(pulse, player_flash / 0.28 * 0.45)
	for edge: int in range(20):
		var fade: float = pow(1.0 - edge / 20.0, 2)
		if red > 0:
			draw_rect(Rect2(edge, edge, 640 - edge * 2, 360 - edge * 2), Color("dd6482", red * fade), false, 1)
		if core_flash > 0:
			draw_line(Vector2(0, 359 - edge), Vector2(640, 359 - edge), Color("ffce75", core_flash / 0.22 * 0.55 * fade), 1)
