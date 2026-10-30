class_name ExperienceSystem
extends Node2D
## La experiencia de campaña se recoge en el mundo; cada nivel abre una elección.
var district: Node2D
var level: int = 1
var xp: int = 0
var pending: int = 0
var chest_pending: int = 0
var chest_credits: int = 0
var opened_chests: int = 0
var defeated: int = 0
var drops: Array[Dictionary] = []
var panel: LevelChoicePanel
var elapsed: float = 0
var present_choices: bool = true
var dead_seen: bool = false
var lost: Dictionary = {}
var status: Label
var bar: ColorRect
var hud: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = CanvasLayer.new()
	hud.layer = 3
	add_child(hud)
	status = Label.new()
	status.position = Vector2(12, 28)
	status.add_theme_font_size_override("font_size", 10)
	hud.add_child(status)
	var background: ColorRect = ColorRect.new()
	background.position = Vector2(12, 44)
	background.size = Vector2(136, 3)
	background.color = Color("182639")
	hud.add_child(background)
	bar = ColorRect.new()
	bar.position = background.position
	bar.size.y = 3
	bar.color = Color("47dacb")
	hud.add_child(bar)

func _process(_delta: float) -> void:
	hud.visible = not get_tree().paused and not district.session.finished and not district.expedition.active
	status.text = "NV.%d · DATOS %d/%d" % [level, xp, needed()]
	bar.size.x = 136.0 * xp / needed()

func needed() -> int:
	return 8 + (level - 1) * 3

func setup(world: Node2D) -> void:
	district = world
	panel = LevelChoicePanel.new()
	panel.experience = self
	add_child(panel)

func drop(origin: Vector2, amount: int, elite: bool) -> void:
	defeated += 1
	if drops.size() >= 256:
		drops[0].amount += amount
	else:
		drops.append({"x": origin.x, "amount": maxi(1, amount), "chest": false})
	if elite and drops.size() < 260: drops.append({"x": origin.x, "amount": 0, "chest": true})
	queue_redraw()

func gain(amount: int) -> void:
	xp += maxi(0, amount)
	while level < 30 and xp >= needed():
		xp -= needed()
		level += 1
		pending += 1
	if level == 30: xp = 0
	district.neural.changed.emit()

func tick(delta: float) -> void:
	elapsed += delta
	if district.player.health <= 0 and not dead_seen:
		dead_seen = true
		lost = {"x": district.player.position.x, "amount": xp} if xp > 0 else {}
		xp = 0
	elif district.player.health > 0:
		dead_seen = false
		if not lost.is_empty() and absf(float(lost.x) - district.player.position.x) < 24:
			gain(int(lost.amount))
			lost.clear()
	if district.player.health > 0:
		for index: int in range(drops.size() - 1, -1, -1):
			var item: Dictionary = drops[index]
			var distance: float = absf(float(item.x) - district.player.position.x)
			var radius: float = 95 + (15 * district.modules.passive_rank("magnet") if district.modules.passives.magnet else 0)
			if distance < radius and not item.chest:
				item.x = move_toward(item.x, district.player.position.x, delta * 220)
			if distance < (28 if item.chest else 14):
				if item.chest:
					opened_chests += 1
					chest_pending += 1
					district.modules.cores += 1
				else: gain(int(item.amount))
				drops.remove_at(index)
				district.play("pickup")
	if present_choices and district.player.health > 0 and not panel.opened and (pending > 0 or chest_pending > 0) and not get_tree().paused and not district.session.finished:
		panel.open_choices(chest_pending > 0)
	queue_redraw()

func options(chest: bool = false) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var gear: ModuleSystem = district.modules
	if not chest and district.neural.points() <= 0:
		return [{"id": "scrap", "type": "scrap", "title": "Reserva de suministros", "text": "+15 chatarra; mejora ya asignada."}]
	if chest:
		for data: ModuleData in ModuleSystem.DATA:
			if gear.can_evolve(data.id): choices.append({"id": data.id, "type": "evolve", "title": data.evolution, "text": "Evolucionar " + data.title + ". Consume este núcleo."})
	for data: ModuleData in ModuleSystem.DATA:
		if gear.levels[data.id] < 5 and (data.id in gear.equipped or gear.equipped.size() < 2):
			choices.append({"id": data.id, "type": "weapon", "title": data.title + " · " + ("NUEVO" if gear.levels[data.id] == 0 else "Nv. %d → %d" % [gear.levels[data.id], gear.levels[data.id] + 1]), "text": data.description})
	for id: String in ModuleSystem.PASSIVE_IDS:
		if gear.passive_rank(id) < 5 and (gear.passives[id] or gear.passive_count() < 4):
			choices.append({"id": id, "type": "passive", "title": ModuleSystem.PASSIVE_TITLES[id] + " · Nv. %d" % (gear.passive_rank(id) + 1), "text": ModuleSystem.PASSIVE_TEXT[id]})
	for id: String in NeuralSystem.IDS:
		if district.neural.ranks[id] < 3:
			choices.append({"id": id, "type": "implant", "title": {"blade": "Filo de inducción", "drone": "Enlace de dron", "capacitor": "Capacitor sináptico"}[id], "text": {"blade": "+10 daño de hoja", "drone": "+4 daño de dron y mayor cadencia", "capacitor": "+5 regeneración de resistencia"}[id]})
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(str(level) + ":" + str(pending) + ":" + str(defeated))
	# Las evoluciones válidas tienen prioridad al abrir un cofre.
	var result: Array[Dictionary] = []
	if chest:
		for choice: Dictionary in choices:
			if choice.type == "evolve" and result.size() < 2: result.append(choice)
	while result.size() < (2 if chest else 3) and not choices.is_empty():
		var index: int = rng.randi_range(0, choices.size() - 1)
		var choice: Dictionary = choices.pop_at(index)
		if choice not in result: result.append(choice)
	if chest: result.append({"id": "core", "type": "core", "title": "Guardar núcleo", "text": "Conservarlo para una evolución posterior."})
	if result.is_empty(): result.append({"id": "scrap", "type": "scrap", "title": "Reserva de suministros", "text": "+15 chatarra; equipo al máximo."})
	return result

