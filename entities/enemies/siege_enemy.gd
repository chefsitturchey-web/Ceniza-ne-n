class_name SiegeEnemy
extends Node2D
## Las animaciones no determinan el instante del daño.
@export var sprite_faces_right: bool = true
enum State { APPROACH, WINDUP, ATTACK, DEAD }
const DEATH_VISUAL_GRACE: float = 0.1
signal state_changed(state: State)
signal reward_requested(amount: int)
@export var data: EnemyData
var player: Player
var construction: ConstructionSystem
var core: ColonyCore
var session: SessionController
var night: int = 1
var state: State = State.APPROACH
var health_component: HealthComponent = HealthComponent.new()
var hurtbox: HurtboxComponent = HurtboxComponent.new()
var visual: EnemyVisual = EnemyVisual.new()
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
var flash: float = 0.0
var hurt_remaining: float = 0.0
var death_remaining: float = 0.0
var attack_visual_remaining: float = 0.0
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	if data == null:
		data = EnemyData.new()
	add_child(health_component)
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	hurtbox.hit.connect(take_damage)
	add_child(hurtbox)
	visual.actor = self
	add_child(visual)
	visual.bind(sprite)
	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)
		visual.play_visual(&"reposo")
	if session == null:
		return # F6 permite previsualizar sin una partida activa.
	add_to_group(GameRules.ENEMIES)
	max_health = data.health + (night - 1) * data.health_per_night
	health_component.maximum = max_health
	health_component.reset()
	speed = data.speed
	damage = data.damage
	face_toward(0.0)

func set_state(value: State) -> void:
	if state != value:
		state = value
		state_changed.emit(state)

func face_toward(x: float) -> void:
	if sprite != null and not is_equal_approx(position.x, x):
		sprite.flip_h = (x < position.x) if sprite_faces_right else (x > position.x)

func update_visual(moving: bool = false) -> void:
	visual.update_state(moving)

func get_hurt_rect() -> Rect2:
	return hurtbox.world_rect()

func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health_component.take_damage(amount)
	flash = data.flash_duration
	hurt_remaining = data.hurt_duration
	if health == 0:
		set_state(State.DEAD)
		remove_from_group(GameRules.ENEMIES)
		reward_requested.emit(data.reward)
		windup = 0.0
		if sprite != null and visual.animation_duration(&"destruccion") > 0.0:
			sprite.modulate = Color.WHITE
			visual.play_visual(&"destruccion")
			death_remaining = visual.animation_duration(&"destruccion") + DEATH_VISUAL_GRACE
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
	if player.health > 0 and absf(player.position.x - position.x) < data.player_notice_range:
		target_kind = "player"
		face_toward(player.position.x)
	elif find_wall() >= 0:
		target_kind = "wall"
		target_index = find_wall()
		face_toward(construction.sites[target_index].x)
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
	for index: int in range(construction.sites.size()):
		var site: ConstructionSite = construction.sites[index]
		if site.data.blocks_enemies and site.hp > 0 and absf(position.x - site.x) < data.wall_range:
			return index
	return -1

func land_hit() -> void:
	if target_kind == "player":
		if absf(player.position.x - position.x) < data.player_hit_range:
			player.take_damage(damage)
	elif target_kind == "wall":
		construction.damage_site(target_index, damage)
	elif target_kind == "core":
		core.take_damage(damage)
