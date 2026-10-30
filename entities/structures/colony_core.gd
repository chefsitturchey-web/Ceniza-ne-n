class_name ColonyCore
extends Node2D

## El estado del mundo se comunica con efectos, nunca con barras.
const WORLD_BARS_ENABLED: bool = false

const TEXTURE: Texture2D = preload("res://assets/world/structures/core_01.png")

var effects: StructureEffects = StructureEffects.new()

var health_component: HealthComponent = HealthComponent.new()
var tier: int = 0
var ordered: bool = false
var progress: float = 0
var district: District
const BUILD_TIME: float = 24

func upgrade_cost() -> int: return 20 if tier == 0 else FortressRules.UPGRADE_COSTS[tier - 1]

func parts_cost() -> int: return [12, 10, 18, 0][tier]

func upgrade_blocker() -> String:
	if tier >= 3: return "Núcleo al máximo"
	if ordered: return "Núcleo en obras"
	if district == null: return "Colonia no disponible"
	if tier == 0: return ""
	if district.expansion.energy_bonus() == 0: return "Primero construye un generador"
	var walls: int = 0
	for site: ConstructionSite in district.construction.sites:
		if site.data.blocks_enemies and site.hp > 0: walls += 1
	if walls < 2: return "Termina las dos murallas centrales"
	if tier == 2:
		if district.cycle.day < 2: return "Nv.3: resiste al menos una noche"
		var built: int = 0
		for site: ExpansionOutpost in district.expansion.sites:
			if site.hp > 0: built += 1
		if built < 2: return "Nv.3: construye dos instalaciones"
	return ""

func request_upgrade() -> bool:
	var reason: String = upgrade_blocker()
	if not reason.is_empty():
		if district != null:
			district.presenter.show_notice(reason)
			district.play("denied")
		return false
	if district.bank.parts + district.bank.stored_parts < parts_cost():
		district.presenter.show_notice("Necesitas %d piezas para el núcleo" % parts_cost())
		return false
	if not district.bank.spend(upgrade_cost()):
		district.presenter.show_notice("Falta chatarra para mejorar el núcleo")
		district.play("denied")
		return false
	district.bank.spend_parts(parts_cost())
	ordered = true
	progress = 0
	district.presenter.show_notice("Núcleo encargado: espera a los constructores")
	district.play("build_order")
	return true

func complete_work() -> void:
	if not ordered: return
	var previous: int = health_component.maximum
	tier = mini(3, tier + 1)
	health_component.maximum = FortressRules.CORE_HEALTH[maxi(1, tier) - 1]
	if tier == 1: health_component.reset()
	else: health_component.heal(health_component.maximum - previous)
	ordered = false
	progress = 0
	effects.repair_sparks()
	if district != null and tier == 1:
		district.presenter.show_notice("Núcleo encendido: almacena piezas y prepara la primera noche")
		district.story.queue_dialogue("foundation")
	elif district != null:
		district.presenter.show_notice("Núcleo Nv.2: defensas, apoyo y transporte" if tier == 2 else "Núcleo Nv.3: fortificaciones avanzadas")
		district.play("build_done")
	if district != null and district.session.save_system != null: district.session.save_system.save_game()

func snapshot() -> Dictionary: return {"tier": tier, "ordered": ordered, "progress": progress}

func restore(data: Dictionary) -> void:
	tier = int(data.get("tier", 1))
	ordered = data.get("ordered", false)
	progress = float(data.get("progress", 0))
	health_component.maximum = FortressRules.CORE_HEALTH[maxi(1, tier) - 1]
	queue_redraw()

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	return ExpansionSystem.number(data.get("tier"), 0, 3, true) and data.get("ordered") is bool and ExpansionSystem.number(data.get("progress"), 0, BUILD_TIME) and (data.tier < 3 or not data.ordered) and (data.ordered or data.progress == 0)

