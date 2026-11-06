class_name MenuFx
extends RefCounted
## Movimiento comun de menus: botones con vida y paneles que entran con curva.
## Respeta "reducir destellos": sin rebotes ni parpadeos, solo fundidos breves.

static func reduced() -> bool:
	return GamePreferences.current().reduced_flashes

static func _play(node: CanvasItem, key: StringName) -> Tween:
	if node.has_meta(key):
		var old: Variant = node.get_meta(key)
		if old is Tween and old.is_valid():
			old.kill()
	var tween: Tween = node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	node.set_meta(key, tween)
	return tween

## Hover/foco: crece un poco; pulsar lo aplasta. El brillo naranja lo da theme.tres.
static func juice_button(button: BaseButton) -> void:
	if button == null or button.has_meta(&"juiced"):
		return
	button.set_meta(&"juiced", true)
	button.offset_transform_enabled = true
	button.offset_transform_pivot_ratio = Vector2(0.0, 0.5)
	var raise: Callable = func() -> void:
		if button.disabled:
			return
		button.offset_transform_pivot_ratio = Vector2(0.0, 0.5)
		var target: Vector2 = Vector2.ONE if reduced() else Vector2(1.04, 1.04)
		_play(button, &"fx_scale").tween_property(button, "offset_transform_scale", target, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lower: Callable = func() -> void:
		_play(button, &"fx_scale").tween_property(button, "offset_transform_scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	button.mouse_entered.connect(raise)
	button.focus_entered.connect(raise)
	button.mouse_exited.connect(func() -> void:
		if not button.has_focus():
			lower.call())
	button.focus_exited.connect(lower)
	button.button_down.connect(func() -> void:
		if reduced():
			return
		button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
		var tween: Tween = _play(button, &"fx_scale")
		tween.tween_property(button, "offset_transform_scale", Vector2(0.96, 0.88), 0.05).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "offset_transform_scale", Vector2(1.04, 1.04), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))

## Aplica juice_button a todos los botones bajo un nodo.
static func juice_tree(root: Node) -> void:
	for child: Node in root.get_children():
		if child is Button or child is OptionButton:
			juice_button(child)
		juice_tree(child)

## Entrada con fundido y ligero ascenso visual (no toca el layout ni la posicion real).
static func enter(target: CanvasItem, rise: float = 18.0) -> void:
	if target == null:
		return
	var duration: float = 0.12 if reduced() else 0.28
	target.modulate.a = 0.0
	var tween: Tween = _play(target, &"fx_enter")
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if target is Control and not reduced() and rise != 0.0:
		var control: Control = target
		control.offset_transform_enabled = true
		control.offset_transform_position = Vector2(0, rise)
		tween.tween_property(control, "offset_transform_position", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Entrada escalonada desde la izquierda para listas de elementos (menu principal).
static func slide_in(target: Control, delay: float, from_x: float = -28.0) -> void:
	target.modulate.a = 0.0
	target.offset_transform_enabled = true
	if reduced():
		_play(target, &"fx_enter").tween_property(target, "modulate:a", 1.0, 0.15).set_delay(delay * 0.3)
		return
	target.offset_transform_position = Vector2(from_x, 0)
	var tween: Tween = _play(target, &"fx_enter")
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, 0.3).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "offset_transform_position", Vector2.ZERO, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Capa de panel (CanvasLayer con velo + PanelContainer): cada vez que se muestra, entra animada.
static func polish_layer(layer: CanvasLayer) -> void:
	layer.visibility_changed.connect(func() -> void:
		if not layer.visible:
			return
		juice_tree(layer)
		for child: Node in layer.get_children():
			if child is MenuBackdrop:
				enter(child, 0.0)
			elif child is Control:
				enter(child))

## Control que alterna `visible` (panel de pausa): al mostrarse entra deslizandose.
static func polish_control(control: Control, rise: float = 22.0) -> void:
	control.visibility_changed.connect(func() -> void:
		if control.is_visible_in_tree():
			juice_tree(control)
			enter(control, rise))
