class_name ExpansionOutpost
extends Node2D

const MAX_HEALTH: int = 180
const ART: Texture2D = preload("res://assets/structures/industrial_atlas_v2.png")
var spec: Dictionary
var expansion: ExpansionSystem
var hp: int = 0
var ordered: bool = false
var progress: float = 0
var income: float = 0
var elapsed: float = 0
var flash: float = 0
var ally: FieldAlly
var effects: DebrisEmitter
var staffed: bool = false
var staff_role: String = ""
var squad: Array[FieldAlly] = []

func staff_count() -> int:
	var count: int = 0
	for member: FieldAlly in squad:
		if is_instance_valid(member) and member.hp > 0: count += 1
	return count

func staff_capacity() -> int:
	return 3 if spec.id == "barracks" else 1

func _ready() -> void:
	effects = DebrisEmitter.new()
	add_child(effects)

func take_damage(amount: int) -> void:
	if hp <= 0 or amount <= 0: return
	hp = maxi(0, hp - amount)
	flash = 0.16
	effects.emit_pixels(global_position + Vector2(0, -24), 5, Color("ffce75"))
	if hp == 0:
		ordered = false
		progress = 0
		for member: FieldAlly in squad:
			if is_instance_valid(member): member.take_damage(300)
		effects.emit_fragments(global_position, null, 12)
		expansion.district.sound.play_cue("destroy")
		expansion.refresh_energy()
	queue_redraw()

func create_ally() -> void:
	if not staffed: return
	if staff_count() > 0: return
	hire(staff_role if not staff_role.is_empty() else ("ranger" if spec.id == "barracks" else "medic"))

func hire(role: String) -> FieldAlly:
	if staff_count() >= staff_capacity(): return null
	for index: int in range(squad.size() - 1, -1, -1):
		if not is_instance_valid(squad[index]) or squad[index].hp <= 0:
			if is_instance_valid(squad[index]): squad[index].free()
			squad.remove_at(index)
	var member: FieldAlly = FieldAlly.new()
	member.home = self
	member.role = role
	member.position = position + Vector2(squad.size() * 14, 0)
	expansion.add_child(member)
	squad.append(member)
	ally = squad[0]
	staffed = true
	staff_role = role
	return member

func tick(delta: float) -> void:
	elapsed += delta
	flash = maxf(0, flash - delta)
	if ordered:
		progress = minf(6, progress)
		if progress >= 6:
			hp = MAX_HEALTH
			ordered = false
			progress = 0
			expansion.district.presenter.show_notice(spec.title + " operativo")
			effects.emit_pixels(global_position + Vector2(0, -30), 10, Color("47dacb"))
			expansion.district.sound.play_cue("upgrade")
			expansion.refresh_energy()
			expansion.checkpoint()
			delta = 0.0
	if hp > 0:
		if spec.id == "recycler" and expansion.district.cycle.phase == "DÍA":
			income += delta
			if income >= 12:
				var batches: int = floori(income / 12)
				income = fmod(income, 12)
				expansion.district.bank.deposit(5 * batches)
	for member: FieldAlly in squad:
		if is_instance_valid(member): member.tick(delta)
	queue_redraw()

func snapshot() -> Dictionary:
	var crew: Array[Dictionary] = []
	for member: FieldAlly in squad:
		if is_instance_valid(member) and member.hp > 0:
			var entry: Dictionary = member.snapshot()
			entry["role"] = member.role
			crew.append(entry)
	return {"id": spec.id, "hp": hp, "ordered": ordered, "progress": progress, "income": income, "staffed": not crew.is_empty(), "role": staff_role, "ally": crew[0] if not crew.is_empty() else {}, "crew": crew}

func restore(data: Dictionary) -> void:
	hp = int(data.get("hp", 0))
	ordered = data.get("ordered", false)
	progress = float(data.get("progress", 0))
	income = float(data.get("income", 0))
	staffed = data.get("staffed", not data.get("ally", {}).is_empty())
	staff_role = data.get("role", "ranger" if spec.id == "barracks" else "medic")
	for member: FieldAlly in squad:
		if is_instance_valid(member): member.free()
	squad.clear()
	ally = null
	var saved_crew: Array = data.get("crew", [])
	if not data.has("crew") and not data.get("ally", {}).is_empty(): saved_crew = [data.ally]
	for entry: Dictionary in saved_crew:
		var member: FieldAlly = hire(entry.get("role", staff_role))
		member.restore(entry)
	staffed = staff_count() > 0
	queue_redraw()

func plate(rect: Rect2, tint: Color = Color("304356")) -> void:
	draw_rect(rect.grow(1), Color("0b1322"))
	draw_rect(rect, tint)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("8299a8"), 1)
	for x: float in [rect.position.x + 2, rect.end.x - 3]: draw_rect(Rect2(x, rect.position.y + 3, 1, 1), Color("8299a8"))

