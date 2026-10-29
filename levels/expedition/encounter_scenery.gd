class_name EncounterScenery
extends Node2D
## Tramoya fuera del perímetro físico; el suelo conserva las señales de combate.
var arena: RecaudadorArena
var elapsed: float = 0
var redraw_time: float = 0
var equipment: Array[Sprite2D] = []
var backdrop: Texture2D

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	backdrop = load(arena.zone.background_path) as Texture2D
	if arena.zone_index == 0: return
	for side: int in [-1, 1]:
		for row: int in range(2):
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = DepotArt.machine(arena.zone_index - 1)
			sprite.position = Vector2(320 + side * 304, 147 + row * 195)
			sprite.scale = Vector2.ONE * 72 / sprite.texture.get_height()
			sprite.modulate = [Color.WHITE, Color("c3a28e"), Color("719ba9"), Color("c6bd9b"), Color("739aaf")][arena.zone_index]
			add_child(sprite)
			equipment.append(sprite)

func _process(delta: float) -> void:
	elapsed += delta
	redraw_time += delta
	if redraw_time >= 1.0 / 24:
		redraw_time = 0
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2(320, 240)
	var boundary: PackedVector2Array = ArenaLayout.boundary(arena.zone_index)
	var tint: Color = [Color("8299a8"), Color("e89e54"), Color("47dacb"), Color("ffce75"), Color("47dacb")][arena.zone_index]
	for index: int in range(boundary.size()):
		if arena.zone_index == 0: continue # DepotArenaVisual already paints its water and rail yard.
		var a: Vector2 = boundary[index]
		var b: Vector2 = boundary[(index + 1) % boundary.size()]
		var outside: PackedVector2Array = [a, b, center + (b - center) * 4, center + (a - center) * 4]
		# These textured polygons are strictly outside the walkable platform.
		draw_colored_polygon(outside, Color("07131d"))
		var far_uv: PackedVector2Array = []
		var near_uv: PackedVector2Array = []
		for at: Vector2 in outside:
			far_uv.append(at / Vector2(920, 620) + Vector2(0.15, 0.15))
			near_uv.append(at / Vector2(720, 520) + Vector2(0.2, 0.10))
		draw_polygon(outside, PackedColorArray([Color(tint, 0.18)]), far_uv, DistrictDepth.SKYLINE)
		if backdrop != null: draw_polygon(outside, PackedColorArray([Color(tint, 0.38)]), near_uv, backdrop)
	for index: int in 28:
		if not GamePreferences.current().particles: break
		var at: Vector2 = Vector2(fposmod(index * 79.0 + elapsed * (4 + index % 3), 880) - 120, fposmod(index * 71.0 - elapsed * 7, 680) - 100)
		if not Geometry2D.is_point_in_polygon(at, boundary):
			draw_line(at, at + Vector2(1, 2), Color(tint, 0.25), 1)
	if arena.zone_index == 0: return
	for ring: int in range(8):
		var polygon: PackedVector2Array = []
		for at: Vector2 in boundary: polygon.append(center + (at - center) * (1.02 + ring * 0.035))
		polygon.append(polygon[0])
		draw_polyline(polygon, Color(tint, 0.04 + (0.04 if ring % 3 == 0 else 0)), 2)
	if arena.zone_index == 1:
		for side: int in [-1, 1]:
			var at: Vector2 = Vector2(320 + side * 238, -5)
			draw_texture_rect(DepotArt.prop(1), Rect2(at - Vector2(70, 18), Vector2(140, 48)), false, Color("b09b83"))
			AmbientSteam.draw_plume(self, at + Vector2(0, 20), elapsed + side, 28)
	elif arena.zone_index == 2:
		for row: int in range(24):
			var y: float = -60 + row * 26
			for side: int in [-1, 1]:
				var x: float = 320 + side * (290 + sin(elapsed * 0.6 + row * 1.7) * 12)
				draw_line(Vector2(x, y), Vector2(x + side * 110, y + sin(elapsed + row) * 3), Color("47dacb", 0.1), 2)
	elif arena.zone_index == 3:
		for side: int in [-1, 1]:
			var at: Vector2 = Vector2(320 + side * 215, 12)
			draw_texture_rect(DepotArt.prop(0), Rect2(at - Vector2(20, 28), Vector2(40, 56)), false, Color("d4c09d"))
			# Paños de señalización sujetos a sus mástiles: movimiento suave, no flashes.
			var cloth: PackedVector2Array = [at + Vector2(side * 12, -25), at + Vector2(side * 12, 16), at + Vector2(side * 48, 23 + sin(elapsed * 1.8 + side) * 4), at + Vector2(side * 48, -18 + sin(elapsed * 1.8 + side) * 4)]
			draw_colored_polygon(cloth, Color("704c43"))
			draw_line(cloth[0], cloth[3], Color("ffce75", 0.65), 2)
	else:
		for index: int in range(12):
			var at: Vector2 = center + Vector2(cos(index * TAU / 12) * 310, sin(index * TAU / 12) * 238)
			draw_line(center + (at - center) * 0.97, at, Color("304356"), 6)
			var progress: float = fposmod(elapsed * 0.35 + index * 0.14, 1)
			draw_circle(center + (at - center) * (1.03 + progress * 0.1), 2, Color("47dacb", 0.6))
	for sprite: Sprite2D in equipment:
		var at: Vector2 = sprite.position
		draw_circle(at + Vector2(0, 28), 4, Color(tint, 0.3))
		if arena.zone_index == 1:
			AmbientSteam.draw_plume(self, at + Vector2(-7, -26), elapsed + at.y, 18)
		else:
			var arm: Vector2 = Vector2.from_angle(elapsed * 0.8 + at.y) * 16
			draw_line(at + Vector2(0, -23), at + Vector2(0, -23) + arm, Color(tint, 0.55), 1)
