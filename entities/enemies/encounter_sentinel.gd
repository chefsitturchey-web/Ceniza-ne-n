class_name EncounterSentinel
extends CharacterBody2D
## Dron de escolta: se abre, fija la puntería y dispara; nunca daña por contacto.
var encounter: RecaudadorArena
var tactics: BossTactics = BossTactics.new()
var health: int = 120
var age: float = 0
var cooldown: float = 1.7
var windup: float = 0
var aim: Vector2 = Vector2.DOWN
var shot_origin: Vector2
var side: int = 1
var muzzle_time: float = 0
var rotor: float = 0
var role: String = "gunner"
var relay_target: NetworkRelay

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 11
	collider.shape = shape
	add_child(collider)

func _physics_process(delta: float) -> void:
	if encounter.ending or encounter.boss.health <= 0 or encounter.player.health <= 0: return
	age += delta
	rotor += delta * 12
	muzzle_time = maxf(0, muzzle_time - delta)
	tactics.observe(encounter.player, delta)
	if windup > 0:
		windup -= delta
		velocity = Vector2.ZERO
		if windup <= 0:
			if role == "saboteur" and is_instance_valid(relay_target):
				var mother: MadreCero = encounter.boss as MadreCero
				if global_position.distance_to(relay_target.global_position) < 75 and mother.guard_time <= 0:
					relay_target.health = maxi(0, relay_target.health - 9)
			elif role == "hunter":
				var difference: Vector2 = encounter.player.global_position - global_position
				if difference.length() < 75 and aim.dot(difference.normalized()) > 0.5:
					encounter.player.take_damage(12, aim * 90)
			else: encounter.spawn_bullet(global_position + aim * 15, aim)
			muzzle_time = 0.12
			cooldown = 3.8
	else:
		cooldown -= delta
		var offset: Vector2 = global_position - encounter.player.global_position
		var destination: Vector2 = encounter.player.global_position + offset.normalized() * 145 + offset.normalized().orthogonal() * side * 65
		if role == "hunter": destination = encounter.player.global_position + offset.normalized() * 48
		if role == "saboteur":
			var distance: float = INF
			relay_target = null
			for relay: NetworkRelay in (encounter.boss as MadreCero).relays:
				if relay.health > 0 and global_position.distance_to(relay.global_position) < distance:
					relay_target = relay
					distance = global_position.distance_to(relay.global_position)
			if relay_target != null: destination = relay_target.global_position
		velocity = tactics.steer(self, destination, 58)
		move_and_slide()
		var goal: Vector2 = relay_target.global_position if role == "saboteur" and is_instance_valid(relay_target) else encounter.player.global_position
		var in_range: bool = role == "gunner" or global_position.distance_to(goal) < 70
		if cooldown <= 0 and in_range and tactics.clear_shot(self, goal):
			aim = ((tactics.predicted(encounter.player, 0.2) if role == "gunner" else goal) - global_position).normalized()
			windup = 0.95
			shot_origin = global_position
			encounter.sound.play_cue("alarm", -18)
	# Escoltas tienen una vida limitada; no se acumulan en combate indefinidamente.
	if age > 32: queue_free()
	queue_redraw()

func receive_hit(_origin: Vector2, amount: int) -> int:
	if health <= 0: return 0
	var damage: int = mini(health, maxi(0, amount))
	health -= damage
	encounter.boss.effects.emit_pixels(global_position, 5, Color("ffce75"))
	if health <= 0:
		encounter.player.stamina = minf(100, encounter.player.stamina + 8)
		encounter.boss.effects.emit_pixels(global_position, 10, Color("8299a8"), true)
		queue_free()
	return damage

func _draw() -> void:
	if health <= 0: return
	if windup > 0:
		if role == "gunner": draw_line(aim * 16, aim * 280, Color("ffce75", 0.45), 1)
		else: draw_arc(Vector2.ZERO, 75, aim.angle() - 1, aim.angle() + 1, 24, Color("ffce75"), 2)
	draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 18, Color("050c13", 0.6))
	draw_set_transform(Vector2(0, -4 + sin(age * 4) * 1.5))
	var tint: Color = Color("bd9ba0") if role == "gunner" else (Color("a0c8c5") if role == "saboteur" else Color("d2ac83"))
	draw_texture_rect(DepotArt.part(0), Rect2(-12, -13, 24, 26), false, tint)
	for direction: int in [-1, 1]:
		draw_line(Vector2(direction * 8, 0), Vector2(direction * 18, -2), Color("8299a8"), 2)
		draw_set_transform(Vector2(direction * 18, -6 + sin(age * 4) * 1.5), rotor * direction)
		draw_texture_rect(DepotArt.part(5), Rect2(-7, -7, 14, 14), false)
	draw_set_transform(Vector2(0, -4 + sin(age * 4) * 1.5), aim.angle() - PI / 2)
	draw_texture_rect(DepotArt.part(2), Rect2(-4, 3, 8, 18), false)
	if muzzle_time > 0: draw_circle(Vector2(0, 23), 5, Color("ffce75"))
	draw_circle(Vector2(0, -2), 2, Color("ffce75") if windup > 0 else Color("dd6482"))
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(-11, -26), Vector2(11, -26), Color("0b1322"), 3)
	draw_line(Vector2(-11, -26), Vector2(-11 + 22 * health / 120.0, -26), Color("dd6482"), 2)
