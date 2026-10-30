class_name SettlementCourier
extends Node2D

enum Route { WAIT, FETCH, RETURN }
const DOCK_X: float = 100.0
var system: SettlementSystem
var route: int = Route.WAIT
var cooldown: float = 10
var delivered: int = 0
var route_day: int = 1
var cargo_parts: int = 0
var cargo_scrap: int = 0
var blocked: bool = false
var wheel_angle: float = 0
var elapsed: float = 0
var facing: float = 1
var art: Texture2D = DepotArt.prop(3)
const CRATE: Texture2D = preload("res://assets/world/props/crate.png")

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position.y = GameRules.FLOOR_Y
	position.x = DOCK_X
	visible = false

func walk_to(target: float, delta: float) -> bool:
	var next: float = move_toward(position.x, target, delta * 90)
	blocked = false
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		if enemy.position.x < minf(position.x, next) - 90 or enemy.position.x > maxf(position.x, next) + 90: continue
		var escaping: bool = absf(position.x - enemy.position.x) < 90 and absf(next - enemy.position.x) > absf(position.x - enemy.position.x) and (position.x - enemy.position.x) * (next - enemy.position.x) > 0
		if not escaping:
			blocked = true
			return false
	var distance: float = next - position.x
	if absf(distance) > 0.01: facing = signf(distance)
	wheel_angle += distance / 3
	position.x = next
	return absf(position.x - target) < 1

func deliver() -> void:
	if cargo_parts <= 0: return
	system.world.bank.stored_parts += cargo_parts
	system.world.bank.parts_changed.emit(system.world.bank.parts)
	system.world.bank.deposit(cargo_scrap)
	system.world.presenter.show_notice("Reparto al depósito: +%d piezas y +%d chatarra" % [cargo_parts, cargo_scrap])
	cargo_parts = 0
	cargo_scrap = 0
	delivered += 1
	route = Route.WAIT
	cooldown = 45
	system.world.expansion.checkpoint()

func tick(delta: float) -> void:
	elapsed += delta
	visible = system.sites[0].tier > 0
	if not visible: return
	if route_day != system.world.cycle.day:
		route_day = system.world.cycle.day
		delivered = 0
	cooldown = maxf(0, cooldown - delta)
	var source: float = system.sites[0].position.x
	if system.world.cycle.phase != "DÍA":
		var shelter: float = DOCK_X if absf(position.x - DOCK_X) <= absf(position.x - source) else source
		if walk_to(shelter, delta) and shelter == DOCK_X and route == Route.RETURN: deliver()
		queue_redraw()
		return
	if route == Route.WAIT and delivered < 2 and cooldown <= 0: route = Route.FETCH
	if route == Route.FETCH and walk_to(source, delta):
		cargo_parts = 2 * system.sites[0].tier
		cargo_scrap = 4 + 4 * system.sites[0].tier
		route = Route.RETURN
		system.world.expansion.checkpoint()
	elif route == Route.RETURN and walk_to(DOCK_X, delta): deliver()
	queue_redraw()

func status() -> String:
	if system.sites[0].tier == 0: return "Reparto: restaura el taller para recuperar el transportador"
	if blocked: return "Reparto: ruta bloqueada por enemigos"
	if system.world.cycle.phase != "DÍA": return "Reparto: recogida nocturna"
	return "Reparto %d/2 del día · %s" % [delivered, ["en espera", "hacia el taller", "llevando suministros"][route]]

func snapshot() -> Dictionary:
	return {"x": position.x, "route": route, "cooldown": cooldown, "day": route_day, "delivered": delivered, "parts": cargo_parts, "scrap": cargo_scrap}

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	for rule: Array in [["x", -6900, 6900, false], ["route", 0, 2, true], ["cooldown", 0, 45, false], ["day", 1, 1000000, true], ["delivered", 0, 2, true], ["parts", 0, 4, true], ["scrap", 0, 12, true]]:
		if not ExpansionSystem.number(value.get(rule[0]), rule[1], rule[2], rule[3]): return false
	if value.route != Route.RETURN and (value.parts != 0 or value.scrap != 0): return false
	if value.route != Route.WAIT and value.delivered >= 2: return false
	return value.route != Route.RETURN or (value.parts in [2, 4] and value.scrap == 4 + value.parts * 2)

func restore(data: Dictionary) -> void:
	position.x = float(data.get("x", DOCK_X))
	route = int(data.get("route", Route.WAIT))
	cooldown = float(data.get("cooldown", 10))
	route_day = int(data.get("day", system.world.cycle.day))
	delivered = int(data.get("delivered", 0))
	cargo_parts = int(data.get("parts", 0))
	cargo_scrap = int(data.get("scrap", 0))
	blocked = false
	visible = system.sites[0].tier > 0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	draw_texture_rect(art, Rect2(-17, -21, 34, 18), false)
	if cargo_parts > 0:
		for index: int in 2: draw_texture_rect(CRATE, Rect2(-11 + index * 11, -30, 12, 11), false)
	for x: int in [-11, 11]:
		draw_circle(Vector2(x, -3), 3.5, Color("0b1322"))
		draw_circle(Vector2(x, -3), 2.5, Color("8299a8"))
		var spoke: Vector2 = Vector2.from_angle(wheel_angle * facing) * 2
		draw_line(Vector2(x, -3) - spoke, Vector2(x, -3) + spoke, Color("304356"), 1)
	draw_rect(Rect2(10, -16, 3, 2), Color("ffce75") if blocked else Color("47dacb"))
	draw_set_transform(Vector2.ZERO)
