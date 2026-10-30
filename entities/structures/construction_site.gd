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
var core: ColonyCore

func visual_height() -> float:
	return FortressArt.WALL_HEIGHTS[tier - 1] if data.blocks_enemies else FortressArt.TURRET_HEIGHTS[tier - 1] + 18

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
	var repairing: bool = not upgrade_pending and health_component.current > 0
	if upgrade_pending:
		tier = mini(3, tier + 1)
		health_component.maximum = data.health * tier
		upgrade_pending = false
	effects.repair_sparks()
	health_component.reset()
	ordered = false
	progress = 0.0
	if core != null and core.district != null:
		core.district.play("repair" if repairing else "build_done")

func _on_destroyed() -> void:
	upgrade_pending = false
	if turret_visual != null:
		turret_visual.clear_target()
	if core != null and core.district != null:
		core.district.sound.play_world("wall_destroy", global_position)
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
	var art: Texture2D = FortressArt.texture("wall" if data.blocks_enemies else "turret_base", tier)
	var source: Rect2 = ArtScale.source(art)
	var height: float = FortressArt.WALL_HEIGHTS[tier - 1] if data.blocks_enemies else FortressArt.TURRET_HEIGHTS[tier - 1]
	var frame: Rect2 = ArtScale.grounded(source, height)
	var size: Vector2 = frame.size
	var fraction: float = clampf(progress / GameRules.BUILD_TIME, 0, 1)
	var built: float = floorf(size.y * fraction)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if x < 0.0 else 1.0, 1.0))
	draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y - built), Color("b075ae", 0.4), false, 1.0)
	if built > 0:
		draw_texture_rect_region(art, Rect2(-size.x / 2, -built, size.x, built), Rect2(source.position + Vector2(0, source.size.y * (1 - fraction)), Vector2(source.size.x, source.size.y * fraction)))
	var amber: Color = Color("ffce75")
	amber.a = 1.0 if int(effects.elapsed * 12) % 2 == 0 else 0.45
	draw_line(Vector2(-size.x / 2.0, -built), Vector2(size.x / 2.0, -built), amber)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var can_upgrade: bool = tier < (core.tier if core != null else 3)
	if is_instance_valid(viewer) and absf(viewer.position.x - x) < 85 and not ordered and (hp < max_hp or can_upgrade):
		var price: int = cost if hp == 0 else (25 * tier if hp == max_hp else data.repair_cost)
		var pips: int = ceili(price / 5.0)
		for index: int in range(pips):
			draw_circle(Vector2((index % 5 - 2) * 7, -visual_height() - 10 - (index / 5) * 6), 2, Color("ffce75") if index < int(payment_fraction * pips) else Color("8299a8"))
	if ordered and hp == 0:
		_draw_construction()
	elif hp > 0:
		if turret_visual == null:
			var art: Texture2D = FortressArt.texture("wall", tier)
			var source: Rect2 = ArtScale.source(art)
			draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if x < 0 else 1, 1))
			ArtScale.footing(self, ArtScale.grounded(source, FortressArt.WALL_HEIGHTS[tier - 1]))
			draw_texture_rect_region(art, ArtScale.grounded(source, FortressArt.WALL_HEIGHTS[tier - 1]), source, Color(0.8, 1.2, 1.15) if boosted else Color.WHITE)
			draw_set_transform(Vector2.ZERO)
		if upgrade_pending:
			for side: int in [-1, 1]: draw_line(Vector2(side * 20, 0), Vector2(side * 20, -visual_height() - 5), Color("8299a8"), 1)
	else:
		draw_rect(Rect2(-14, -4, 28, 4), Color("304356"))
		for side: int in [-1, 1]: draw_rect(Rect2(side * 12 - 1, -7, 3, 7), Color("8299a8"))
