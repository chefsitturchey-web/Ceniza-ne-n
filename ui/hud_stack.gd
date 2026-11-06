class_name HudStack
extends Node
## Apila los textos de la esquina superior izquierda con su alto real, en este orden:
## cartel de la guía, objetivo, nivel y datos, plataforma, meta nocturna y veneno.
## Cada capa decide si se ve; aquí solo se reparte el espacio para que nada se monte.
const TOP: float = 10.0
const GAP: float = 3.0
var world: District
var hud: GameHud
var guide_hud: FirstStepsHud
## Borde inferior del último bloque colocado; las pruebas lo usan para medir el apilado.
var bottom: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Después de que cada capa haya decidido su visibilidad en este fotograma.
	process_priority = 100

func _process(_delta: float) -> void:
	layout()

func layout() -> void:
	var y: float = TOP
	var banner: bool = guide_hud != null and guide_hud.visible
	if banner: y = guide_hud.banner_bottom() + GAP
	# El cartel de la guía ya dice qué hacer: el objetivo general vuelve cuando se va.
	hud.objective.visible = not banner
	y = place(hud.objective, y)
	if shown(world.experience.status): y = world.experience.place(y) + GAP
	if world.mobility != null:
		world.mobility.status.position.x = world.experience.status.position.x
		y = place(world.mobility.status, y)
	y = place(world.rewards_hud.goal_label, y)
	y = place(hud.poison_label, y)
	bottom = y
	# El combo y los logros quedan debajo de toda la columna, incluso con plataforma.
	world.rewards_hud.combo_label.position.y = maxf(65, bottom)
	world.rewards_hud.toast.position.y = maxf(115, world.rewards_hud.combo_label.position.y + world.rewards_hud.combo_label.get_combined_minimum_size().y + GAP)
	# El botón del diario (arriba a la derecha) baja bajo el cartel cuando este se ve.
	if world.story != null and world.story.journal_button != null:
		var heading_bottom: float = guide_hud.banner_bottom() if banner else hud.objective.position.y + hud.objective.size.y
		world.story.journal_button.position.y = maxf(28.0, heading_bottom + GAP)

## Coloca la etiqueta en y si se ve y devuelve dónde empieza la siguiente.
func place(label: Label, y: float) -> float:
	if not shown(label): return y
	label.position.y = roundf(y)
	label.size.y = 0
	return roundf(y) + label.size.y + GAP

## Visible de verdad: el nodo, sus padres y su CanvasLayer, y con texto.
static func shown(item: CanvasItem) -> bool:
	if not item.is_visible_in_tree(): return false
	var node: Node = item.get_parent()
	while node != null:
		if node is CanvasLayer and not (node as CanvasLayer).visible: return false
		node = node.get_parent()
	return not (item is Label) or not (item as Label).text.is_empty()
