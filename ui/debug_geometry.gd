class_name GameDebugGeometry
extends Control
var tools: Node

func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	visible = tools.draw_debug and not tools.opened
	if visible: queue_redraw()

func _draw() -> void:
	var arena: RecaudadorArena = tools.active_arena()
	if arena != null:
		var transform: Transform2D = arena.world.get_canvas_transform()
		var edge: PackedVector2Array = []
		for point: Vector2 in ArenaLayout.boundary(arena.zone_index): edge.append(transform * point)
		edge.append(edge[0])
		draw_polyline(edge, Color("47dacb"), 1)
		for parent: Node in [arena.world, arena.actors]:
			for child: Node in parent.get_children():
				if not child is StaticBody2D: continue
				var collision: CollisionShape2D = child.get_child(0) as CollisionShape2D
				if collision == null or not collision.shape is RectangleShape2D: continue
				var half: Vector2 = collision.shape.size / 2
				var outline: PackedVector2Array = []
				for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y), Vector2(-half.x, -half.y)]: outline.append(transform * child.global_transform * corner)
				draw_polyline(outline, Color("ffce75", 0.7), 1)
		draw_arc(transform * arena.boss.position, 29 * transform.get_scale().x, 0, TAU, 32, Color("dd6482"), 1)
		draw_arc(transform * arena.player.position, 8 * transform.get_scale().x, 0, TAU, 24, Color("47dacb"), 1)
		var path: PackedVector2Array = []
		for point: Vector2 in arena.boss.tactics.route: path.append(transform * point)
		if path.size() > 1: draw_polyline(path, Color("47dacb"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(8, 65), "IA: %s · Estado: %s · %.2fs · HP %d/%d" % [arena.boss.last_decision, Recaudador.State.keys()[arena.boss.state], arena.boss.timer, arena.boss.health, arena.boss.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	else:
		var district: District = tools.active_district()
		if district == null: return
		var transform: Transform2D = district.get_canvas_transform()
		for site: ConstructionSite in district.construction.sites + district.civic.walls:
			var point: Vector2 = transform * site.position
			draw_line(point, point + Vector2(0, -60), Color("ffce75"), 1)
			draw_string(ThemeDB.fallback_font, point + Vector2(-10, -65), "Nv.%d HP %d" % [site.tier, site.hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
