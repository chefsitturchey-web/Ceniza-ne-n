class_name GameHud
extends CanvasLayer

func display(text: String, hint: String, result: String) -> void:
	$Status.text = text
	$Hint.text = hint
	$Result.text = result
