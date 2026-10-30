class_name SettlementSystem
extends Node2D

const TARGET_BASE: int = -20000
const CACHE_BASE: int = -21000
const KEYS: Array[String] = ["servo", "coil", "filter"]
const NAMES: Array[String] = ["servomotor", "bobina de inducción", "membrana filtrante"]
const SHORT: Array[String] = ["Taller", "Armería", "Dispensario"]
const SHORT_PARTS: Array[String] = ["servo", "bobina", "filtro"]
const SPECS: Array[Dictionary] = [
	{"title": "Taller de reconstrucción", "core": 1, "parts": 8, "scrap": 35},
	{"title": "Armería del distrito", "core": 2, "parts": 12, "scrap": 50},
	{"title": "Dispensario comunitario", "core": 2, "parts": 10, "scrap": 40}
]
var world: District
var sites: Array[SettlementSupport] = []
var caches: Array[RelicCache] = []
var components: Array[int] = [0, 0, 0]
var healing_time: float = 0
var courier: SettlementCourier

func setup(district: District) -> void:
	world = district
	z_index = -1
	var anchors: Array[float] = [-2050, 3250, 4950]
	for index: int in 3:
		var site: SettlementSupport = SettlementSupport.new()
		site.system = self
		site.kind = index
		site.position = Vector2(find_space(anchors[index] + world.zone_index * 67), GameRules.FLOOR_Y)
		sites.append(site)
		add_child(site)
	for index: int in 6:
		var cache: RelicCache = RelicCache.new()
		cache.system = self
		cache.kind = index % 3
		var anchor: float = [-1450.0, 2200.0, -3350.0, 4100.0, -5350.0, 6150.0][index]
		cache.position = Vector2(find_space(anchor + world.zone_index * 43), GameRules.FLOOR_Y)
		caches.append(cache)
		add_child(cache)

	courier = SettlementCourier.new()
	courier.system = self
	add_child(courier)

func find_space(anchor: float) -> float:
	for attempt: int in 121:
		var x: float = anchor + ceili(attempt / 2.0) * 24 * (-1 if attempt % 2 == 0 else 1)
		if absf(x) > GameRules.MAP_HALF_WIDTH - 300: continue
		if world.interaction.target_at_x(x, true) != GameRules.NO_TARGET: continue
		var occupied: Array[float] = [world.story.rescue_x, world.story.relay_x, world.story.convoy_x, world.expedition.station.position.x, MobilitySystem.PAD_X]
		for site: ExpansionOutpost in world.expansion.sites: occupied.append(site.position.x)
		for site: ConstructionSite in world.construction.defensive_sites(): occupied.append(site.x)
		for site: SettlementSupport in sites: occupied.append(site.position.x)
		for cache: RelicCache in caches: occupied.append(cache.position.x)
		for prop: ScavengeProp in world.scavenge.props: occupied.append(prop.position.x)
		if occupied.any(func(other: float) -> bool: return absf(x - other) < 105): continue
		return x
	assert(false, "No accessible settlement slot")
	return anchor

func target_at(x: float) -> int:
	for index: int in sites.size():
		if absf(sites[index].position.x - x) < 36: return TARGET_BASE - index
	for index: int in caches.size():
		if not caches[index].claimed and absf(caches[index].position.x - x) < 30: return CACHE_BASE - index
	return GameRules.NO_TARGET

func effect(kind: int, tier: int) -> String:
	return ["Construcción +%d%%" % (25 * tier), "Daño de tropas y torretas +%d%%" % (15 * tier), "Cura %d de vida/s en 260 px" % (3 * tier)][kind]

func brief(kind: int, tier: int) -> String:
	return ["Obras +%d%%" % (25 * tier), "Daño aliado +%d%%" % (15 * tier), "Cura %d/s · 260 px" % (3 * tier)][kind]

