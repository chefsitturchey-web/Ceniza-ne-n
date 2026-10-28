class_name MobilitySystem
extends Node2D
## Transporte opcional de colonia; no altera las estadísticas del combate cenital.
const PAD_X: float = -880
const COST: int = 45
const SPEED_FACTOR: float = 1.45
const BOARD_HEIGHT: float = 13
const ART: Texture2D = preload("res://assets/structures/fortress/cargo_board.png")
var district: District
var owned: bool = false
var mounted: bool = false
var charge: float = 100
var parked_x: float = PAD_X
var elapsed: float = 0
var hud: CanvasLayer
var status: Label

func setup(world: District) -> void:
	district = world
	district.player.mobility = self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud = CanvasLayer.new()
	hud.layer = 4
	add_child(hud)
	status = Label.new()
	status.position = Vector2(200, 30)
	status.add_theme_font_size_override("font_size", 10)
	hud.add_child(status)

func _process(_delta: float) -> void:
	hud.visible = owned and not get_tree().paused and not district.expedition.active and not district.session.finished
	status.text = "PLATAFORMA %d%% - V %s" % [ceili(charge), "bajar" if mounted else "subir cerca"]
	queue_redraw()

func bob() -> float: return minf(0, roundf(sin(elapsed * 4)))

func rider_offset() -> float: return -10 + bob()

func target_at(x: float) -> bool:
	return (not owned and absf(x - PAD_X) < 25) or (owned and not mounted and absf(x - parked_x) < 25)

func describe() -> Dictionary:
	if owned: return {"text": "Subir a la plataforma - recarga quieto en núcleo o taller", "cost": -1}
	return {"text": "Plataforma de carga: requiere núcleo Nv.2", "cost": COST}

func interact() -> bool:
	if district.player.health <= 0: return false
	if owned: return toggle_mount()
	if absf(district.player.position.x - PAD_X) > 35: return false
	if not district.civic.safe_to_build(PAD_X):
		district.presenter.show_notice("Cierra la brecha que bloquea el taller de transporte")
		return false
	if district.core.tier < 2 or district.cycle.phase != "DÍA":
		district.presenter.show_notice("Plataforma: núcleo Nv.2 y compra de día")
		return false
	if not district.bank.spend(COST): return false
	owned = true
	mounted = true
	charge = 100
	apply_speed()
	checkpoint()
	return true

func toggle_mount() -> bool:
	if not owned or district.player.health <= 0: return false
	if mounted:
		mounted = false
		parked_x = district.player.position.x
	elif absf(district.player.position.x - parked_x) <= 45:
		mounted = true
	else:
		district.presenter.show_notice("La plataforma quedó en x=%d" % int(parked_x))
		return false
	apply_speed()
	checkpoint()
	return true

func apply_speed() -> void:
	district.player.travel_speed_factor = (SPEED_FACTOR if charge > 0 else 0.85) if mounted else 1.0

func tick(delta: float) -> void:
	elapsed += delta
	if not owned: return
	var player: Player = district.player
	if player.health <= 0 and mounted:
		mounted = false
		parked_x = player.position.x
	if Input.is_action_just_pressed("mount"): toggle_mount()
	var at_station: bool = absf(player.position.x) < 70 or absf(player.position.x - PAD_X) < 45
	if mounted and absf(player.velocity.x) > 10:
		charge = maxf(0, charge - delta * 4)
	elif at_station and absf(player.velocity.x) <= 10 and (mounted or absf(player.position.x - parked_x) < 45):
		charge = minf(100, charge + delta * 20)
	apply_speed()

func checkpoint() -> void:
	if district.session.save_system != null: district.session.save_system.save_game()

func snapshot() -> Dictionary:
	return {"owned": owned, "mounted": mounted, "charge": charge, "parked_x": parked_x}

func restore(data: Dictionary) -> void:
	owned = data.get("owned", false)
	mounted = data.get("mounted", false)
	charge = float(data.get("charge", 100))
	parked_x = float(data.get("parked_x", PAD_X))
	apply_speed()

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not data.get("owned") is bool or not data.get("mounted") is bool: return false
	return (not data.mounted or data.owned) and ExpansionSystem.number(data.get("charge"), 0, 100) and ExpansionSystem.number(data.get("parked_x"), -1600, 1600)

func _draw() -> void:
	# El apoyo del pasajero coincide con la cubierta, no con los márgenes del PNG.
	var source: Rect2 = ArtScale.source(ART)
	var origin: Vector2 = Vector2(district.player.position.x, GameRules.FLOOR_Y + bob()) if mounted else Vector2(parked_x, GameRules.FLOOR_Y)
	draw_set_transform(origin, 0, Vector2(district.player.facing if mounted else 1.0, 1))
	draw_texture_rect_region(ART, ArtScale.grounded(source, BOARD_HEIGHT), source, Color.WHITE if charge > 0 else Color("8299a8"))
	if mounted and charge > 0 and GamePreferences.current().particles:
		for index: int in range(3):
			draw_line(Vector2(-13 + index * 11, -2), Vector2(-13 + index * 11, 0), Color("47dacb", 0.4), 1)
	draw_set_transform(Vector2.ZERO)
