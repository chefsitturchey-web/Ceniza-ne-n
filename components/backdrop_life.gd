class_name BackdropLife
extends RefCounted
## Anclajes medidos sobre periphery_alive_v2.png; humo, ventiladores y vía comparten el dibujo.
const TRAIN: Texture2D = preload("res://assets/world/expedition/train.png")
const ANCHORS: Dictionary = {
	"foundry": [Vector2(0.09, 0.13), Vector2(0.225, 0.14), Vector2(0.46, 0.33), Vector2(0.65, 0.29), Vector2(0.94, 0.12)],
	"flooded": [Vector2(0.16, 0.79), Vector2(0.51, 0.69), Vector2(0.76, 0.12)],
	"citadel": [Vector2(0.43, 0.32), Vector2(0.70, 0.18), Vector2(0.88, 0.25)],
	"network": [Vector2(0.085, 0.61), Vector2(0.91, 0.61), Vector2(0.525, 0.32)]
}

static func draw_zone(canvas: CanvasItem, id: String, time: float, top: float, width: float, height: float, frame: Transform2D) -> void:
	if WorldParticles.budget(1) == 0: return
	canvas.draw_set_transform_matrix(frame * Transform2D(0, Vector2(width / 1024, height / 576), 0, Vector2(0, top)))
	var night: bool = false
	var view: DistrictView = canvas.get_parent().view if canvas.get_parent().get("view") != null else null
	if view != null: night = float(view.light.lamps) > 0.5
	# Espuma y bruma en la desembocadura medida de cada caida.
	if id == "citadel":
		foam(canvas, Vector2(307, 370), 24, time)
		foam(canvas, Vector2(362, 363), 22, time + 1)
		foam(canvas, Vector2(296, 450), 28, time + 2)
	elif id == "periphery":
		foam(canvas, Vector2(386, 503), 16, time)
		foam(canvas, Vector2(961, 503), 16, time + 1)
		# Tren esporadico sobre la via elevada, no sobre el canal.
		var journey: float = fposmod(time + 5, 38)
		if journey < 13:
			var x: float = floorf(journey * 94 - 140)
			canvas.draw_texture_rect(TRAIN, Rect2(x, 216, 124, 28), false, Color("8c9da6"))
			for wheel: int in 4:
				canvas.draw_rect(Rect2(x + 12 + wheel * 29, 241, 5, 4), Color("172432"))
	elif id == "foundry":
		for index: int in WorldParticles.budget(20):
			var phase: float = fposmod(time * 0.23 + index * 0.137, 1)
			var at: Vector2 = Vector2(176 + sin(index * 7.1 + phase * 4) * 45, 422 - phase * 72).floor()
			canvas.draw_rect(Rect2(at, Vector2(1, 3)), Color("e8a153", (1 - phase) * 0.65))
	# Vapor intermitente en tuberias reales; el humo de chimeneas sigue en su pool.
	var mouth: Vector2 = Vector2(165, 394) if id == "flooded" else Vector2(85, 351)
	if id == "network" or id == "flooded":
		var burst: float = fposmod(time, 9)
		if burst < 3:
			for index: int in WorldParticles.budget(8):
				var age: float = fposmod(burst + index * 0.31, 2)
				var at: Vector2 = (mouth + Vector2(age * 9, -age * 9 + sin(index * 3.7) * 4)).floor()
				canvas.draw_texture_rect(WorldParticles.smoke_texture(), Rect2(at, Vector2(8, 5)), false, Color(0.52, 0.72, 0.77, (1 - age / 2) * 0.28))
	if id == "flooded":
		# Goteo bajo las puntas de la pasarela, medido en el PNG.
		for index: int in WorldParticles.budget(4):
			var drop: float = fposmod(time * 29 + index * 13, 46)
			var at: Vector2 = Vector2(464 + index * 9, 342 + drop).floor()
			canvas.draw_rect(Rect2(at, Vector2(1, 3)), Color("8eb2bf", 0.45))
	# Gotas, ceniza o lluvia segun el distrito, siempre con presupuesto compartido.
	for index: int in WorldParticles.budget(24):
		var rain: bool = id == "flooded"
		var at: Vector2 = Vector2(fposmod(index * 137.3 - time * (9 if rain else 2), 1024), fposmod(index * 91.7 + time * (105 if rain else 7), 555)).floor()
		canvas.draw_rect(Rect2(at, Vector2(1, 5 if rain else 1)), Color(0.64, 0.76, 0.8, 0.23 if rain else 0.2))
	# Siluetas distantes; de noche, luces discretas de drones.
	for index: int in WorldParticles.budget(3):
		var x: float = floorf(fposmod(time * (13 + index * 3) + index * 317, 1120) - 48)
		var y: float = floorf(220 + index * 47 + sin(time * 0.7 + index) * 6)
		var drone: bool = id == "network" or night
		canvas.draw_rect(Rect2(x, y, 6 if drone else 2, 2), Color("233645"))
		if drone:
			canvas.draw_rect(Rect2(x - 2, y - 1, 10, 1), Color("435b67"))
			canvas.draw_rect(Rect2(x + 4, y + 1, 1, 1), Color("79bbb9"))
		else:
			var wing: float = -2 if int(time * 5 + index) % 2 == 0 else 1
			canvas.draw_line(Vector2(x - 3, y + wing), Vector2(x, y), Color("233645"))
			canvas.draw_line(Vector2(x + 1, y), Vector2(x + 4, y + wing), Color("233645"))
	canvas.draw_set_transform_matrix(frame)

static func foam(canvas: CanvasItem, base: Vector2, width: float, time: float) -> void:
	for index: int in WorldParticles.budget(12):
		var phase: float = fposmod(time * 0.8 + index * 0.173, 1)
		var at: Vector2 = (base + Vector2(sin(index * 13.7) * width * (0.2 + phase * 0.6), -sin(phase * PI) * 5)).floor()
		canvas.draw_rect(Rect2(at, Vector2(3, 1)), Color("b9d7e0", (1 - phase) * 0.6))
	for index: int in WorldParticles.budget(4):
		var age: float = fposmod(time * 0.4 + index * 0.27, 1)
		var at: Vector2 = (base + Vector2((index - 2) * 5 + age * 8, -age * 11 - 4)).floor()
		canvas.draw_texture_rect(WorldParticles.smoke_texture(), Rect2(at, Vector2(18, 8)), false, Color(0.65, 0.79, 0.84, (1 - age) * 0.25))
