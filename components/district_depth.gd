class_name DistrictDepth
extends RefCounted
## Four visual planes share a fixed world baseline; only horizontal depth varies.
const SKYLINE: Texture2D = preload("res://assets/world/backgrounds/layers/far_skyline.png")
const FAR_SCROLL: float = 0.10
const ARCHITECTURE_SCROLL: float = 0.34
const NEAR_SCROLL: float = 0.62
const ZONE_TINTS: Dictionary = {"periphery": Color("9aaeb8"), "foundry": Color("bd927a"), "flooded": Color("709baa"), "citadel": Color("abb3c0"), "network": Color("69aaa8")}
const SKY_COLORS: Dictionary = {"periphery": [Color("627e96"), Color("a7bccc")], "foundry": [Color("1d2a3c"), Color("606a71")], "flooded": [Color("283e54"), Color("71818e")], "citadel": [Color("293a53"), Color("7c90a2")], "network": [Color("10343e"), Color("4d8b91")]}

static func origin(camera_x: float, tile: int, width: float, scroll: float) -> float:
	return tile * width + camera_x * (1 - scroll) - width * 0.5

static func draw_far(canvas: CanvasItem, camera_x: float, time: float, zone_id: String, horizon: Color) -> void:
	var tint: Color = ZONE_TINTS.get(zone_id, ZONE_TINTS.periphery)
	var first: int = floori(camera_x * FAR_SCROLL / 900)
	# Cloud banks drift independently of the city and of the player camera.
	if GamePreferences.current().particles:
		for index: int in 5:
			var x: float = camera_x + fposmod(index * 193.0 + time * 2.4 - camera_x * 0.035, 1050) - 525
			for lobe: int in 4:
				canvas.draw_circle(Vector2(x + lobe * 24, 15 + index % 3 * 23), 25 + lobe * 3, Color(horizon, 0.055))
	for tile: int in range(first - 1, first + 2):
		var left: float = origin(camera_x, tile, 900, FAR_SCROLL)
		canvas.draw_texture_rect(SKYLINE, Rect2(left, GameRules.FLOOR_Y - 265, 914, 225), false, Color(tint, 0.46))

static func draw_architecture(canvas: CanvasItem, texture: Texture2D, camera_x: float, time: float, zone_id: String) -> void:
	var periphery: bool = zone_id == "periphery"
	var width: float = 512 if periphery else 640
	var height: float = 288 if periphery else 360
	var top: float = GameRules.FLOOR_Y - (216 if periphery else 360)
	var first: int = floori(camera_x * ARCHITECTURE_SCROLL / width)
	for tile: int in range(first - 1, first + 2):
		var x: float = origin(camera_x, tile, width, ARCHITECTURE_SCROLL)
		var mirrored: bool = posmod(tile, 2) == 1
		var frame: Transform2D = Transform2D(0, Vector2(-1 if mirrored else 1, 1), 0, Vector2(x + (width if mirrored else 0), 0))
		canvas.draw_set_transform_matrix(frame)
		canvas.draw_texture_rect(texture, Rect2(0, top, width, height), false, Color(0.86, 0.89, 0.96))
		BackdropLife.draw_zone(canvas, zone_id, time, top, width, height, frame)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

static func draw_near(canvas: CanvasItem, camera_x: float, time: float, zone_id: String) -> void:
	var first: int = floori(camera_x * NEAR_SCROLL / 720)
	var index: int = ["periphery", "foundry", "flooded", "citadel", "network"].find(zone_id)
	var tint: Color = ZONE_TINTS.get(zone_id, ZONE_TINTS.periphery).darkened(0.45)
	for tile: int in range(first - 1, first + 2):
		var x: float = origin(camera_x, tile, 720, NEAR_SCROLL)
		# Local industrial set pieces sit behind gameplay buildings, below eye level.
		if index > 0:
			var texture: Texture2D = DepotArt.machine(index - 1)
			canvas.draw_texture_rect(texture, Rect2(x + 37, GameRules.FLOOR_Y - 62, 52, 62), false, Color(tint, 0.45))
		var pipe: PackedVector2Array = PackedVector2Array([Vector2(x + 110, 260), Vector2(x + 110, 242), Vector2(x + 144, 242), Vector2(x + 144, 256), Vector2(x + 201, 256)])
		canvas.draw_polyline(pipe, Color("0b1623", 0.75), 5)
		canvas.draw_polyline(pipe, Color(tint, 0.5), 1)
		if zone_id == "flooded" or zone_id == "periphery":
			for ripple: int in 8:
				var point: Vector2 = Vector2(x + ripple * 18, 268 + ripple % 3 * 3)
				canvas.draw_line(point, point + Vector2(8 + sin(time * 1.7 + ripple) * 3, 0), Color(tint.lightened(0.5), 0.16), 1)
