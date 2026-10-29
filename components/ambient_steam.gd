class_name AmbientSteam
extends RefCounted
static var puff: GradientTexture2D

static func draw_plume(canvas: CanvasItem, origin: Vector2, time: float, wind: float, count: int = 7, tint: Color = Color("bac7c6")) -> void:
	if not GamePreferences.current().particles: return
	if puff == null:
		puff = GradientTexture2D.new()
		var ramp: Gradient = Gradient.new()
		ramp.colors = PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		puff.gradient = ramp
		puff.width = 32
		puff.height = 32
		puff.fill = GradientTexture2D.FILL_RADIAL
		puff.fill_from = Vector2(0.5, 0.5)
		puff.fill_to = Vector2(1, 0.5)
	for index: int in range(count):
		var age: float = fposmod(time * 0.2 + float(index) / count, 1)
		var center: Vector2 = origin + Vector2(age * wind + sin(age * 8 + index) * 2, -age * 38)
		var diameter: float = 5 + age * 18
		canvas.draw_texture_rect(puff, Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), false, Color(tint, (1 - age) * 0.38))