func choose(choice: Dictionary, chest: bool) -> bool:
	if (chest and chest_pending <= 0) or (not chest and pending <= 0): return false
	if choice not in options(chest): return false
	var credit: bool = chest and choice.type not in ["core", "evolve"]
	if credit: chest_credits += 1
	var accepted: bool = false
	match choice.type:
		"weapon": accepted = district.neural.upgrade_module(choice.id)
		"passive": accepted = district.neural.install_passive(choice.id)
		"implant": accepted = district.neural.install(choice.id)
		"evolve": accepted = district.modules.evolve(choice.id)
		"core": accepted = true
		"scrap":
			district.bank.deposit(15)
			accepted = true
	if not accepted:
		if credit: chest_credits -= 1
		return false
	if chest:
		chest_pending -= 1
		if credit: district.modules.cores -= 1
	else: pending -= 1
	district.neural.changed.emit()
	district.sound.play_cue("upgrade")
	return true

func snapshot() -> Dictionary:
	return {"level": level, "xp": xp, "pending": pending, "chest_pending": chest_pending, "chest_credits": chest_credits, "opened_chests": opened_chests, "defeated": defeated, "drops": drops.duplicate(true), "lost": lost.duplicate(), "dead_seen": dead_seen}

func restore(data: Dictionary) -> void:
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	pending = int(data.get("pending", 0))
	chest_pending = int(data.get("chest_pending", 0))
	chest_credits = int(data.get("chest_credits", 0))
	opened_chests = int(data.get("opened_chests", 0))
	defeated = int(data.get("defeated", 0))
	dead_seen = data.get("dead_seen", false)
	drops.clear()
	for item: Dictionary in data.get("drops", []):
		drops.append({"x": float(item.x), "amount": int(item.amount), "chest": item.chest})
	lost = {}
	if not data.get("lost", {}).is_empty(): lost = {"x": float(data.lost.x), "amount": int(data.lost.amount)}
	queue_redraw()

static func valid(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not data.get("dead_seen", false) is bool: return false
	for key: String in ["level", "xp", "pending", "chest_pending", "chest_credits", "opened_chests", "defeated"]:
		if not ExpansionSystem.number(data.get(key), 1 if key == "level" else 0, 30 if key == "level" else 1000000, true): return false
	if data.pending > data.level - 1 or data.chest_credits + data.chest_pending > data.opened_chests or data.xp >= 8 + (data.level - 1) * 3: return false
	if not data.get("drops") is Array or data.drops.size() > 260: return false
	var signal_data: Variant = data.get("lost", {})
	if not signal_data is Dictionary: return false
	if not signal_data.is_empty() and (not ExpansionSystem.number(signal_data.get("x"), -1600, 1600) or not ExpansionSystem.number(signal_data.get("amount"), 0, 1000, true)): return false
	for item: Variant in data.drops:
		if not item is Dictionary or not item.get("chest") is bool or not ExpansionSystem.number(item.get("x"), -1600, 1600) or not ExpansionSystem.number(item.get("amount"), 0, 1000000, true): return false
	return true

func _draw() -> void:
	if not lost.is_empty():
		draw_circle(Vector2(lost.x, GameRules.FLOOR_Y - 16), 10, Color("ffce75", 0.2))
		draw_line(Vector2(lost.x, GameRules.FLOOR_Y - 27), Vector2(lost.x, GameRules.FLOOR_Y - 5), Color("ffce75"), 2)
	for item: Dictionary in drops:
		var y: float = GameRules.FLOOR_Y - 7 + roundf(sin(elapsed * 3 + float(item.x)) * 2)
		if item.chest:
			draw_rect(Rect2(item.x - 8, y - 7, 16, 12), Color("704c43"))
			draw_rect(Rect2(item.x - 8, y - 7, 16, 3), Color("ffce75"))
			draw_rect(Rect2(item.x - 1, y - 3, 3, 5), Color("47dacb"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(item.x, y - 4), Vector2(item.x + 3, y), Vector2(item.x, y + 4), Vector2(item.x - 3, y)]), Color("47dacb"))
