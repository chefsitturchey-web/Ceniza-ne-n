class_name Corpse
extends CubeBody

## Fallen ally remains. Decays over days; from stage 2 it spreads poison
## and can request a rat spawn through CorpseSystem.

var kind: StringName = &"ally"
var died_day: int = 0
var stage: int = 0
var buried: bool = false
var cycle: CycleSystem
## Set when the player reports the corpse; a builder is then dispatched.
var reported: bool = false
var bury_progress: float = 0.0
## Accumulated cooldown (seconds) between rat_spawn_requested emissions.
## Managed by CorpseSystem; a single float, not a Timer node.
var rat_timer: float = 0.0

func _draw() -> void:
	var frames: SpriteFrames = UnitSpriteLibrary.frames("builder" if kind == &"worker" else "ranger")
	var texture: Texture2D = frames.get_frame_texture(&"caer", frames.get_frame_count(&"caer") - 1)
	draw_texture(texture, Vector2(-32, -56), Color.WHITE.lerp(Color("517354"), stage / 4.0))
	if stage >= 2:
		for index: int in 4:
			draw_circle(Vector2(-12 + index * 8, -5 - index % 2 * 3), 2, Color(0.3, 0.6, 0.34, 0.25))

func _ready() -> void:
	size = Vector2(16, 10)

func refresh_stage(current_day: int) -> void:
	stage = clampi(current_day - died_day, 0, 3)
	match stage:
		0:
			fill = Color(0.51, 0.6, 0.66)
		1:
			fill = Color(0.35, 0.48, 0.35)
		2:
			fill = Color(0.29, 0.42, 0.29)
		_:
			fill = Color(0.18, 0.29, 0.18)

func aura_radius() -> float:
	if stage < 2:
		return 0.0
	return 36.0 if stage == 2 else 56.0

func poison_dps() -> float:
	if stage < 2:
		return 0.0
	return 2.0 if stage == 2 else 4.0

func bury() -> void:
	if buried:
		return
	buried = true
	queue_free()
