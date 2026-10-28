class_name ConstructionSite
extends Node2D

## El estado del mundo se comunica con efectos, nunca con barras.
const WORLD_BARS_ENABLED: bool = false

signal destroyed
@export var data: StructureData
var health_component: HealthComponent = HealthComponent.new()
var effects: StructureEffects = StructureEffects.new()
var weld_timer: float = 0.0
var boosted: bool = false
var ordered: bool = false
var progress: float = 0.0
var shot: float = 0.0
var recoil: float = 0.0
var turret_visual: TurretVisual
var tier: int = 1
var upgrade_pending: bool = false
var viewer: Player
var payment_fraction: float = 0
var powered: bool = true

func muzzle_position() -> Vector2:
	if turret_visual != null:
		return turret_visual.muzzle_position()
	# Sprite 40x50: cañón a 9 px desde arriba, reflejado en el frente izquierdo.
	var extent: Vector2 = data.texture.get_size() if data.texture != null else Vector2(28, 50)
	return global_position + Vector2((extent.x / 2.0 - 2) * (-1.0 if x < 0 else 1.0), -extent.y + 9)

func fire_effects() -> void:
	recoil = 0.09
	if turret_visual != null:
		turret_visual.fire()
	var direction: float = turret_visual.facing if turret_visual != null else (-1.0 if x < 0 else 1.0)
	effects.emit_shot(muzzle_position(), direction)
	queue_redraw()
var x: float:
	get: return position.x
var kind: StringName:
	get: return data.id
var cost: int:
	get: return data.cost
var max_hp: int:
	get: return health_component.maximum
var hp: int:
	get: return health_component.current
	set(value): health_component.reset(value)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(health_component)
	health_component.maximum = data.health
	health_component.reset(0)
	health_component.died.connect(_on_destroyed)
	add_child(effects)
	effects.setup(health_component, data.texture, x < 0.0)
	if data.id == &"turret" and data.texture != null:
		turret_visual = TurretVisual.new()
		turret_visual.site = self
		add_child(turret_visual)

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func complete_work() -> void:
	if upgrade_pending:
		tier = mini(3, tier + 1)
		health_component.maximum = data.health * tier
		upgrade_pending = false
	effects.repair_sparks()
	health_component.reset()
	ordered = false
	progress = 0.0

func _on_destroyed() -> void:
	upgrade_pending = false
	if turret_visual != null:
		turret_visual.clear_target()
	effects.shatter()
	ordered = false
	progress = 0.0
	destroyed.emit()

func update_overload(left_active: bool, right_active: bool) -> void:
	boosted = left_active if x < 0.0 else right_active
	queue_redraw()

func _process(delta: float) -> void:
	modulate = Color.WHITE if powered else Color(0.5, 0.56, 0.63)
	recoil = maxf(0.0, recoil - delta)
	weld_timer -= delta
	if ordered and weld_timer <= 0.0:
		weld_timer = 0.18
		var height: float = data.texture.get_height() if data.texture != null else 40.0
		var origin: Vector2 = global_position + Vector2(effects.rng.randf_range(-8, 8), -height * clampf(progress / GameRules.BUILD_TIME, 0, 1))
		effects.emit_pixels(origin, 2, Color("75fff0") if hp > 0 else Color("ffce75"))
	queue_redraw()

func _draw_construction() -> void:
	var size: Vector2 = data.texture.get_size()
	var built: float = floorf(size.y * clampf(progress / GameRules.BUILD_TIME, 0, 1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if x < 0.0 else 1.0, 1.0))
	draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y - built), Color("b075ae", 0.4), false, 1.0)
	if built > 0:
		draw_texture_rect_region(data.texture, Rect2(-size.x / 2.0, -built, size.x, built), Rect2(0, size.y - built, size.x, built))
	var amber: Color = Color("ffce75")
	amber.a = 1.0 if int(effects.elapsed * 12) % 2 == 0 else 0.45
	draw_line(Vector2(-size.x / 2.0, -built), Vector2(size.x / 2.0, -built), amber)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if is_instance_valid(viewer) and absf(viewer.position.x - x) < 85 and not ordered and (hp < max_hp or (data.blocks_enemies and tier < 3)):
		var price: int = cost if hp == 0 else (25 * tier if hp == max_hp else data.repair_cost)
		var pips: int = ceili(price / 5.0)
		for index: int in range(pips):
			draw_circle(Vector2((index % 5 - 2) * 7, -55 - (index / 5) * 6), 2, Color("ffce75") if index < int(payment_fraction * pips) else Color("8299a8"))
	if data.blocks_enemies and hp > 0 and tier > 1:
		for side: int in [-1, 1]:
			draw_rect(Rect2(side * 14 - 3, -48 - tier * 4, 6, 48 + tier * 4), Color("304356"))
			draw_line(Vector2(side * 14, 0), Vector2(side * 14, -48 - tier * 4), Color("8299a8"), 1)
	var color: Color = Color("47dacb") if boosted else Color("8299a8")
	if ordered and hp == 0 and progress < GameRules.BUILD_TIME and data.texture != null:
		_draw_construction()
	elif hp > 0 and data.texture != null:
		if turret_visual != null:
			return
		var size: Vector2 = data.texture.get_size()
		# Los sprites miran a la derecha; en el frente izquierdo deben mirar hacia afuera.
		var kick: float = (1.0 if x < 0 else -1.0) if recoil > 0 else 0.0
		draw_set_transform(Vector2(kick, 0), 0.0, Vector2(-1.0 if x < 0.0 else 1.0, 1.0))
		draw_texture(data.texture, Vector2(-size.x / 2.0, -size.y), Color(0.75, 1.5, 1.45) if boosted else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
	elif hp > 0:
		if data.blocks_enemies:
			draw_rect(Rect2(-10, -45, 20, 45), color)
			draw_rect(Rect2(-5, -40, 10, 30), Color("304356"))
		else:
			draw_rect(Rect2(-5, -35, 10, 35), color)
			draw_rect(Rect2(-14, -45, 28, 12), color)
	else:
		draw_rect(Rect2(-14, -4, 28, 4), Color("304356"))
		for side: int in [-1, 1]:
			draw_rect(Rect2(side * 12 - 1, -9, 3, 9), Color("8299a8"))
			draw_rect(Rect2(side * 12 - 1, -9, 3, 2), Color("47dacb"))
