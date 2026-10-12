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
var notice: String = "Construye ambas murallas y torretas antes de la noche."
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

func _player_damaged(_amount: int, _remaining: int) -> void:
	player_hit += 1

func _core_damaged(_amount: int, _remaining: int) -> void:
	core_hit += 1

func publish() -> void:
	if not damage_connected:
		player.health_component.damaged.connect(_player_damaged)
		core.health_component.damaged.connect(_core_damaged)
		damage_connected = true
	if cycle.phase == "NOCHE" and core.health > 0 and core.health <= GameRules.CORE_HEALTH * 0.3 and warned_night != cycle.day:
		warned_night = cycle.day
		show_notice("¡El núcleo se está rompiendo!")
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
	var text: String = "CENIZA NEÓN  |  %s %d/%d · %ds  |  Chatarra %d  |  Energía %d/%d\n" % [cycle.phase, cycle.day, cycle.config.nights, ceili(cycle.phase_remaining), bank.scrap, bank.energy_used(), bank.energy_capacity]
	text += "Vida %d  ·  Resistencia %d  ·  Núcleo %d/%d  ·  Habitantes %d/%d\n" % [player.health, int(player.stamina), core.health, GameRules.CORE_HEALTH, colony.workers.size(), GameRules.POPULATION]
	text += "Amenazas  ◀ %d / %d ▶  |  Sobrecarga IZQ %s / DER %s\n" % [left_count, right_count, overload.overload_status(true), overload.overload_status(false)]
	text += "A/D mover · J ataque · Espacio esquiva · E obra · Q sobrecarga · Esc pausa"
	var context: String = ""
	var context_screen: Vector2 = Vector2.ZERO
	var target: int = interaction.interaction_target()
	if target == -1:
		context = "Mantén E: curarte gratis · Solo de día" if player.health < Player.MAX_HEALTH else "Mantén E: reclutar (15 chatarra) · Solo de día"
		context_screen = core.get_global_transform_with_canvas() * Vector2(0, -ColonyCore.TEXTURE.get_height())
	elif target >= 0:
		var site: ConstructionSite = construction.sites[target]
		context_screen = site.get_global_transform_with_canvas() * Vector2(0, -site.data.texture.get_height() if site.data.texture != null else -45)
		var title: String = site.data.display_name
		if site.data.energy > 0:
			title += " (%d energía)" % site.data.energy
		if site.ordered:
			context = "%s · Obra %d%% · Esperando trabajo seguro" % [title, int(site.progress / GameRules.BUILD_TIME * 100)]
		elif site.hp == site.max_hp:
			context = ""
		else:
			context = "%s · Mantén E: %s (%d chatarra)" % [title, "construir" if site.hp == 0 else "reparar", site.cost if site.hp == 0 else site.data.repair_cost]
	if interaction.hold_time > 0.0 and not context.is_empty():
		context += "  %d%%" % int(interaction.hold_time / GameRules.INTERACT_HOLD * 100)
	var hint_text: String = context + "\n" + (notice if notice_time > 0.0 else "Mando: X ataque · A esquiva · Y obra · LB sobrecarga · Start pausa")
	var result_text: String = ""
	if player.health <= 0:
		result_text = "Reenlace en %d s\n¡La colonia sigue defendiéndose!" % ceili(player.respawn_remaining)
	if get_tree().paused:
		result_text = ""
	if session.finished:
		result_text = ("DISTRITO ESTABILIZADO" if session.won else "NÚCLEO DESTRUIDO") + "\n\nR / Select: nueva partida"
	updated.emit(text, hint_text, result_text)
	dashboard_updated.emit({
		"paused": get_tree().paused, "finished": session.finished,
		"context": context, "context_screen": context_screen,
		"notice": notice if notice_time > 0 else "", "notice_time": notice_time,
		"player_hit": player_hit, "core_hit": core_hit, "health_max": Player.MAX_HEALTH,
		"offscreen_left": offscreen_left, "offscreen_right": offscreen_right,
		"phase": cycle.phase, "day": cycle.day, "nights": cycle.config.nights,
		"seconds": ceili(cycle.phase_remaining), "scrap": bank.scrap,
		"energy": bank.energy_used(), "capacity": bank.energy_capacity,
		"population": colony.workers.size(), "population_max": GameRules.POPULATION,
		"health": player.health, "stamina": int(player.stamina), "core": core.health,
		"left": left_count, "right": right_count,
		"overload_left": overload.overload_status(true), "overload_right": overload.overload_status(false)
	})
