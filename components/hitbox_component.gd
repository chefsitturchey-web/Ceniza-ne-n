class_name HitboxComponent
extends Node

signal hit(target: HurtboxComponent, amount: int)
var enabled: bool = true

func strike(rect: Rect2, amount: int) -> void:
	if not enabled: return
	for target: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES) + get_tree().get_nodes_in_group(GameRules.REPEATERS):
		var hurtbox: HurtboxComponent = target.get_node("Hurtbox") as HurtboxComponent
		if rect.intersects(hurtbox.world_rect()):
			hurtbox.receive(amount)
			hit.emit(hurtbox, amount)