static func saved_tier(document: Dictionary) -> int:
	if document.has("core_building"): return int(document.core_building.get("tier", 1))
	# Migrar fortificaciones antiguas sin rebajarlas ni bloquear su reconstrucción.
	var result: int = 1
	var structures: Variant = document.get("structures", [])
	if structures is Array:
		for site: Variant in structures:
			if site is Dictionary and ExpansionSystem.number(site.get("tier", 1), 1, 3, true): result = maxi(result, int(site.get("tier", 1)))
	var civic: Variant = document.get("civic", {})
	if civic is Dictionary:
		for site: Variant in civic.get("walls", []):
			if site is Dictionary and ExpansionSystem.number(site.get("tier", 1), 1, 3, true): result = maxi(result, int(site.get("tier", 1)))
		var capacity: int = int(civic.get("capacity", 8))
		if capacity > 8: result = maxi(result, 3 if capacity > 16 else 2)
	var expansion: Variant = document.get("expansion", {})
	if expansion is Dictionary:
		for site: Variant in expansion.get("sites", []):
			if site is Dictionary and (float(site.get("hp", 0)) > 0 or site.get("ordered", false)) and site.get("id", "") in ["medical", "recycler"]: result = maxi(result, 2)
	return result
var health: int:
	get: return health_component.current
	set(value):
		health_component.reset(value)
		queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	health_component.maximum = GameRules.CORE_HEALTH
	health_component.reset()
	add_child(health_component)
	health_component.damaged.connect(_on_health_changed)
	health_component.healed.connect(_on_health_changed)
	add_child(effects)
	effects.setup(health_component, TEXTURE)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func _on_health_changed(_amount: int, _remaining: int) -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if tier == 0:
		var rubble: Texture2D = preload("res://assets/world/props/scrap.png")
		draw_texture_rect(rubble, Rect2(-32, -18, 64, 18), false, Color("6b7e8c"))
		for side: int in [-1, 1]:
			draw_line(Vector2(side * 44, 0), Vector2(side * 44, -8 if not ordered else -64), Color("8299a8"), 3)
			draw_line(Vector2(side * 44, -5), Vector2(side * 28, -5), Color("47dacb"), 2)
		if ordered:
			draw_line(Vector2(-44, -52), Vector2(44, -52), Color("8c674d"), 3)
			for step: int in 5:
				if progress / BUILD_TIME > step / 5.0: draw_rect(Rect2(-28 + step * 11, -36, 9, 28), Color("304356"))
		return
	var art: Texture2D = FortressArt.texture("core", tier)
	var source: Rect2 = ArtScale.source(art)
	var frame: Rect2 = ArtScale.grounded(source, FortressArt.CORE_HEIGHTS[tier - 1])
	var offset: Vector2 = Vector2(2 if int(effects.elapsed * 40) % 2 == 0 else -1, 0) if effects.shake > 0 and not GamePreferences.current().reduced_flashes else Vector2.ZERO
	effects.position = offset
	draw_set_transform(offset)
	ArtScale.footing(self, frame)
	draw_texture_rect_region(art, frame, source)
	if ordered:
		for side: int in [-1, 1]: draw_line(Vector2(side * frame.size.x * 0.5, 0), Vector2(side * frame.size.x * 0.5, frame.position.y - 5), Color("8299a8"), 2)
		for index: int in range(ceili(upgrade_cost() / 10.0)):
			draw_circle(Vector2((index - 3) * 6, frame.position.y - 10), 1.5, Color("ffce75") if index < progress / BUILD_TIME * 6 else Color("8299a8"))
	if health > 0:
		var intensity: float = 0.75 if GamePreferences.current().reduced_flashes else 0.55 + sin(effects.elapsed * 2) * 0.2
		var color: Color = Color("47dacb") if health > health_component.maximum * 0.3 else Color("ffce75")
		for index: int in range(3):
			draw_rect(Rect2(-16 + index * 5, -8, 3, 1), Color(color, intensity))
	draw_set_transform(Vector2.ZERO)
