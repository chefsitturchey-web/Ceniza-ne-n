class_name ScreenFade
extends CanvasLayer
## Transicion entre escenas por disolvencia de bloques. Vive en la raiz y sobrevive al cambio de escena.
const SHADER: Shader = preload("res://ui/shaders/screen_dissolve.gdshader")
const NAME: String = "ScreenFade"
var rect: ColorRect = ColorRect.new()
var material_ref: ShaderMaterial = ShaderMaterial.new()
var tween: Tween
var busy: bool = false

static func instance(tree: SceneTree) -> ScreenFade:
	var found: Node = tree.root.get_node_or_null(NAME)
	if found is ScreenFade:
		return found
	var fade: ScreenFade = ScreenFade.new()
	fade.name = NAME
	tree.root.add_child(fade)
	return fade

## Sin animacion en pruebas sin pantalla.
static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"

## Con "reducir destellos" la disolvencia se vuelve un fundido corto.
static func duration() -> float:
	return 0.18 if GamePreferences.current().reduced_flashes else 0.4

## Cubre la pantalla, cambia de escena y la descubre cuando la nueva esta lista.
static func change_scene(tree: SceneTree, path: String) -> void:
	if not enabled():
		tree.change_scene_to_file(path)
		return
	var fade: ScreenFade = instance(tree)
	if fade.busy:
		return
	fade.busy = true
	await fade.cover()
	tree.change_scene_to_file(path)
	await tree.process_frame
	await tree.process_frame
	await fade.reveal()
	fade.busy = false

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_ref.shader = SHADER
	material_ref.set_shader_parameter("progress", 0.0)
	rect.material = material_ref
	rect.visible = false
	add_child(rect)

func set_progress(value: float) -> void:
	material_ref.set_shader_parameter("progress", value)
	rect.visible = value > 0.0

func _run(from: float, to: float) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tween.tween_method(set_progress, from, to, duration()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func cover() -> void:
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _run(0.0, 1.0)

func reveal() -> void:
	await _run(1.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
