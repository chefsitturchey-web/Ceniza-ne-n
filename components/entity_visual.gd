class_name EntityVisual
extends Node2D

var sprite: AnimatedSprite2D

func bind(value: AnimatedSprite2D) -> void:
	sprite = value

func animation_duration(animation_name: StringName) -> float:
	if sprite == null or not sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frames: SpriteFrames = sprite.sprite_frames
	var duration: float = 0.0
	for index: int in range(frames.get_frame_count(animation_name)):
		duration += frames.get_frame_duration(animation_name, index)
	return duration / maxf(0.01, frames.get_animation_speed(animation_name))

func play_visual(animation_name: StringName, duration: float = 0.0) -> void:
	if sprite == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation == animation_name and sprite.is_playing():
		return
	sprite.speed_scale = animation_duration(animation_name) / duration if duration > 0.0 else 1.0
	sprite.play(animation_name)

func face(left: bool) -> void:
	if sprite != null:
		sprite.flip_h = left
