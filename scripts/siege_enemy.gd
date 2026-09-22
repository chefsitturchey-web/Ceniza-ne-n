extends Node2D
## Enemigo de asedio: avance, aviso de ataque, golpe y recuperación.
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

func _ready() -> void:
	add_to_group("enemies")
	if runner:
		max_health = 60
		health = 60
		speed = 56.0
		damage = 8
	max_health += (world.day - 1) * 20
	health = max_health

func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-12, -30), Vector2(24, 30))

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	flash = 0.12
	if health == 0:
		remove_from_group("enemies")
		world.scrap += 3
		queue_free()

func _physics_process(delta: float) -> void:
	if health <= 0 or world.finished:
		return
	flash = maxf(0.0, flash - delta)
	cooldown = maxf(0.0, cooldown - delta)
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			land_hit()
			cooldown = 1.1
		queue_redraw()
		return
	var player = world.player
	if player.health > 0 and absf(player.position.x - position.x) < 30.0:
		target_kind = "player"
	elif find_wall() >= 0:
		target_kind = "wall"
		target_index = find_wall()
	elif absf(position.x) < 35.0:
		target_kind = "core"
	else:
		target_kind = ""
		position.x = move_toward(position.x, 0.0, speed * delta)
	if target_kind != "" and cooldown == 0.0:
		windup = 0.5
	queue_redraw()

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
	var color := Color("dd6482") if not runner else Color("e89e54")
	if flash > 0.0:
		color = Color.WHITE
	var height: float = 30.0 if not runner else 22.0
	draw_rect(Rect2(-10, -height, 20, height), color)
	draw_rect(Rect2(-7, -height + 5, 14, 6), Color("271d33"))
	draw_rect(Rect2(-12, -height - 7, 24.0 * health / max_health, 3), color)
	if windup > 0.0:
		draw_line(Vector2(0, -height - 13), Vector2(0, -height - 22), Color("ffce75"), 3.0)