func describe(target: int) -> Dictionary:
	if target <= CACHE_BASE:
		var cache: RelicCache = caches[CACHE_BASE - target]
		return {"text": "Recuperar " + NAMES[cache.kind] + " · estuche técnico", "cost": -1, "progress": 0.0, "key": world.core.tier > 0}
	var site: SettlementSupport = sites[TARGET_BASE - target]
	var spec: Dictionary = SPECS[site.kind]
	var text: String = SHORT[site.kind] + " Nv.%d · " % site.tier + brief(site.kind, maxi(1, site.tier))
	var cost: int = int(spec.scrap) + site.tier * 30
	var required: int = 3 if site.tier == 1 else int(spec.core)
	if site.ordered: text = "Restaurando " + spec.title + " · %d%%" % int(site.progress / site.duration() * 100)
	elif site.tier < 2:
		text += " · 1 " + SHORT_PARTS[site.kind] + " +%d piezas" % (int(spec.parts) + site.tier * 4)
		if world.core.tier < required: text = SHORT[site.kind] + " · " + brief(site.kind, maxi(1, site.tier)) + " · requiere núcleo Nv.%d" % required
		elif not world.civic.safe_to_build(site.position.x): text = "Cierra el portal de esta franja antes de restaurar"
	var available: bool = not site.ordered and site.tier < 2 and world.core.tier >= required and world.civic.safe_to_build(site.position.x)
	return {"text": text, "cost": cost if available else -1, "progress": site.progress / site.duration(), "key": available}

func interact(target: int) -> bool:
	if target <= CACHE_BASE:
		var index: int = CACHE_BASE - target
		if index < 0 or index >= caches.size(): return false
		var cache: RelicCache = caches[index]
		if cache.claimed or world.core.tier < 1 or not world.civic.safe_to_build(cache.position.x):
			world.presenter.show_notice("Enciende el núcleo y libera la franja para recuperar tecnología")
			return false
		cache.claimed = true
		components[cache.kind] += 1
		world.presenter.show_notice("Recuperado: " + NAMES[cache.kind] + " · protegido en el estuche")
		world.sound.play_cue("upgrade", -12)
		world.expansion.checkpoint()
		return true
	var index: int = TARGET_BASE - target
	if index < 0 or index >= sites.size(): return false
	var site: SettlementSupport = sites[index]
	var spec: Dictionary = SPECS[index]
	var required: int = 3 if site.tier == 1 else int(spec.core)
	if site.ordered or site.tier >= 2 or world.core.tier < required or not world.civic.safe_to_build(site.position.x):
		world.presenter.show_notice("Revisa el nivel del núcleo y el control de esta franja")
		return false
	var parts: int = int(spec.parts) + site.tier * 4
	var scrap: int = int(spec.scrap) + site.tier * 30
	if components[index] < 1:
		world.presenter.show_notice("Falta " + NAMES[index] + ": explora los depósitos señalados")
		return false
	if world.bank.parts + world.bank.stored_parts < parts or world.bank.scrap < scrap:
		world.presenter.show_notice("Restaurar requiere %d piezas y %d chatarra" % [parts, scrap])
		return false
	components[index] -= 1
	world.bank.spend_parts(parts)
	world.bank.spend(scrap)
	site.ordered = true
	site.progress = 0
	world.presenter.show_notice("Restauración encargada: espera a los constructores")
	world.expansion.checkpoint()
	return true

func refresh_bonuses() -> void:
	world.colony.work_factor = 1.0 + sites[0].tier * 0.25
	world.defenses.settlement_damage_factor = 1.0 + sites[1].tier * 0.15

func recovery_at(x: float) -> float:
	var recovery: float = 0.0
	for site: SettlementSupport in sites:
		if absf(site.position.x - x) < (900 if site.tier == 2 else 560): recovery = maxf(recovery, site.tier * 0.5)
	return recovery

func tick(delta: float) -> void:
	courier.tick(delta)
	for site: SettlementSupport in sites: site.tick(delta)
	for cache: RelicCache in caches: cache.tick(delta)
	healing_time += delta
	if healing_time >= 1:
		var amount: int = floori(healing_time) * sites[2].tier * 3
		healing_time = fmod(healing_time, 1)
		if amount > 0:
			var center: float = sites[2].position.x
			if world.player.health > 0 and absf(world.player.position.x - center) <= 260: world.player.health = mini(Player.MAX_HEALTH, world.player.health + amount)
			for ally: FieldAlly in get_tree().get_nodes_in_group(GameRules.ALLIES):
				if ally.hp > 0 and absf(ally.position.x - center) <= 260: ally.hp = mini(90, ally.hp + amount)
			for worker: ColonyWorker in world.colony.workers:
				if worker.hp > 0 and absf(worker.x - center) <= 260: worker.health_component.heal(amount)

func summary() -> String:
	return "Servomotores %d · Bobinas %d · Filtros %d\nBonificaciones: %s / %s / %s" % [components[0], components[1], components[2], effect(0, sites[0].tier), effect(1, sites[1].tier), effect(2, sites[2].tier)]

