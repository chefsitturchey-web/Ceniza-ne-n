extends CanvasLayer

signal resolved(victory: bool)
signal continued
var completed: bool = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if completed:
		if event.keycode == KEY_R:
			continued.emit()
	elif event.keycode == KEY_1:
		resolved.emit(true)
	elif event.keycode == KEY_2:
		resolved.emit(false)
	get_viewport().set_input_as_handled()

func show_completed() -> void:
	completed = true
	$Screen/Title.text = "DISTRITO 1 COMPLETADO"
	$Screen/Choices.text = "[R] Continuar"