func _draw() -> void:
	var index: int = ["barracks", "medical", "generator", "recycler"].find(spec.id)
	var source: Rect2 = ArtScale.source(ART, index)
	var height: float = [64.0, 60.0, 52.0, 68.0][index]
	var frame: Rect2 = ArtScale.grounded(source, height)

	if hp > 0 or ordered:
		var fraction: float = clampf(progress / 6, 0, 1) if ordered else 1.0
		var shown: float = height * fraction
		draw_texture_rect_region(ART, Rect2(-frame.size.x * 0.5, -shown, frame.size.x, shown), Rect2(source.position + Vector2(0, source.size.y * (1 - fraction)), Vector2(source.size.x, source.size.y * fraction)), Color.WHITE if hp > MAX_HEALTH / 2 or ordered else Color("ac8d7b"))
		if ordered:
			for x: int in [-49, 49]:
				draw_line(Vector2(x, 0), Vector2(x, -height), Color("8299a8"), 2)
			for y: int in range(-int(height), 0, 12): draw_line(Vector2(-49, y), Vector2(49, y + 12), Color("304356"), 1)
			draw_line(Vector2(-48, -shown), Vector2(48, -shown), Color("ffce75"), 1)
		if hp > 0 and spec.id == "generator":
			var rotor: Vector2 = Vector2.from_angle(elapsed * 4) * 7
			draw_line(Vector2(25, -18) - rotor, Vector2(25, -18) + rotor, Color("ffce75"), 1)
		if hp > 0 and spec.id == "recycler":
			for tooth: int in range(6): draw_rect(Rect2(-40 + fposmod(tooth * 7 + elapsed * 12, 42), -18, 3, 2), Color("8299a8"))
		return
	for x: int in [-48, 48]:
		draw_rect(Rect2(x - 2, -5, 4, 5), Color("8299a8"))
	draw_line(Vector2(-46, -2), Vector2(46, -2), Color("47dacb", 0.35), 1)

func _draw_prototype() -> void:
	if hp <= 0 and not ordered:
		draw_rect(Rect2(-27, -42, 54, 42), Color("47dacb", 0.28), false, 1)
		for x: int in [-29, 27]: draw_rect(Rect2(x, -4, 3, 4), Color("8299a8"))
		return
	var built: float = progress / 6 if ordered else 1.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, maxf(0.1, built)))
	plate(Rect2(-29, -5, 58, 5))
	plate(Rect2(-24, -39, 48, 34), Color("704c43") if spec.id == "recycler" else Color("304356"))
	plate(Rect2(-20, -44, 40, 5))
	var powered: bool = expansion.powered(self)
	var tint: Color = Color("47dacb") if powered else Color("e89e54")
	if spec.id == "generator":
		for x: int in [-14, 0, 14]:
			plate(Rect2(x - 5, -34, 10, 25), Color("182639"))
			for y: int in [-29, -21, -13]: draw_rect(Rect2(x - 3, y, 6, 3), tint)
		var rotor: Vector2 = Vector2.from_angle(elapsed * 5) * 7
		draw_circle(Vector2(0, -21), 9, Color("0b1322"))
		draw_line(Vector2(0, -21) - rotor, Vector2(0, -21) + rotor, Color("8299a8"), 3)
	elif spec.id == "recycler":
		plate(Rect2(-18, -33, 36, 15), Color("182639"))
		for tooth: int in range(5):
			var x: float = fposmod(tooth * 8 + elapsed * 12, 34) - 17
			draw_rect(Rect2(x, -30, 3, 8), Color("8299a8"))
		plate(Rect2(-15, -13, 30, 5))
	elif spec.id == "barracks":
		plate(Rect2(-10, -32, 20, 27), Color("182639"))
		for side: int in [-1, 1]:
			plate(Rect2(side * 15 - 3, -29, 6, 17))
			draw_line(Vector2(side * 15, -28), Vector2(side * 15, -18), tint, 1)
		draw_rect(Rect2(-7, -39, 14, 3), tint)
	else:
		plate(Rect2(-16, -32, 32, 21), Color("182639"))
		draw_rect(Rect2(-3, -29, 6, 16), tint)
		draw_rect(Rect2(-8, -24, 16, 6), tint)
	if hp < MAX_HEALTH / 2:
		draw_polyline(PackedVector2Array([Vector2(-20, -38), Vector2(-12, -29), Vector2(-16, -19), Vector2(-9, -13)]), Color("0b1322"), 2)
	if flash > 0 and not GamePreferences.current().reduced_flashes:
		draw_rect(Rect2(-24, -39, 48, 34), Color(1, 0.65, 0.3, 0.3))
	draw_set_transform(Vector2.ZERO)
	if ordered:
		var drone: Vector2 = Vector2(roundf(sin(elapsed * 3) * 20), -52)
		draw_rect(Rect2(drone - Vector2(6, 3), Vector2(12, 6)), Color("8299a8"))
		draw_line(drone, Vector2(0, -44 * built), Color("47dacb", 0.5), 1)
