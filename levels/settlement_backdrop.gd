class_name SettlementBackdrop
extends Node2D

var world: District
var elapsed: float = 0
var clock: float = 0
var art: Texture2D = load("res://assets/world/settlements/ruins.png")
var font: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const LAMP: Texture2D = preload("res://assets/world/props/lamp.png")
const ZONE_NAMES: Array[String] = ["ANDÉN", "HORNOS", "DIQUE", "AVENIDA", "ENLACE"]

func _ready() -> void:
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	clock += delta
	if clock >= 0.08:
		clock = 0
		queue_redraw()

func facade(x: float, height: float, frame: int, tint: Color, back: bool = false, recovery: float = 0) -> void:
	var width: float = height * 128.0 / 144
	var floor_y: float = GameRules.FLOOR_Y - (4 if back else 0)
	var rect: Rect2 = Rect2(x - width / 2, floor_y - height + height * 3 / 144, width, height)
	draw_texture_rect_region(art, rect, Rect2(frame * 128, 0, 128, 144), tint)
	if recovery > 0 and not back:
		var scale_factor: float = height / 144.0
		var warm: Color = Color("47dacb") if world.zone_index == 4 else Color("ffce75")
		var lit_windows: int = 4 if recovery > 0.5 else 2
		for index: int in lit_windows:
			var at: Vector2 = Vector2(x - width / 2 + (49 + index % 2 * 21) * scale_factor, floor_y - height + (41 + floori(index / 2.0) * 29) * scale_factor)
			draw_rect(Rect2(at, Vector2(6, 10) * scale_factor), Color(warm, 0.48 if world.cycle.phase == "NOCHE" else 0.27))
	if not back:
		draw_set_transform(Vector2(x, GameRules.FLOOR_Y + 3), 0, Vector2(1, -0.16))
		draw_texture_rect_region(art, Rect2(-width / 2, -height, width, height), Rect2(frame * 128, 0, 128, 144), Color(0.4, 0.6, 0.7, 0.10))
		draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if world == null: return
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0.0
	var zone: int = world.zone_index
	var night: bool = world.cycle.phase == "NOCHE"
	var glow: float = 0.8 if GamePreferences.current().reduced_flashes else 0.7 + sin(elapsed * 0.8) * 0.12
	for index: int in range(-10, 11):
		if index == 0: continue
		var center: float = index * 680 + (zone - 2) * 17
		if absf(center - camera_x) > 650: continue
		var variant: int = absi(index) % 2
		var recovery: float = world.settlements.recovery_at(center)
		facade(center - 32, 140 + (absi(index) % 3) * 9, zone * 2 + variant, Color("596b75"), true)
		facade(center + 70, 119, zone * 2 + 1 - variant, Color("53636d"), true)
		for building: int in 3:
			var x: float = center - 93 + building * 91
			var height: float = 91 + (absi(index + building) % 3) * 13
			var tint: Color = Color("9bafb5") if zone == 2 else Color("b1b7b5")
			facade(x, height, zone * 2 + (variant + building) % 2, tint.lerp(Color.WHITE, recovery * 0.7), false, recovery)
			if building == 1:
				var window_tint: Color = Color("ffce75") if zone != 4 else Color("47dacb")
				draw_rect(Rect2(x - 8, GameRules.FLOOR_Y - 32, 6, 9), Color(window_tint, glow * (0.62 if night else 0.25)))
				if night: draw_circle(Vector2(x - 5, GameRules.FLOOR_Y - 27), 14, Color(window_tint, 0.035))
		# A sagging service cable, laundry, poles and a readable district sign.
		for segment: int in 12:
			var a: float = segment / 12.0
			var b: float = (segment + 1) / 12.0
			draw_line(Vector2(center - 145 + a * 290, GameRules.FLOOR_Y - 64 + sin(a * PI) * 15), Vector2(center - 145 + b * 290, GameRules.FLOOR_Y - 64 + sin(b * PI) * 15), Color("1a2b36"), 1)
		for cloth: int in 3:
			var offset: float = sin(elapsed * 1.4 + index + cloth) * 1.5
			var cloth_color: Color = Color("49646b") if cloth % 2 == 0 else Color("6c6556")
			draw_colored_polygon(PackedVector2Array([Vector2(center + cloth * 10 - 20, 211), Vector2(center + cloth * 10 - 13, 211), Vector2(center + cloth * 10 - 12 + offset, 222), Vector2(center + cloth * 10 - 20 + offset, 221)]), cloth_color.lerp(Color("879f9a"), recovery))
		if recovery > 0:
			var flag_x: float = center + 125
			var wave: float = sin(elapsed * 1.8 + index) * 2
			draw_line(Vector2(flag_x, GameRules.FLOOR_Y), Vector2(flag_x, GameRules.FLOOR_Y - 78), Color("8299a8"), 2)
			draw_colored_polygon(PackedVector2Array([Vector2(flag_x, 184), Vector2(flag_x + 17, 186 + wave), Vector2(flag_x + 15, 198 + wave), Vector2(flag_x, 196)]), Color("47a59d") if recovery < 1 else Color("d6ac68"))
			if GamePreferences.current().particles:
				var pulse: float = fposmod(elapsed * 0.16 + index * 0.23, 1)
				draw_circle(Vector2(center - 145 + pulse * 290, GameRules.FLOOR_Y - 64 + sin(pulse * PI) * 15), 1.5, Color("47dacb", 0.7))
		var lamp_x: float = center + 145
		draw_texture(LAMP, Vector2(lamp_x - LAMP.get_width() / 2.0, GameRules.FLOOR_Y - LAMP.get_height()), Color("889da6"))
		if night: draw_circle(Vector2(lamp_x + 2, GameRules.FLOOR_Y - 28), 18, Color(1.0, 0.68, 0.3, 0.06))
		draw_rect(Rect2(center - 42, GameRules.FLOOR_Y - 15, 84, 12), Color("14232e", 0.9))
		var address: String = "%s %02d" % [ZONE_NAMES[zone], absi(index)] + (" · RED" if recovery > 0 else "")
		draw_string(font, Vector2(center - 37, GameRules.FLOOR_Y - 6), address, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("c3b27e") if recovery > 0 else Color("8d9c9f"))
		if GamePreferences.current().particles:
			for puff: int in 4:
				var rise: float = fposmod(elapsed * 5 + puff * 9 + index * 3, 40)
				draw_circle(Vector2(center + 26 + sin(rise * 0.1) * 3, GameRules.FLOOR_Y - 113 - rise), 3 + rise * 0.08, Color(0.44, 0.5, 0.52, (1 - rise / 40) * 0.09))
	# Foreground route clutter is detailed scenery, kept behind buildable defences.
	for index: int in range(floori((camera_x - 450) / 190), ceili((camera_x + 450) / 190)):
		var x: float = index * 190 + 36
		if absf(x) < 160: continue
		for bolt: int in 4:
			draw_rect(Rect2(x + bolt * 5, GameRules.FLOOR_Y - 3, 3, 2), Color("41515b"))
		draw_line(Vector2(x - 15, GameRules.FLOOR_Y - 1), Vector2(x + 26, GameRules.FLOOR_Y - 2), Color("647579"), 1)
	for site: ConstructionSite in world.construction.defensive_sites():
		if site.hp > 0 or site.ordered or absf(site.x - camera_x) > 360 or world.frontier.blocked(site.x): continue
		var preview: Texture2D = FortressArt.texture("wall" if site.data.blocks_enemies else "turret_base", 1)
		var height: float = 26 if site.data.blocks_enemies else 22
		draw_texture_rect(preview, ArtScale.grounded(ArtScale.source(preview), height, Vector2(site.x, GameRules.FLOOR_Y)), false, Color(0.5, 0.7, 0.72, 0.22))
