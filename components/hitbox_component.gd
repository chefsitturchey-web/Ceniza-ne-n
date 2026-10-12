class_name HitboxComponent
extends Node

signal hit(target: HurtboxComponent, amount: int)

func strike(rect: Rect2, amount: int) -> void:
	for target: Node in get_tree().get_nodes_in_group(GameRules.ENEMIES) + get_tree().get_nodes_in_group(GameRules.REPEATERS):
		var hurtbox: HurtboxComponent = target.get_node("Hurtbox") as HurtboxComponent
		if rect.intersects(hurtbox.world_rect()):
			hurtbox.receive(amount)
			hit.emit(hurtbox, amount)
