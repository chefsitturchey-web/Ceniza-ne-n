class_name InvasionState
extends RefCounted

## Optional extension of version 1 checkpoints. Old checkpoints remain readable.
static func snapshot(session: SessionController) -> Dictionary:
	var result: Dictionary = {"parts": session.bank.parts, "shovel": session.interaction.workshop.shovel_ready,
		"dodge": session.player.dodge_cooldown_remaining, "poison": session.player._poison_accum,
		"props": [], "corpses": [], "traps": [], "rats": []}
	for prop: ScavengeProp in session.interaction.scavenge.props:
		result.props.append({"id": String(prop.data.id), "x": prop.position.x, "charges": prop.charges_left})
	for corpse: Corpse in session.corpse_system.corpses:
		if not is_instance_valid(corpse) or corpse.buried: continue
		result.corpses.append({"kind": String(corpse.kind), "x": corpse.position.x, "day": corpse.died_day,
			"reported": corpse.reported, "progress": corpse.bury_progress, "timer": corpse.rat_timer})
	for trap: RatTrap in session.trap_system.traps:
		result.traps.append({"armed": trap.armed, "cooldown": trap.cooldown})
	var sites: Array[ConstructionSite] = session.interaction.construction.defensive_sites()
	for rat: SewerRat in session.pest_system.rats:
		if not is_instance_valid(rat) or rat.is_queued_for_deletion(): continue
		result.rats.append({"x": rat.position.x, "state": rat.state, "time": rat.chew_time,
			"chews": rat.chews, "target": sites.find(rat.target_site), "exit": rat.exit_x})
	return result

static func number(data: Dictionary, key: String, low: float, high: float, integer: bool = false) -> bool:
	return ExpansionSystem.number(data.get(key), low, high, integer)

static func valid(value: Variant, session: SessionController, day: int) -> bool:
	if not value is Dictionary: return false
	var data: Dictionary = value
	if data.is_empty(): return true
	if not number(data, "parts", 0, 2147483647, true) or not data.get("shovel") is bool: return false
	if not number(data, "dodge", 0, Player.DODGE_COOLDOWN) or not number(data, "poison", 0, 1): return false
	for key: String in ["props", "corpses", "traps", "rats"]:
		if not data.get(key) is Array: return false
	if data.props.size() != session.interaction.scavenge.props.size() or data.traps.size() != session.trap_system.traps.size(): return false
	if data.corpses.size() > 4096 or data.rats.size() > PestSystem.MAX_RATS: return false
	for index: int in data.props.size():
		var prop: PropData = session.interaction.scavenge.props[index].data
		var entry: Variant = data.props[index]
		if not entry is Dictionary or entry.get("id") != String(prop.id): return false
		if not number(entry, "x", -GameRules.MAP_HALF_WIDTH, GameRules.MAP_HALF_WIDTH) or not number(entry, "charges", 0, prop.charges, true): return false
	for entry: Variant in data.corpses:
		if not entry is Dictionary or entry.get("kind") not in ["ally", "worker"] or not entry.get("reported") is bool: return false
		if not number(entry, "x", -GameRules.MAP_HALF_WIDTH, GameRules.MAP_HALF_WIDTH) or not number(entry, "day", 0, day, true): return false
		if not number(entry, "progress", 0, ColonySystem.BURY_DURATION) or not number(entry, "timer", 0, CorpseSystem.RAT_INTERVAL): return false
	for entry: Variant in data.traps:
		if not entry is Dictionary or not entry.get("armed") is bool or not number(entry, "cooldown", 0, TrapSystem.TRAP_COOLDOWN): return false
	for entry: Variant in data.rats:
		if not entry is Dictionary: return false
		if not number(entry, "x", -GameRules.MAP_HALF_WIDTH - 80, GameRules.MAP_HALF_WIDTH + 80) or not number(entry, "exit", -GameRules.MAP_HALF_WIDTH - 80, GameRules.MAP_HALF_WIDTH + 80): return false
		if not number(entry, "state", 0, 3, true) or not number(entry, "time", 0, PestSystem.CHEW_DURATION) or not number(entry, "chews", 0, PestSystem.CHEWS_BEFORE_FLEE, true): return false
		if not number(entry, "target", -1, session.interaction.construction.defensive_sites().size() - 1, true): return false
	return true

static func restore(session: SessionController, data: Dictionary) -> void:
	session.colony.burial_target = null
	for corpse: Corpse in session.corpse_system.corpses:
		if is_instance_valid(corpse): corpse.free()
	session.corpse_system.corpses.clear()
	for rat: SewerRat in session.pest_system.rats:
		if is_instance_valid(rat): rat.free()
	session.pest_system.rats.clear()
	session.bank.parts = int(data.get("parts", 0))
	session.interaction.workshop.shovel_ready = data.get("shovel", false)
	session.player.dodge_cooldown_remaining = data.get("dodge", 0.0)
	session.player._poison_accum = data.get("poison", 0.0)
	for index: int in session.interaction.scavenge.props.size():
		var prop: ScavengeProp = session.interaction.scavenge.props[index]
		var saved: Dictionary = data.get("props", [])[index] if not data.is_empty() else {"x": prop.position.x, "charges": prop.data.charges}
		prop.position.x = saved.x
		prop.charges_left = int(saved.charges)
		prop.depleted = prop.charges_left == 0
		prop.fill = prop.data.fill * 0.4 if prop.depleted else prop.data.fill
		prop.queue_redraw()
	for saved: Dictionary in data.get("corpses", []):
		var corpse: Corpse = session.corpse_system.spawn(Vector2(saved.x, GameRules.FLOOR_Y), StringName(saved.kind), int(saved.day))
		corpse.reported = saved.reported
		corpse.bury_progress = saved.progress
		corpse.rat_timer = saved.timer
	for index: int in session.trap_system.traps.size():
		var trap: RatTrap = session.trap_system.traps[index]
		var saved: Dictionary = data.get("traps", [])[index] if not data.is_empty() else {"armed": false, "cooldown": 0.0}
		trap.armed = saved.armed
		trap.cooldown = saved.cooldown
		trap.refresh_visual()
	var sites: Array[ConstructionSite] = session.interaction.construction.defensive_sites()
	for saved: Dictionary in data.get("rats", []):
		var rat: SewerRat = SewerRat.new()
		session.pest_system.add_child(rat)
		session.pest_system.rats.append(rat)
		rat.position = Vector2(saved.x, GameRules.FLOOR_Y)
		rat.state = int(saved.state)
		rat.chew_time = saved.time
		rat.chews = int(saved.chews)
		rat.target_site = sites[int(saved.target)] if saved.target >= 0 else null
		rat.exit_x = saved.exit
		rat.visible = rat.state != SewerRat.State.HIDE
	session.corpse_system.tick(0.0)
	session.bank.parts_changed.emit(session.bank.parts)
