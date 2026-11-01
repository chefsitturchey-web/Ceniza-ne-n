class_name ScreenFit
extends RefCounted
## Pantallas anchas: el proyecto usa stretch "keep_height", así que el alto lógico siempre es 360
## y en un móvil 20:9 el ancho crece (unos 800 px). Las capas con diseño fijo de 640 px se centran
## y sus fondos se estiran a todo el ancho. En móvil también se respetan los recortes (notch).

const BASE: Vector2 = Vector2(640, 360)

## Tamaño visible del viewport raíz en coordenadas lógicas.
static func visible_size(node: Node = null) -> Vector2:
	var viewport: Viewport = node.get_viewport() if node != null and node.is_inside_tree() else null
	if viewport == null:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		viewport = tree.root if tree != null else null
	return viewport.get_visible_rect().size if viewport != null else BASE

## Ancho sobrante respecto al diseño de 640 px; nunca negativo.
static func extra_width(node: Node = null) -> float:
	return maxf(0.0, visible_size(node).x - BASE.x)

## Desplazamiento que centra un diseño de 640 px en un ancho visible dado.
static func layer_shift(width: float) -> float:
	return roundf(maxf(0.0, width - BASE.x) / 2.0)

## Márgenes seguros (notch, esquinas redondeadas) en píxeles lógicos. Solo en móvil:
## en escritorio el área segura es la utilizable del monitor y no afecta a la ventana.
static func safe_margins(node: Node = null) -> Dictionary:
	var margins: Dictionary = {"left": 0.0, "right": 0.0, "top": 0.0, "bottom": 0.0}
	if not OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		return margins
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window: Vector2i = DisplayServer.window_get_size()
	if safe.size.x <= 0 or window.x <= 0 or window.y <= 0:
		return margins
	var scale: float = visible_size(node).y / float(window.y)
	margins.left = maxf(0.0, safe.position.x) * scale
	margins.top = maxf(0.0, safe.position.y) * scale
	margins.right = maxf(0.0, window.x - safe.end.x) * scale
	margins.bottom = maxf(0.0, window.y - safe.end.y) * scale
	return margins

## Centra una capa de diseño fijo y estira sus fondos a todo el ancho visible.
## Un nodo vigía hijo de la capa sigue los cambios de tamaño y se desconecta al liberarse con ella.
static func fit_layer(layer: CanvasLayer, backdrops: Array = []) -> void:
	var watcher: LayerWatcher = LayerWatcher.new()
	watcher.name = "ScreenFit"
	watcher.layer = layer
	watcher.backdrops = backdrops
	layer.add_child(watcher)
	if layer.is_inside_tree():
		watcher.apply()

class LayerWatcher extends Node:
	var layer: CanvasLayer
	var backdrops: Array = []

	func _ready() -> void:
		get_viewport().size_changed.connect(apply)
		apply()

	func apply() -> void:
		if layer == null or not layer.is_inside_tree():
			return
		var area: Vector2 = ScreenFit.visible_size(layer)
		var shift: float = ScreenFit.layer_shift(area.x)
		layer.offset.x = shift
		for backdrop: Variant in backdrops:
			if backdrop is Control and is_instance_valid(backdrop):
				var control: Control = backdrop as Control
				control.position.x = -shift
				control.size = Vector2(maxf(ScreenFit.BASE.x, area.x), control.size.y)
