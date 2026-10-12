class_name HurtboxComponent
extends Node

signal hit(amount: int)
@export var bounds: Rect2 = Rect2(-12, -30, 24, 30)
var actor: Node2D

func world_rect() -> Rect2:
	return Rect2(actor.global_position + bounds.position, bounds.size)

func receive(amount: int) -> void:
	hit.emit(amount)
