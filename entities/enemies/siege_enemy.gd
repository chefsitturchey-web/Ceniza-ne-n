class_name SiegeEnemy
extends Node2D
## Las animaciones no determinan el instante del daño.
@export var sprite_faces_right: bool = true
@export var detailed_silhouette: bool = true
enum State { APPROACH, WINDUP, ATTACK, DEAD }
const DEATH_VISUAL_GRACE: float = 0.1
signal state_changed(state: State)
signal reward_requested(amount: int)
@export var data: EnemyData
var player: Player
var construction: ConstructionSystem
var core: ColonyCore
var session: SessionController
var facing: float = 1.0
var night: int = 1
var elite: bool = false
var state: State = State.APPROACH
var health_component: HealthComponent
var hurtbox: HurtboxComponent
var visual: EnemyVisual
var health: int:
	get: return health_component.current
	set(value): health_component.reset(value)
var max_health: int = 100
var speed: float = 32.0
var damage: int = 12
var cooldown: float = 0.0
var windup: float = 0.0
var target_kind: String = ""
var target_index: int = -1
var ally_target: Node2D
var flash: float = 0.0
var hurt_remaining: float = 0.0
var death_remaining: float = 0.0
var attack_visual_remaining: float = 0.0
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	# Las escenas heredadas pueden reasignar el script al instanciarse.
	# Crear nodos aquí evita componentes huérfanos de los inicializadores anteriores.
	health_component = HealthComponent.new()
	hurtbox = HurtboxComponent.new()
	visual = EnemyVisual.new()
	if data == null:
		data = EnemyData.new()
	add_child(health_component)
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	hurtbox.hit.connect(take_damage)
	add_child(hurtbox)
	visual.actor = self
	add_child(visual.effects)
	add_child(visual)
	visual.bind(sprite)
	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)
		visual.play_visual(&"reposo")
	max_health = data.health + (night - 1) * data.health_per_night
	health_component.maximum = max_health
	health_component.reset()
	speed = data.speed
	damage = data.damage
	face_toward(0.0)
	if session != null:
		add_to_group(GameRules.ENEMIES)

func set_state(value: State) -> void:
	if state != value:
		state = value
		state_changed.emit(state)

func face_toward(x: float) -> void:
	if not is_equal_approx(position.x, x):
		facing = signf(x - position.x)
	queue_redraw()
	if sprite != null and not is_equal_approx(position.x, x):
		sprite.flip_h = (x < position.x) if sprite_faces_right else (x > position.x)

func update_visual(moving: bool = false) -> void:
	visual.update_state(moving)

func get_hurt_rect() -> Rect2:
	return hurtbox.world_rect()

## Los disparos llevan origen y tipo; el cuerpo a cuerpo conserva Hurtbox.receive.
func receive_shot(amount: int, _origin: Vector2, _electric: bool = false) -> void:
	hurtbox.receive(amount)

func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health_component.take_damage(amount)
	queue_redraw()
	visual.hit_effects(health == 0)
	flash = data.flash_duration
	hurt_remaining = data.hurt_duration
	if health == 0:
		set_state(State.DEAD)
		remove_from_group(GameRules.ENEMIES)
		reward_requested.emit(data.reward)
		windup = 0.0
		if sprite != null and visual.animation_duration(&"destruccion") > 0.0:
			sprite.modulate = visual.base_tint
			visual.play_visual(&"destruccion")
			death_remaining = visual.animation_duration(&"destruccion") + DEATH_VISUAL_GRACE
		elif data.id in [&"artillero", &"saboteador"]:
			death_remaining = 0.7
		else:
			queue_free()
		visual.queue_redraw()
		return
	update_visual()

func _on_animation_finished() -> void:
	if health <= 0 and sprite.animation == &"destruccion":
		queue_free()

func _physics_process(delta: float) -> void:
	if session == null:
		return
	if health <= 0:
		death_remaining -= delta
		if death_remaining <= 0.0:
			queue_free()
		return
	if session.finished:
		if sprite != null:
			sprite.pause()
		return
	flash = maxf(0.0, flash - delta)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	attack_visual_remaining = maxf(0.0, attack_visual_remaining - delta)
	cooldown = maxf(0.0, cooldown - delta)
	if state == State.WINDUP:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			set_state(State.ATTACK)
			land_hit()
			cooldown = data.cooldown
		update_visual()
		return
	var moving: bool = false
	if choose_special_target(delta): return
	ally_target = null
	for ally: Node in get_tree().get_nodes_in_group(GameRules.ALLIES):
		if absf(ally.position.x - position.x) < 30 and ally.position.y >= GameRules.FLOOR_Y - 20:
			ally_target = ally as Node2D
			break
	if player.health > 0 and absf(player.position.x - position.x) < data.player_notice_range:
		target_kind = "player"
		face_toward(player.position.x)
	elif is_instance_valid(ally_target):
		target_kind = "ally"
		face_toward(ally_target.position.x)
	elif find_wall() >= 0:
		target_kind = "wall"
		target_index = find_wall()
		face_toward(construction.defensive_sites()[target_index].x)
	elif absf(position.x) < data.core_range:
		target_kind = "core"
		face_toward(0.0)
	else:
		target_kind = ""
		face_toward(0.0)
		position.x = move_toward(position.x, 0.0, speed * delta)
		moving = true
		set_state(State.APPROACH)
	if target_kind != "" and cooldown == 0.0:
		set_state(State.WINDUP)
		windup = data.windup
		attack_visual_remaining = data.attack_visual_duration
		# Reinicia el ciclo solo al iniciar un ataque real, no cada fotograma.
		if sprite != null:
			sprite.stop()
	update_visual(moving)

func find_wall() -> int:
	var fortifications: Array[ConstructionSite] = construction.defensive_sites()
	for index: int in range(fortifications.size()):
		var site: ConstructionSite = fortifications[index]
		if site.data.blocks_enemies and site.hp > 0 and absf(position.x - site.x) < data.wall_range:
			return index
	return -1

func choose_special_target(_delta: float) -> bool:
	return false

func land_hit() -> void:
	if target_kind == "player":
		if absf(player.position.x - position.x) < data.player_hit_range:
			player.take_damage(damage)
	elif target_kind == "wall":
		construction.damage_site(target_index, damage)
	elif target_kind == "core":
		core.take_damage(damage)
	elif target_kind == "ally" and is_instance_valid(ally_target) and absf(ally_target.position.x - position.x) < 38:
		ally_target.take_damage(damage)
