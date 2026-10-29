class_name GameArt
extends RefCounted
## Atlas originales: regiones calculadas desde el tamaño real, sin copias recortadas.
const UNITS: Texture2D = preload("res://assets/characters/units/field_atlas_v3.png")
const CIVIC: Texture2D = preload("res://assets/world/structures/coherent_civic_v4.png")
const SKILLS: Texture2D = preload("res://assets/ui/skills/skills_atlas_v1.png")
const UNIT_IDS: Array[String] = ["ranger", "guardian", "technician", "medic", "civilian", "medical_drone", "artillero", "saboteador"]
const ICON_IDS: Array[String] = ["blade", "drone", "tesla", "orbital", "optic", "battery", "bearing", "magnet", "condenser", "recovery", "shield", "wrench", "medical", "core", "scrap", "signal"]

static func region(texture: Texture2D, columns: int, rows: int, index: int) -> Rect2:
	var cell: Vector2 = texture.get_size() / Vector2(columns, rows)
	return Rect2(Vector2(index % columns, index / columns) * cell, cell)

static func icon(id: String) -> AtlasTexture:
	if id == "capacitor": id = "condenser"
	var index: int = ICON_IDS.find(id)
	var result: AtlasTexture = AtlasTexture.new()
	result.atlas = SKILLS
	result.region = region(SKILLS, 4, 4, maxi(0, index))
	return result
