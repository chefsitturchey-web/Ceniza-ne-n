class_name HudPresenter
extends Node

const INITIAL_NOTICE_DURATION: float = 3.0
const NOTICE_DURATION: float = 3.0
signal updated(text: String, hint: String, result: String)
signal dashboard_updated(values: Dictionary)
var player: Player
var cycle: CycleSystem
var bank: ResourceBank
var core: ColonyCore
var colony: ColonySystem
var construction: ConstructionSystem
var overload: OverloadSystem
var interaction: InteractionSystem
var session: SessionController
var neural: NeuralSystem
var notice: String = "DEFIENDE EL NÚCLEO"
var notice_time: float = INITIAL_NOTICE_DURATION

func tick(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)

func show_notice(message: String) -> void:
	notice = message
	notice_time = NOTICE_DURATION

var player_hit: int = 0
var core_hit: int = 0
var warned_night: int = -1
var damage_connected: bool = false

func objective_text() -> String:
	if interaction.story != null: return interaction.story.objective()
	var fortifications: int = 0
	var completed: int = 0
	for site: ConstructionSite in construction.sites:
		if site.hp > 0 or site.ordered:
			fortifications += 1
		if site.hp > 0:
			completed += 1
	if fortifications < construction.sites.size():
		return "Construye las defensas de ambos lados - mantener E"
	if completed < construction.sites.size():
		return "Las defensas se están construyendo - protege las obras"
	if session.civic != null and not session.civic.stabilized():
		return "Estabiliza: resiste una noche y construye un generador"
	if interaction.expedition == null:
		return "Defiende el núcleo hasta el amanecer"
	var expedition: ExpeditionManager = interaction.expedition
	var destroyed: int = 0
	for repeater: EnemyRepeater in expedition.repeaters:
		if repeater.health.current <= 0:
			destroyed += 1
	if destroyed < 2:
		return "Antenas enemigas: %d/2 - busca los extremos del distrito" % destroyed
	if session.civic != null:
		var open_gates: int = 0
		for gate: EnemyRepeater in session.civic.gates:
			if gate.health.current > 0: open_gates += 1
		if open_gates > 0: return "Cierra las %d brechas de entrada restantes" % open_gates
	if not expedition.station.train_arrived:
		return "Antenas destruidas - espera el tren en la estación"
	return "Tren listo - mantén E en la estación" if cycle.phase == "DÍA" else "Resiste hasta el amanecer para viajar en tren"

func _player_damaged(_amount: int, _remaining: int) -> void:
	player_hit += 1

func _core_damaged(_amount: int, _remaining: int) -> void:
	core_hit += 1

