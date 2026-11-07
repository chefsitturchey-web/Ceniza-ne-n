class_name RoundEngagement
extends Node
## Las bajas de tropas también pertenecen al comandante. No sustituye el botín base.
signal combo_changed(multiplier: int)
signal achievement_unlocked(title: String)
signal result_ready(stats: Dictionary)
signal goal_changed
signal reward_awarded(at: Vector2, amount: int)
var world: District
var kills: int = 0
var night_kills: int = 0
var combo: int = 0
var best_combo: int = 0
var combo_left: float = 0
var walls_lost: int = 0
var goal_paid: bool = false
var nights: int = 0
var earned: int = 0
var night_active: bool = false
var enabled: bool = true
var persist: bool = true
var unlocked: Array = []
const ACHIEVEMENTS: Dictionary = {"first": "Primera baja", "ten": "Diez máquinas", "fifty": "Cincuenta máquinas", "combo": "Cadena de tres", "walls": "Doble muralla", "night": "Primer amanecer", "clean": "Defensa perfecta"}

func setup(district: District) -> void:
	world = district
	persist = world.session.persistence_enabled and not world.session.debug_practice
	enabled = persist
	unlocked = SaveSystem.engagement_profile().achievements.duplicate()
	world.director.spawned.connect(func(enemy: SiegeEnemy, _side: float) -> void:
		enemy.reward_requested.connect(func(reward: int) -> void:
			register_kill(reward)
			if enabled: reward_awarded.emit(enemy.global_position, reward * mini(combo, 5))))
	for site: ConstructionSite in world.construction.sites:
		site.destroyed.connect(func() -> void:
			if night_active and site.data.blocks_enemies:
				walls_lost += 1
				goal_changed.emit())
	world.cycle.phase_changed.connect(on_phase)
	world.session.finished_changed.connect(func(won: bool) -> void:
		if enabled and not world.session.debug_practice: result_ready.emit(result(won, false)))

func tick(delta: float) -> void:
	if not enabled or world.session.debug_practice: return
	combo_left = maxf(0, combo_left - delta)
	if combo_left == 0 and combo > 0:
		combo = 0
		combo_changed.emit(0)
	var walls: int = 0
	for site: ConstructionSite in world.construction.sites:
		if site.data.blocks_enemies and site.hp > 0: walls += 1
	if walls >= 2: unlock("walls")

func register_kill(base_reward: int) -> void:
	if not enabled or world.session.debug_practice: return
	combo = combo + 1 if combo_left > 0 else 1
	combo_left = 2.5
	best_combo = maxi(best_combo, combo)
	kills += 1
	if night_active: night_kills += 1
	var multiplier: int = mini(combo, 5)
	var bonus: int = maxi(0, base_reward) * (multiplier - 1)
	world.bank.deposit(bonus)
	earned += maxi(0, base_reward) + bonus
	combo_changed.emit(multiplier)
	unlock("first")
	if kills >= 10: unlock("ten")
	if kills >= 50: unlock("fifty")
	if combo >= 3: unlock("combo")
	goal_changed.emit()

func on_phase(phase: String, _day: int) -> void:
	if not enabled or world.session.debug_practice: return
	if phase == "NOCHE":
		night_active = true
		night_kills = 0
		walls_lost = 0
		goal_paid = false
		combo = 0
		combo_left = 0
		goal_changed.emit()
	elif phase == "DÍA" and night_active:
		night_active = false
		nights += 1
		unlock("night")
		if walls_lost == 0: unlock("clean")
		if night_kills >= 10 and walls_lost == 0 and not goal_paid:
			goal_paid = true
			world.bank.deposit(25)
			earned += 25
			# El guardado de amanecer precede a esta señal: incluir el premio.
			if world.session.save_system != null: world.session.save_system.save_game()
		result_ready.emit(result(true, true))

func goal() -> String:
	if walls_lost > 0: return "Meta perdida. Próxima noche: +25"
	return "Noche: %d/10 bajas sin perder muros. +25" % mini(10, night_kills)

func result(victory: bool, dawn: bool) -> Dictionary:
	var stars: int = 1 + int(victory) + int(victory and walls_lost == 0 and night_kills >= 10)
	var score: int = kills * 10 + best_combo * 5 + nights * 100
	var profile: Dictionary = SaveSystem.engagement_profile()
	var record: int = maxi(int(profile.record), score)
	if persist:
		profile.record = record
		SaveSystem.store_engagement(profile)
	return {"victory": victory, "dawn": dawn, "stars": stars, "kills": kills, "combo": best_combo, "scrap": earned, "record": record, "goal": goal_paid}

func unlock(id: String) -> void:
	if id in unlocked or not ACHIEVEMENTS.has(id): return
	unlocked.append(id)
	if persist:
		var profile: Dictionary = SaveSystem.engagement_profile()
		profile.achievements = unlocked.duplicate()
		SaveSystem.store_engagement(profile)
	achievement_unlocked.emit(ACHIEVEMENTS[id])
