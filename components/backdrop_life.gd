class_name BackdropLife
extends RefCounted
## Anclajes medidos sobre periphery_alive_v2.png; humo, ventiladores y vía comparten el dibujo.
const TRAIN: Texture2D = preload("res://assets/world/expedition/train.png")
static var fan: AtlasTexture
const ANCHORS: Dictionary = {
	"foundry": [Vector2(0.09, 0.13), Vector2(0.225, 0.14), Vector2(0.46, 0.33), Vector2(0.65, 0.29), Vector2(0.94, 0.12)],
	"flooded": [Vector2(0.16, 0.79), Vector2(0.51, 0.69), Vector2(0.76, 0.12)],
	"citadel": [Vector2(0.43, 0.32), Vector2(0.70, 0.18), Vector2(0.88, 0.25)],
	"network": [Vector2(0.085, 0.61), Vector2(0.91, 0.61), Vector2(0.525, 0.32)]
}

static func point(at: Vector2, width: float, height: float, top: float) -> Vector2:
	return at * Vector2(width, height) + Vector2(0, top)

static func draw_zone(canvas: CanvasItem, id: String, time: float, top: float, width: float, height: float, frame: Transform2D) -> void:
	if id == "periphery":
		draw_factory(canvas, time, top, frame)
		return
	var particles: bool = GamePreferences.current().particles
	var steady: bool = GamePreferences.current().reduced_flashes
	match id:
		"foundry":
			for mouth: Vector2 in ANCHORS.foundry:
				AmbientSteam.draw_plume(canvas, point(mouth, width, height, top), time + mouth.x * 9, 19, 6, Color("b6a49a"))
			# Molten metal travels inside the drawn furnace opening.
			var pour: Vector2 = point(Vector2(0.175, 0.53), width, height, top)
			for index: int in 8:
				var phase: float = fposmod(time * 0.32 + index / 8.0, 1)
				var at: Vector2 = pour + Vector2(sin(phase * 6 + index) * 1.5, phase * height * 0.27)
				canvas.draw_line(at, at + Vector2(0, 5), Color("ffc56e", 0.55), 2)
			if particles:
				for index: int in 18:
					var phase: float = fposmod(time * 0.22 + index * 0.17, 1)
					var at: Vector2 = point(Vector2(0.12 + index % 7 * 0.11, 0.85 - phase * 0.24), width, height, top)
					canvas.draw_line(at, at + Vector2(1, -2), Color("ffd49a", (1 - phase) * 0.55), 1)
			var cart: Vector2 = point(Vector2(fposmod(time * 0.014 + 0.10, 0.72), 0.555), width, height, top)
			canvas.draw_texture_rect(DepotArt.prop(0), Rect2(cart - Vector2(6, 9), Vector2(12, 9)), false, Color("a79581"))
		"flooded":
			for index: int in 2:
				var outlet: Vector2 = point(ANCHORS.flooded[index], width, height, top)
				for stream: int in 3:
					var drop: float = fposmod(time * 15 + stream * 3.0, 10)
					canvas.draw_line(outlet + Vector2(stream - 1, drop), outlet + Vector2(stream - 1, drop + 3), Color("8fb8c9", 0.45), 1)
				canvas.draw_arc(outlet + Vector2(0, 12), 4 + fposmod(time + index, 1) * 7, 0, PI, 16, Color("86bec5", 0.2), 1)
			for index: int in 22:
				var at: Vector2 = point(Vector2(fposmod(index * 0.071 + sin(time * 0.2 + index) * 0.008, 1), 0.78 + index % 5 * 0.035), width, height, top)
				var half: float = 3 + sin(time * 1.2 + index) * 2
				canvas.draw_line(at - Vector2(half, 0), at + Vector2(half, 0), Color("74b5ca", 0.24), 1)
			if particles:
				for index: int in 30:
					var at: Vector2 = point(Vector2(fposmod(index * 0.137 - time * 0.025, 1), fposmod(index * 0.193 + time * 0.43, 1)), width, height, top)
					canvas.draw_line(at, at + Vector2(-1, 5), Color("abc4d1", 0.16), 1)
		"citadel":
			for index: int in 3:
				var pole: Vector2 = point(ANCHORS.citadel[index], width, height, top)
				canvas.draw_line(pole - Vector2(0, 5), pole + Vector2(0, 30), Color("6c706c"), 1)
				# Segmented cloth keeps its attachment fixed while the hem trails.
				for strip: int in 6:
					var a: float = strip / 6.0
					var b: float = (strip + 1) / 6.0
					var wave_a: float = sin(time * 1.6 - a * 3 + index) * a * 2
					var wave_b: float = sin(time * 1.6 - b * 3 + index) * b * 2
					var corners: PackedVector2Array = [pole + Vector2(a * 18, wave_a), pole + Vector2(b * 18, wave_b), pole + Vector2(b * 18, 22 + wave_b), pole + Vector2(a * 18, 22 + wave_a)]
					canvas.draw_colored_polygon(corners, Color("263345").lightened(0.04 if strip % 2 == 0 else 0))
					canvas.draw_line(corners[2], corners[3], Color("ad9261"), 1)
				canvas.draw_line(pole + Vector2(3, 3), pole + Vector2(3, 17), Color("c7aa71"), 1)
			if particles:
				for index: int in 16:
					var at: Vector2 = point(Vector2(fposmod(index * 0.127 + time * 0.012, 1), 0.54 + fposmod(index * 0.11 - time * 0.03, 0.35)), width, height, top)
					canvas.draw_circle(at, 0.7, Color("d8cba7", 0.35))
		"network":
			for index: int in 2:
				AmbientSteam.draw_plume(canvas, point(ANCHORS.network[index], width, height, top), time + index, -12 if index == 0 else 12, 5, Color("6bacae"))
			var core: Vector2 = point(ANCHORS.network[2], width, height, top)
			for ring: int in 3:
				canvas.draw_arc(core, 43 + ring * 4, time * (0.12 + ring * 0.03) + ring, time * (0.12 + ring * 0.03) + ring + 1.2, 28, Color("6ddbd1", 0.15), 1)
			for index: int in 8:
				var start: Vector2 = point(Vector2(0.13 + index * 0.1, 0.05), width, height, top)
				var elbow: Vector2 = point(Vector2(0.20 + index * 0.07, 0.47), width, height, top)
				var ratio: float = fposmod(time * 0.13 + index * 0.16, 1)
				var at: Vector2 = start.lerp(elbow, ratio * 2) if ratio < 0.5 else elbow.lerp(core, (ratio - 0.5) * 2)
				canvas.draw_circle(at, 1, Color("79e0ce", 0.75))
	for index: int in 5:
		var at: Vector2 = point(Vector2(0.14 + index * 0.17, 0.59 + index % 2 * 0.08), width, height, top)
		var energy: float = 0.32 if steady else 0.22 + sin(time * 0.8 + index * 1.7) * 0.1
		canvas.draw_rect(Rect2(at, Vector2(1, 3)), Color("d0e6df", energy))