func publish() -> void:
	if not damage_connected:
		player.health_component.damaged.connect(_player_damaged)
		core.health_component.damaged.connect(_core_damaged)
		damage_connected = true
	if cycle.phase == "NOCHE" and core.health > 0 and core.health <= core.health_component.maximum * 0.3 and warned_night != cycle.day:
		warned_night = cycle.day
		show_notice("Núcleo dañado")
	var offscreen_left: int = 0
	var offscreen_right: int = 0
	var screen_width: float = get_viewport().get_visible_rect().size.x
	var left_count: int = 0
	var right_count: int = 0
	for enemy: Node2D in get_tree().get_nodes_in_group(GameRules.ENEMIES):
		# get_global_transform_with_canvas incluye desplazamiento, zoom y suavizado de cámara.
		var screen_x: float = enemy.get_global_transform_with_canvas().origin.x
		var half_width: float = 12.0
		if enemy is SiegeEnemy and enemy.sprite != null:
			var texture: Texture2D = enemy.sprite.sprite_frames.get_frame_texture(enemy.sprite.animation, enemy.sprite.frame)
			half_width = texture.get_width() * 0.5 * absf(enemy.get_global_transform_with_canvas().get_scale().x)
		if screen_x + half_width < 0:
			offscreen_left += 1
		elif screen_x - half_width > screen_width:
			offscreen_right += 1
		if enemy.position.x < 0:
			left_count += 1
		else:
			right_count += 1
	var text: String = "%s %d" % [cycle.phase, cycle.day]
	var context: String = ""
	var context_cost: int = -1
	var context_progress: float = interaction.hold_time / GameRules.INTERACT_HOLD
	var context_key: bool = true
	var context_screen: Vector2 = Vector2.ZERO
	var target: int = interaction.interaction_target()
	if target <= -400 and interaction.story != null:
		var detail: Dictionary = interaction.story.describe(target)
		context = detail.text
		context_cost = detail.cost
		context_screen = player.get_global_transform_with_canvas() * Vector2(0, -65)
	elif target <= -300 and interaction.civic != null:
		var detail: Dictionary = interaction.civic.describe(target)
		context = detail.text
		context_cost = detail.cost
		context_key = not detail.get("locked", false) and cycle.phase == "DÍA"
		context_screen = player.get_global_transform_with_canvas() * Vector2(0, -60)
	elif target <= -200 and interaction.expansion != null:
		context = "Recuperar suministros: +20"
		context_screen = interaction.expansion.get_global_transform_with_canvas() * Vector2(ExpansionSystem.CACHE_X[-200 - target], GameRules.FLOOR_Y - 25)
	elif target <= -100 and interaction.expansion != null:
		var outpost: ExpansionOutpost = interaction.expansion.sites[-100 - target]
		context = outpost.spec.title + (": operativo" if outpost.hp >= outpost.MAX_HEALTH else (": desplegando" if outpost.ordered else (": reparar" if outpost.hp > 0 else ": desplegar")))
		if outpost.hp >= outpost.MAX_HEALTH:
			var purpose: Dictionary = {"generator": "+2 energía", "recycler": "+5 chatarra / 12 s de día", "barracks": "guarnición", "medical": "puesto de médicos"}
			context = outpost.spec.title + ": " + (String(purpose[outpost.spec.id]) if interaction.expansion.powered(outpost) else "sin energía")
		context_cost = -1 if outpost.hp >= outpost.MAX_HEALTH or outpost.ordered else (12 if outpost.hp > 0 else int(outpost.spec.cost))
		context_key = cycle.phase == "DÍA" and not outpost.ordered and outpost.hp < outpost.MAX_HEALTH
		context_progress = outpost.progress / 6 if outpost.ordered else context_progress
		context_screen = outpost.get_global_transform_with_canvas() * Vector2(0, -48)
		var required: int = FortressRules.BUILDINGS[outpost.spec.id]
		if core.tier < required:
			context = outpost.spec.title + ": requiere núcleo Nv.%d" % required
			context_key = false
			context_cost = -1
	elif target == InteractionSystem.MOBILITY_TARGET:
		var detail: Dictionary = interaction.mobility.describe()
		context = detail.text
		context_cost = detail.cost
		context_screen = player.get_global_transform_with_canvas() * Vector2(0, -35)
	elif target == InteractionSystem.CLINIC_TARGET:
		context = "Clínica: %d puntos" % neural.points() if cycle.phase == "DÍA" else "Clínica: solo de día"
		context_key = cycle.phase == "DÍA"
		context_screen = interaction.clinic.get_global_transform_with_canvas() * Vector2(0, -45)
	elif target == InteractionSystem.STATION_TARGET:
		var expedition: ExpeditionManager = interaction.expedition
		context = "Destruye los repetidores"
		if session.civic != null and not session.civic.stabilized(): context = "Falta estabilizar: una noche y generación eléctrica"
		if expedition.all_destroyed():
			context = "Tren en camino" if not expedition.station.train_arrived else ("Viajar" if cycle.phase == "DÍA" else "Solo de dia")
		context_key = expedition.can_travel()
		if not context_key:
			context_progress = 0
		context_screen = expedition.station.get_global_transform_with_canvas() * Vector2(0, -56)
	elif target == -1:
		context = "Curarte" if player.health < Player.MAX_HEALTH else "Núcleo Nv.%d - mejorar a Nv.%d" % [core.tier, mini(3, core.tier + 1)]
		context_cost = -1 if player.health < Player.MAX_HEALTH else core.upgrade_cost()
		if player.health == Player.MAX_HEALTH:
			var reason: String = core.upgrade_blocker()
			if not reason.is_empty(): context = reason; context_key = false; context_cost = -1
			if core.ordered: context_progress = core.progress / ColonyCore.BUILD_TIME
		context_screen = core.get_global_transform_with_canvas() * Vector2(0, -FortressArt.CORE_HEIGHTS[core.tier - 1])
	elif target >= 0:
		var site: ConstructionSite = construction.sites[target]
		context_screen = site.get_global_transform_with_canvas() * Vector2(0, -site.visual_height())
		if site.ordered:
			context = "Construyendo"
			context_key = false
			context_progress = site.progress / GameRules.BUILD_TIME
		elif site.hp != site.max_hp:
			context = "Construir" if site.hp == 0 else "Reparar"
			context_cost = site.cost if site.hp == 0 else site.data.repair_cost
		elif site.tier < 3:
			context = "Mejorar %s %d > %d" % ["muralla" if site.data.blocks_enemies else "torreta", site.tier, site.tier + 1]
			context_cost = site.tier * 25
			if site.tier >= core.tier:
				context = "Necesitas núcleo Nv.%d" % (site.tier + 1)
				context_key = false
				context_cost = -1
		elif site.kind == &"turret":
			context = "T: apagar torreta" if site.powered else "T: reactivar torreta"
		if site.kind == &"turret": context += " - T: energía"
	var hint_text: String = context
	var result_text: String = ""
	if player.health <= 0:
		result_text = "Reenlace %d s" % ceili(player.respawn_remaining)
	if get_tree().paused:
		result_text = ""
	if session.finished:
		result_text = ("DISTRITO ESTABILIZADO" if session.won else "NÚCLEO DESTRUIDO") + "\n\n[R] Reintentar"
	updated.emit(text, hint_text, result_text)
	dashboard_updated.emit({
		"objective": objective_text(),
		"paused": get_tree().paused, "finished": session.finished,
		"context": context, "context_cost": context_cost,
		"context_progress": context_progress, "context_key": context_key, "context_screen": context_screen,
		"notice": notice if notice_time > 0 else "", "notice_time": notice_time,
		"player_hit": player_hit, "core_hit": core_hit, "health_max": Player.MAX_HEALTH,
		"offscreen_left": offscreen_left, "offscreen_right": offscreen_right,
		"phase": cycle.phase, "day": cycle.day, "nights": cycle.config.nights,
		"seconds": ceili(cycle.phase_remaining), "scrap": bank.scrap,
		"energy": bank.energy_used(), "capacity": bank.available_capacity(),
		"population": session.civic.population() if session.civic != null else colony.workers.size(), "population_max": session.civic.capacity if session.civic != null else GameRules.POPULATION,
		"health": player.health, "stamina": int(player.stamina), "core": core.health, "core_max": core.health_component.maximum,
		"left": left_count, "right": right_count,
		"overload_left": overload.overload_status(true), "overload_right": overload.overload_status(false),
		"poisoned": player.poison_dps > 0.0
	})
