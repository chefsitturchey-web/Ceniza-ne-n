class_name EnemyRepeater
extends Node2D

signal destroyed
signal defense_requested(portal: EnemyRepeater)
var defense_warning: float = 0
var defense_pending: int = 0
const TEXTURE: Texture2D = preload("res://assets/expedition/repeater.png")
var health: HealthComponent = HealthComponent.new()
var effects: StructureEffects = StructureEffects.new()
var hurtbox: HurtboxComponent = HurtboxComponent.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group(GameRules.REPEATERS)
	health.maximum = 300
	health.reset()
	add_child(health)
	hurtbox.name = "Hurtbox"
	hurtbox.actor = self
	hurtbox.bounds = Rect2(-16, -78, 32, 78)
	add_child(hurtbox)
	hurtbox.hit.connect(receive_assault)
	add_child(effects)
	effects.setup(health, TEXTURE)
	health.died.connect(_destroyed)

func _destroyed() -> void:
	defense_warning = 0
	defense_pending = 0
	remove_from_group(GameRules.REPEATERS)
	effects.shatter()
	destroyed.emit()

func restore(broken: bool) -> void:
	defense_warning = 0
	defense_pending = 0
	health.reset(0 if broken else 300)
	if broken:
		remove_from_group(GameRules.REPEATERS)
	else:
		add_to_group(GameRules.REPEATERS)
	queue_redraw()

func receive_assault(amount: int) -> void:
	if health.current <= 0 or amount <= 0: return
	var before: int = health.current
	health.take_damage(amount)
	if health.current <= 0: return
	# Tres refuerzos por portal. Se derivan del daño: retirarse no reinicia la reserva.
	for threshold: int in [300, 200, 100]:
		if before >= threshold and health.current < threshold:
			defense_pending += 1
			defense_warning = 0.8

func _process(delta: float) -> void:
	if defense_warning > 0:
		defense_warning = maxf(0, defense_warning - delta)
		if defense_warning == 0 and health.current > 0:
			for index: int in range(defense_pending): defense_requested.emit(self)
			defense_pending = 0
	queue_redraw()

func _draw() -> void:
	if health.current <= 0:
		draw_texture_rect_region(TEXTURE, Rect2(-16, -8, 32, 8), Rect2(0, 70, 32, 8), Color("8299a8"))
		draw_rect(Rect2(-7, -9, 10, 3), Color("304356"))
		return
	var offset: Vector2 = Vector2(1 if int(effects.elapsed * 40) % 2 == 0 else -1, 0) if effects.shake > 0 else Vector2.ZERO
	draw_set_transform(offset)
	draw_texture(TEXTURE, Vector2(-16, -78))
	var pink: Color = Color("ff66bb") if fmod(effects.elapsed, 1.0) < 0.6 else Color("713457")
	for point: Vector2 in [Vector2(-1, -77), Vector2(-14, -55), Vector2(11, -55)]:
		draw_rect(Rect2(point, Vector2(3, 2)), pink)
	draw_set_transform(Vector2.ZERO)
