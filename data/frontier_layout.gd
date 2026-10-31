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

## Semilla de la campaña: 0 conserva el trazado de referencia (partidas antiguas y pruebas).
static var active_seed: int = 0
static var profile_cache: Dictionary = {}

static func new_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 2147483646)

static func profile(zone: int) -> Dictionary:
	var base: Dictionary = PROFILES[clampi(zone, 0, 4)]
	if active_seed == 0: return base
	var key: String = "%d:%d" % [zone, active_seed]
	if not profile_cache.has(key): profile_cache[key] = varied(base, zone)
	return profile_cache[key]

## Desplazamiento determinista para otros elementos del distrito (poblados, alijos).
static func offset(zone: int, salt: int, amount: float) -> float:
	if active_seed == 0: return 0.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([active_seed, zone, salt])
	return roundf(rng.randf_range(-amount, amount) / 10.0) * 10.0

## Cada campaña mueve murallas, brechas, solares y operaciones dentro de márgenes que
## conservan el orden de avance: muros crecientes y espaciados, brechas entre muros,
## y operaciones de cerca a lejos (rescate antes que transporte).
static func varied(base: Dictionary, zone: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([active_seed, zone, "frontier"])
	var result: Dictionary = base.duplicate(true)
	result.rescue = -clampf(absf(float(base.rescue)) + rng.randi_range(-30, 30) * 10, 1900.0, 3800.0)
	result.relay = clampf(float(base.relay) + rng.randi_range(-40, 40) * 10, 2600.0, 5600.0)
	result.convoy = -clampf(absf(float(base.convoy)) + rng.randi_range(-40, 40) * 10, absf(result.rescue) + 900.0, 6200.0)
	for side: String in ["left", "right"]:
		# Puntos fijos de cada lado que un muro o su torreta no deben tapar.
		var taken: Array[float] = [700.0, 1140.0, 1340.0, 1500.0, 6640.0 - zone * 35, 6820.0, 6900.0]
		if side == "left": taken.append_array([880.0, 425.0, 560.0, 700.0, absf(result.rescue), absf(result.convoy)])
		else: taken.append(float(result.relay))
		var walls: Array = []
		var previous: float = 600.0
		for index: int in 6:
			var low: float = previous + 650.0 if index > 0 else 700.0
			var value: float = clampf(float(base[side][index]) + rng.randi_range(-18, 18) * 10, low, 6650.0 - (5 - index) * 650.0)
			# Busca el hueco libre más cercano alternando hacia fuera y hacia dentro.
			# Si el margen normal no deja hueco (último muro), admite muros algo más juntos.
			for step: int in 320:
				var candidate: float = value + ceili((step % 160) / 2.0) * 10.0 * (1 if step % 2 == 1 else -1)
				if candidate < (low if step < 160 else previous + 450.0) or candidate > 6650.0: continue
				if not crowded(candidate, taken) and (candidate <= 1100.0 or not crowded(candidate - 135.0, taken)):
					value = candidate
					break
			walls.append(value)
			previous = value
		result[side] = walls
	for key: String in ["lots", "outer"]:
		var values: Array = []
		for value: Variant in base[key]: values.append(float(value) + rng.randi_range(-12, 12) * 10)
		result[key] = values
	var gates: Array = []
	for gate: Variant in base.gates: gates.append(clampf(float(gate) + rng.randi_range(-20, 20) * 10, 1800.0, 6000.0))
	gates.sort()
	for index: int in range(1, gates.size()): gates[index] = maxf(gates[index], gates[index - 1] + 900.0)
	result.gates = gates
	return result

static func crowded(x: float, taken: Array[float]) -> bool:
	return taken.any(func(point: float) -> bool: return absf(point - x) < 80.0)

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
	var key: String = "%d:%d" % [zone, active_seed]
	if not lot_cache.has(key): lot_cache[key] = plan_lots(zone)
	return lot_cache[key][index]

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
