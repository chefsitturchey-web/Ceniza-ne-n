class_name ArenaLayout
extends RefCounted
## Mismos vértices para la plataforma visible y sus paredes físicas.
static func boundary(index: int) -> PackedVector2Array:
	if index == 0:
		return PackedVector2Array([Vector2(152, 36), Vector2(488, 36), Vector2(568, 96), Vector2(604, 176), Vector2(604, 320), Vector2(524, 400), Vector2(444, 444), Vector2(188, 444), Vector2(108, 400), Vector2(36, 328), Vector2(36, 152), Vector2(100, 88)])
	if index == 4:
		var points: PackedVector2Array = []
		for vertex: int in range(12): points.append(Vector2(320, 240) + Vector2(cos(vertex * TAU / 12) * 285, sin(vertex * TAU / 12) * 215))
		return points
	if index == 3:
		return PackedVector2Array([Vector2(96, 24), Vector2(544, 24), Vector2(616, 100), Vector2(616, 380), Vector2(544, 456), Vector2(96, 456), Vector2(24, 380), Vector2(24, 100)])
	return PackedVector2Array([Vector2(140, 24), Vector2(500, 24), Vector2(616, 140), Vector2(616, 340), Vector2(500, 456), Vector2(140, 456), Vector2(24, 340), Vector2(24, 140)])