func journal_text() -> String:
	var text: String = "[color=#47dacb]POBLADOS · " + world.zone.title + "[/color]\n\n"
	text += "Mara: El catastro conserva los depósitos y las instalaciones que podemos recuperar. Sus componentes viajan en un estuche protegido: no se rompen ni ocupan la mochila.\n\n"
	for index: int in sites.size():
		var site: SettlementSupport = sites[index]
		var direction: String = "izquierda" if site.position.x < 0 else "derecha"
		text += "[color=#ffce75]%s · %s %d[/color]\n" % [SPECS[index].title, direction, int(absf(site.position.x))]
		text += ("En ruinas" if site.tier == 0 else "Nivel %d" % site.tier) + " · " + effect(index, maxi(1, site.tier)) + "\n"
		text += "Componente: %s · disponibles %d\n\n" % [NAMES[index], components[index]]
	text += courier.status() + "\n\n"
	text += "[color=#47dacb]DEPÓSITOS DE TECNOLOGÍA[/color]\n"
	for cache: RelicCache in caches:
		text += "%s · %s %d · %s\n" % [NAMES[cache.kind], "izq." if cache.position.x < 0 else "der.", int(absf(cache.position.x)), "recuperado" if cache.claimed else "sin explorar"]
	text += "\nLa primera restauración requiere 1 componente. La mejora requiere otro y núcleo Nv.3. Mantén E para encargar; los constructores deben llegar. Las bonificaciones pertenecen a esta colonia."
	return text

func snapshot() -> Dictionary:
	var buildings: Array = []
	for site: SettlementSupport in sites: buildings.append({"x": site.position.x, "tier": site.tier, "ordered": site.ordered, "progress": site.progress})
	var storage: Array = []
	for cache: RelicCache in caches: storage.append({"x": cache.position.x, "claimed": cache.claimed})
	return {"courier": courier.snapshot(), "sites": buildings, "caches": storage, "components": components.duplicate(), "healing": healing_time}

func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if not SettlementCourier.valid(value.get("courier", {})): return false
	if not value.get("sites") is Array or value.sites.size() != 3 or not value.get("caches") is Array or value.caches.size() != 6: return false
	if not value.get("components") is Array or value.components.size() != 3 or not ExpansionSystem.number(value.get("healing"), 0, 1): return false
	for index: int in 3:
		var entry: Variant = value.sites[index]
		if not entry is Dictionary or not entry.get("ordered") is bool: return false
		if not ExpansionSystem.number(entry.get("x"), -6900, 6900) or not ExpansionSystem.number(entry.get("tier"), 0, 2, true) or not ExpansionSystem.number(entry.get("progress"), 0, 45): return false
		if entry.tier == 2 and entry.ordered: return false
		if not ExpansionSystem.number(value.components[index], 0, 2, true): return false
	var recovered: Array[int] = [0, 0, 0]
	for index: int in 6:
		var entry: Variant = value.caches[index]
		if not entry is Dictionary or not entry.get("claimed") is bool or not ExpansionSystem.number(entry.get("x"), -6900, 6900): return false
		if entry.claimed: recovered[index % 3] += 1
	for index: int in 3:
		if recovered[index] != int(value.components[index]) + int(value.sites[index].tier) + (1 if value.sites[index].ordered else 0): return false
	return true

func restore(data: Dictionary) -> void:
	if data.is_empty():
		# Legacy checkpoints restore their original loot before new facilities choose space.
		var old_sites: Array[SettlementSupport] = sites.duplicate()
		var old_caches: Array[RelicCache] = caches.duplicate()
		sites.clear()
		caches.clear()
		for index: int in old_sites.size():
			old_sites[index].position.x = find_space(float([-2050, 3250, 4950][index]) + world.zone_index * 67)
			sites.append(old_sites[index])
		for index: int in old_caches.size():
			old_caches[index].position.x = find_space(float([-1450, 2200, -3350, 4100, -5350, 6150][index]) + world.zone_index * 43)
			caches.append(old_caches[index])
	components.assign(data.get("components", [0, 0, 0]))
	healing_time = float(data.get("healing", 0))
	for index: int in sites.size():
		var entry: Dictionary = data.sites[index] if not data.is_empty() else {}
		sites[index].position.x = float(entry.get("x", sites[index].position.x))
		sites[index].tier = int(entry.get("tier", 0))
		sites[index].ordered = entry.get("ordered", false)
		sites[index].progress = float(entry.get("progress", 0))
	for index: int in caches.size():
		var entry: Dictionary = data.caches[index] if not data.is_empty() else {}
		caches[index].position.x = float(entry.get("x", caches[index].position.x))
		caches[index].claimed = entry.get("claimed", false)
	courier.restore(data.get("courier", {}))
	refresh_bonuses()
