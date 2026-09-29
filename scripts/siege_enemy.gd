extends Node2D
## Lógica de asedio compartida; el errante utiliza una escena animada.
@export var sprite_faces_right: bool = true
var world: Node2D
var runner: bool = false
var health: int = 100
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
	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)
		play_visual(&"reposo")
	if world == null:
		return # F6 permite previsualizar la escena sin una partida activa.
	add_to_group("enemies")
	if runner:
		max_health = 60
		speed = 56.0
		damage = 8
	max_health += (world.day - 1) * 20
	health = max_health
	face_toward(0.0)

func animation_duration(animation_name: StringName) -> float:
	if sprite == null or not sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frames: SpriteFrames = sprite.sprite_frames
	var duration: float = 0.0
	for index in range(frames.get_frame_count(animation_name)):
		duration += frames.get_frame_duration(animation_name, index)
	return duration / maxf(0.01, frames.get_animation_speed(animation_name))

func play_visual(animation_name: StringName, duration: float = 0.0) -> void:
	if sprite == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation == animation_name and sprite.is_playing():
		return
	sprite.speed_scale = animation_duration(animation_name) / duration if duration > 0.0 else 1.0
	sprite.play(animation_name)

func face_toward(x: float) -> void:
	if sprite != null and not is_equal_approx(position.x, x):
		sprite.flip_h = (x < position.x) if sprite_faces_right else (x > position.x)

func update_visual(moving: bool = false) -> void:
	if sprite != null:
		sprite.modulate = Color(1.6, 1.3, 1.3) if flash > 0.0 else Color.WHITE
	if windup > 0.0:
		play_visual(&"ataque", 1.6)
	elif hurt_remaining > 0.0:
		play_visual(&"daño", 0.32)
	elif moving:
		attack_visual_remaining = 0.0
		if runner and sprite != null and sprite.sprite_frames.has_animation(&"correr"):
			play_visual(&"correr")
		else:
			play_visual(&"caminar")
	elif attack_visual_remaining > 0.0:
		# Si recibió daño, deja terminar la reacción en vez de reiniciar el golpe.
		if sprite != null and sprite.animation != &"ataque":
			play_visual(&"reposo")
	else:
		play_visual(&"reposo")
	queue_redraw()

func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-12, -30), Vector2(24, 30))

func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	flash = 0.12
	hurt_remaining = 0.32
	if health == 0:
		remove_from_group("enemies")
		world.scrap += 3
		windup = 0.0
		if sprite != null and animation_duration(&"destruccion") > 0.0:
			sprite.modulate = Color.WHITE
			play_visual(&"destruccion")
			death_remaining = animation_duration(&"destruccion") + 0.1
		else:
			queue_free()
		queue_redraw()
		return
	update_visual()

func _on_animation_finished() -> void:
	if health <= 0 and sprite.animation == &"destruccion":
		queue_free()

func _physics_process(delta: float) -> void:
	if world == null:
		return
	if health <= 0:
		death_remaining -= delta
		if death_remaining <= 0.0:
			queue_free()
		return
	if world.finished:
		if sprite != null:
			sprite.pause()
		return
	flash = maxf(0.0, flash - delta)
	hurt_remaining = maxf(0.0, hurt_remaining - delta)
	attack_visual_remaining = maxf(0.0, attack_visual_remaining - delta)
	cooldown = maxf(0.0, cooldown - delta)
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			land_hit()
			cooldown = 1.1
		update_visual()
		return
	var player = world.player
	var moving: bool = false
	if player.health > 0 and absf(player.position.x - position.x) < 30.0:
		target_kind = "player"
		face_toward(player.position.x)
	elif find_wall() >= 0:
		target_kind = "wall"
		target_index = find_wall()
		face_toward(world.sites[target_index].x)
	elif absf(position.x) < 35.0:
		target_kind = "core"
		face_toward(0.0)
	else:
		target_kind = ""
		face_toward(0.0)
		position.x = move_toward(position.x, 0.0, speed * delta)
		moving = true
	if target_kind != "" and cooldown == 0.0:
		windup = 0.5
		attack_visual_remaining = 1.6
		# Reinicia el ciclo solo al iniciar un ataque real, no cada fotograma.
		if sprite != null:
			sprite.stop()
	update_visual(moving)

func find_wall() -> int:
	for index in range(world.sites.size()):
		var site: Dictionary = world.sites[index]
		if site.kind == "wall" and site.hp > 0 and absf(position.x - site.x) < 24.0:
			return index
	return -1

func land_hit() -> void:
	if target_kind == "player":
		if absf(world.player.position.x - position.x) < 38.0:
			world.player.take_damage(damage)
	elif target_kind == "wall":
		world.damage_site(target_index, damage)
	elif target_kind == "core":
		world.core_health = maxi(0, world.core_health - damage)

func _draw() -> void:
	if health <= 0:
		return
	var color := Color("dd6482") if not runner else Color("e89e54")
	if flash > 0.0:
		color = Color.WHITE
	var height: float = 30.0 if not runner else 22.0
	if sprite == null:
		draw_rect(Rect2(-10, -height, 20, height), color)
		draw_rect(Rect2(-7, -height + 5, 14, 6), Color("271d33"))
	draw_rect(Rect2(-12, -height - 7, 24.0 * health / max_health, 3), color)
	if windup > 0.0:
		draw_line(Vector2(0, -height - 13), Vector2(0, -height - 22), Color("ffce75"), 3.0)
