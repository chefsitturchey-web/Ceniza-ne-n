class_name FrontierLayout
extends RefCounted
static var lot_cache: Dictionary = {}

## Distinct, asymmetric industrial districts. Distances are world pixels.
const PROFILES: Array[Dictionary] = [
	{"name": "Corredor ferroviario", "left": [800, 1700, 2800, 3900, 5100, 6200], "right": [960, 2050, 3100, 4250, 5400, 6450], "lots": [520, 880, 390, 1420], "outer": [2550, 3650, 4750, 5850], "gates": [], "rescue": -2350, "relay": 3450, "convoy": -4200, "obstacle": "Vagón descarrilado"},
	{"name": "Terrazas de escoria", "left": [920, 1950, 3150, 4400, 5500, 6550], "right": [720, 1550, 2650, 3850, 5050, 6100], "lots": [650, 1280, 420, 2200], "outer": [2850, 4100, 5150, 5900], "gates": [2700], "rescue": -3250, "relay": 4550, "convoy": -5000, "obstacle": "Escoria solidificada"},
	{"name": "Diques y estaciones", "left": [740, 1620, 2950, 4100, 5350, 6300], "right": [1080, 2250, 3400, 4500, 5700, 6600], "lots": [550, 1350, 390, 2400], "outer": [3050, 4000, 5150, 6100], "gates": [2200, 4400], "rescue": -3550, "relay": 4950, "convoy": -5250, "obstacle": "Conducto inundado"},
	{"name": "Avenidas del Consejo", "left": [1050, 2180, 3300, 4350, 5450, 6550], "right": [780, 1740, 2850, 4050, 5250, 6250], "lots": [700, 1550, 460, 2650], "outer": [3000, 3900, 5050, 5900], "gates": [1900, 3650, 5400], "rescue": -3100, "relay": 4700, "convoy": -5600, "obstacle": "Barricada corporativa"},
	{"name": "Raíces de la red", "left": [980, 1820, 3050, 4250, 5550, 6600], "right": [1140, 2350, 3550, 4650, 5650, 6500], "lots": [610, 1430, 430, 2500], "outer": [3150, 4200, 5300, 6150], "gates": [2050, 3950, 5750], "rescue": -3500, "relay": 5000, "convoy": -5900, "obstacle": "Raíz de fibra activa"}
]

static func profile(zone: int) -> Dictionary:
	return PROFILES[clampi(zone, 0, 4)]

static func wall_positions(zone: int) -> Array[float]:
	var data: Dictionary = profile(zone)
	# Keep the first six legacy slots in order when migrating checkpoints.
	var result: Array[float] = []
	for side: int in [-1, 1]:
		for index: int in 3: result.append(side * float(data.left[index] if side < 0 else data.right[index]))
	for side: int in [-1, 1]:
		for index: int in range(3, 6): result.append(side * float(data.left[index] if side < 0 else data.right[index]))
	return result

static func lot_x(zone: int, index: int) -> float:
	if not lot_cache.has(zone): lot_cache[zone] = plan_lots(zone)
	return lot_cache[zone][index]

static func plan_lots(zone: int) -> Array[float]:
	var data: Dictionary = profile(zone)
	var occupied: Array[float] = [0, -110, 112, -880, -495, -465, -675, -645, -615, -585, -555, -525, -1340, 1340, -1500, -1140, -700, 700, 1140, 1500]
	occupied.append_array([float(data.rescue), float(data.relay), float(data.convoy), 6640.0 - zone * 35])
	var district: ZoneData = CampaignRoute.zone(zone)
	for side: float in [-1.0, 1.0]:
		occupied.append(side * (district.wall_offset if zone > 0 else 240.0))
		occupied.append(side * (district.turret_offset if zone > 0 else 180.0))
		for distance: float in data.gates: occupied.append(side * distance)
	for wall: float in wall_positions(zone):
		occupied.append(wall)
		if absf(wall) > 1100: occupied.append(wall - signf(wall) * 135)
	var result: Array[float] = []
	for index: int in 16:
		var side: float = -1.0 if index % 8 < 4 else 1.0
		var base: float = float(data.lots[index % 4] if index < 8 else data.outer[index % 4])
		var anchor: float = side * (base + (90.0 + zone * 15 if side > 0 else 0.0))
		for attempt: int in 121:
			var offset: float = ceili(attempt / 2.0) * 24 * (-1 if attempt % 2 == 0 else 1)
			var candidate: float = anchor + offset
			if absf(candidate) > 6400 or signf(candidate) != side: continue
			if occupied.any(func(x: float) -> bool: return absf(x - candidate) < 70): continue
			result.append(candidate)
			occupied.append(candidate)
			break
	assert(result.size() == 16, "Each district needs sixteen accessible lots")
	return result
