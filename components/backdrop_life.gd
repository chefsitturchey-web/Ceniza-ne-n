class_name BackdropLife
extends RefCounted
## Anclajes medidos sobre periphery_alive_v2.png; humo, ventiladores y vía comparten el dibujo.
const TRAIN: Texture2D = preload("res://assets/world/expedition/train.png")
static var fan: AtlasTexture

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