static func draw_factory(canvas: CanvasItem, time: float, top: float, frame: Transform2D = Transform2D.IDENTITY) -> void:
	var scale: Vector2 = Vector2(512.0 / 1672.0, 288.0 / 941.0)
	for mouth: Vector2 in [Vector2(180, 73), Vector2(640, 122), Vector2(1068, 140), Vector2(1415, 170)]:
		AmbientSteam.draw_plume(canvas, mouth * scale + Vector2(0, top), time + mouth.x * 0.01, 16, 7, Color("9aa8af"))
	if fan == null:
		fan = AtlasTexture.new()
		fan.atlas = DepotArt.PARTS
		var source: Rect2 = ArtScale.source(DepotArt.PARTS, 5)
		fan.region = Rect2(source.position + source.size * 0.22, source.size * 0.56)
		fan.filter_clip = true
	for at: Vector2 in [Vector2(312, 522), Vector2(1396, 551)]:
		canvas.draw_set_transform_matrix(frame * Transform2D(time * 0.9, at * scale + Vector2(0, top)))
		canvas.draw_texture_rect(fan, Rect2(-7, -7, 14, 14), false, Color("a0afb4"))
	canvas.draw_set_transform_matrix(frame)
	var x: float = fposmod(time * 9 + 110, 620) - 100
	var rail_y: float = top + 122
	canvas.draw_texture_rect(TRAIN, Rect2(x, rail_y - 18, 72, 18), false, Color("7d919d"))
	for axle: int in range(3):
		var center: Vector2 = Vector2(x + 11 + axle * 23, rail_y - 2)
		canvas.draw_circle(center, 2, Color("182639"))
		canvas.draw_line(center, center + Vector2.from_angle(time * 6) * 1.5, Color("8299a8"))
	for window: Vector2 in [Vector2(156, 390), Vector2(705, 391), Vector2(339, 650), Vector2(716, 641)]:
		var energy: float = 0.35 if GamePreferences.current().reduced_flashes else 0.26 + sin(time * 0.7 + window.x) * 0.08
		canvas.draw_rect(Rect2(window * scale + Vector2(-1, top), Vector2(2, 4)), Color("ffce75", energy))
