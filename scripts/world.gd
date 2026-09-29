extends Node2D
## Partida corta: economía, obras, tres asedios y resultado final.
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ERRANTE_SCENE: PackedScene = preload("res://scenes/errante.tscn")
const CORREDOR_SCENE: PackedScene = preload("res://scenes/corredor.tscn")
const FLOOR_Y: float = 260.0
@export var day_duration: float = 90.0
@export var warning_duration: float = 10.0
@export var night_duration: float = 60.0
var player: CharacterBody2D
var scrap: int = 90
var core_health: int = 300
var day: int = 1
var phase: String = "DÍA"
var phase_remaining: float = 90.0
var finished: bool = false
var won: bool = false
var sites: Array[Dictionary] = []
var workers: Array[Dictionary] = []
var energy_capacity: int = 4
var overload_left: float = 0.0
var overload_right: float = 0.0
var cooldown_left: float = 0.0
var cooldown_right: float = 0.0
var spawn_remaining: float = 0.0
var spawn_count: int = 0
var hold_time: float = 0.0
var hold_target: int = -99
var drone_timer: float = 0.0
var beams: Array[Dictionary] = []
var hud: Label
var hint: Label
var result_label: Label
var notice: String = "Construye ambas murallas y torretas antes de la noche."
var notice_time: float = 7.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	configure_input()
	phase_remaining = day_duration
	add_solid(Vector2(0, FLOOR_Y + 20), Vector2(1920, 40))
	add_solid(Vector2(-968, 100), Vector2(16, 400))
	add_solid(Vector2(968, 100), Vector2(16, 400))
	for side in [-1.0, 1.0]:
		sites.append(make_site("wall", side * 240.0, 20, 240))
		sites.append(make_site("turret", side * 180.0, 25, 100))
	player = PLAYER_SCENE.instantiate() as CharacterBody2D
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.position = Vector2(0, FLOOR_Y)
	add_child(player)
	add_worker("builder")
	add_worker("collector")
	create_hud()

func make_site(kind: String, x: float, cost: int, max_hp: int) -> Dictionary:
	return {"kind": kind, "x": x, "cost": cost, "hp": 0, "max_hp": max_hp,
		"ordered": false, "progress": 0.0, "shot": 0.0}

func configure_input() -> void:
	add_action("move_left", KEY_A, JOY_BUTTON_DPAD_LEFT)
	add_action("move_right", KEY_D, JOY_BUTTON_DPAD_RIGHT)
	for entry in [["move_left", KEY_LEFT, -1.0], ["move_right", KEY_RIGHT, 1.0]]:
		var key := InputEventKey.new()
		key.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], key)
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = entry[2]
		InputMap.action_add_event(entry[0], axis)
	add_action("attack", KEY_J, JOY_BUTTON_X)
	add_action("dodge", KEY_SPACE, JOY_BUTTON_A)
	add_action("interact", KEY_E, JOY_BUTTON_Y)
	add_action("overload", KEY_Q, JOY_BUTTON_LEFT_SHOULDER)
	add_action("pause", KEY_ESCAPE, JOY_BUTTON_START)
	add_action("restart", KEY_R, JOY_BUTTON_BACK)

func add_action(action: StringName, keycode: Key, button: JoyButton) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.2)
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	InputMap.action_add_event(action, key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = button
	InputMap.action_add_event(action, pad)

func add_solid(at: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func add_worker(role: String) -> void:
	workers.append({"role": role, "x": 0.0, "job": -1, "gather": 0.0,
		"cargo": 0, "side": -1.0 if workers.size() < 2 else 1.0})

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart") and finished:
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pause") and not finished:
		get_tree().paused = not get_tree().paused
	if get_tree().paused or finished:
		update_hud()
		return
	if core_health <= 0:
		finish(false)
		return
	notice_time = maxf(0.0, notice_time - delta)
	overload_left = maxf(0.0, overload_left - delta)
	overload_right = maxf(0.0, overload_right - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)
	cooldown_right = maxf(0.0, cooldown_right - delta)
	update_phase(delta)
	if finished:
		return
	update_workers(delta)
	update_defenses(delta)
	update_interaction(delta)
	if Input.is_action_just_pressed("overload") and player.health > 0:
		activate_overload()
	for index in range(beams.size() - 1, -1, -1):
		beams[index].time -= delta
		if beams[index].time <= 0:
			beams.remove_at(index)
	update_hud()
	queue_redraw()

func update_phase(delta: float) -> void:
	phase_remaining = maxf(0.0, phase_remaining - delta)
	if phase == "NOCHE":
		spawn_remaining -= delta
		if spawn_remaining <= 0.0 and spawn_count < 8 + day * 4:
			spawn_enemy(-1.0 if spawn_count % 2 == 0 else 1.0, spawn_count % 3 == 2)
			spawn_count += 1
			spawn_remaining = 2.2 - day * 0.4
	if phase_remaining > 0.0:
		return
	if phase == "DÍA":
		phase = "AVISO"
		phase_remaining = warning_duration
		show_notice("¡Ataque por ambos frentes! Los recuperadores regresan.")
	elif phase == "AVISO":
		phase = "NOCHE"
		phase_remaining = night_duration
		spawn_count = 0
		spawn_remaining = 0.0
	elif get_tree().get_nodes_in_group("enemies").is_empty() and spawn_count >= 8 + day * 4:
		if day == 3:
			finish(true)
		else:
			day += 1
			phase = "DÍA"
			phase_remaining = day_duration
			scrap += 25
			core_health = mini(300, core_health + 40)
			player.health = 100
			show_notice("Amanecer: +25 chatarra. Repara y prepara el siguiente asedio.")

func spawn_enemy(side: float, runner: bool) -> Node2D:
	var enemy: Node2D
	if runner:
		enemy = CORREDOR_SCENE.instantiate() as Node2D
	else:
		enemy = ERRANTE_SCENE.instantiate() as Node2D
	enemy.world = self
	enemy.runner = runner
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.position = Vector2(side * 650.0, FLOOR_Y)
	add_child(enemy)
	return enemy

func update_workers(delta: float) -> void:
	for index in range(workers.size()):
		var worker: Dictionary = workers[index]
		if worker.role == "collector":
			var destination: float = worker.side * 330.0 if phase == "DÍA" and worker.cargo == 0 else worker.side * 35.0
			worker.x = move_toward(worker.x, destination, 65.0 * delta)
			if absf(worker.x - destination) < 1.0:
				if absf(destination) > 100.0:
					worker.gather += delta
					if worker.gather >= 3.0:
						worker.cargo = 8
						worker.gather = 0.0
				else:
					scrap += worker.cargo
					worker.cargo = 0
			continue
		# Una reserva por obra impide que los constructores dupliquen tareas.
		if worker.job >= 0:
			var job: Dictionary = sites[worker.job]
			if not job.ordered or unsafe_at(job.x):
				worker.job = -1
		if worker.job == -1:
			for site_index in range(sites.size()):
				if not sites[site_index].ordered or unsafe_at(sites[site_index].x):
					continue
				var reserved: bool = false
				for other in workers:
					if other.job == site_index:
						reserved = true
				if not reserved:
					worker.job = site_index
					break
		var destination: float = worker.side * 55.0
		if worker.job >= 0:
			destination = sites[worker.job].x
		worker.x = move_toward(worker.x, destination, 75.0 * delta)
		if worker.job >= 0 and absf(worker.x - destination) < 2.0:
			var job: Dictionary = sites[worker.job]
			job.progress += delta * (2.0 if overloaded(job.x) else 1.0)
			if job.progress >= 4.0:
				job.hp = job.max_hp
				job.ordered = false
				job.progress = 0.0
				worker.job = -1

func unsafe_at(x: float) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if absf(enemy.position.x - x) < 110.0:
			return true
	return false

func energy_used() -> int:
	var used: int = 0
	for site in sites:
		if site.kind == "turret" and (site.hp > 0 or site.ordered):
			used += 2
	return used

func nearest_enemy(x: float, distance_limit: float) -> Node2D:
	var best: Node2D = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = absf(enemy.position.x - x)
		if distance < distance_limit:
			distance_limit = distance
			best = enemy
	return best

func fire_from(origin: Vector2, target: Node2D, damage: int) -> void:
	beams.append({"from": origin, "to": target.position + Vector2(0, -16), "time": 0.1})
	target.take_damage(damage)

func update_defenses(delta: float) -> void:
	for site in sites:
		if site.kind != "turret" or site.hp <= 0:
			continue
		site.shot = maxf(0.0, site.shot - delta)
		if site.shot == 0.0:
			var target: Node2D = nearest_enemy(site.x, 260.0)
			if target != null:
				fire_from(Vector2(site.x, FLOOR_Y - 42), target, 18)
				site.shot = 0.35 if overloaded(site.x) else 1.1
	drone_timer = maxf(0.0, drone_timer - delta)
	if drone_timer == 0.0 and player.health > 0:
		var target: Node2D = nearest_enemy(player.position.x, 105.0)
		if target != null:
			fire_from(player.position + Vector2(-18, -48), target, 12)
			drone_timer = 1.2

func overloaded(x: float) -> bool:
	return overload_left > 0.0 if x < 0.0 else overload_right > 0.0

func activate_overload() -> void:
	var left: bool = player.position.x < 0.0
	if (cooldown_left if left else cooldown_right) > 0.0:
		show_notice("Ese frente está enfriándose.")
		return
	if energy_used() == 0:
		show_notice("Construye una torreta para utilizar la sobrecarga.")
		return
	if left:
		overload_left = 6.0
		cooldown_left = 24.0
	else:
		overload_right = 6.0
		cooldown_right = 24.0
	show_notice("Sobrecarga: seis segundos de disparo y trabajo acelerados.")

func interaction_target() -> int:
	if absf(player.position.x) < 45.0:
		return -1
	var best: int = -99
	var distance: float = 38.0
	for index in range(sites.size()):
		var candidate: float = absf(player.position.x - sites[index].x)
		if candidate < distance:
			distance = candidate
			best = index
	return best

func update_interaction(delta: float) -> void:
	var target: int = interaction_target()
	if target != hold_target or not Input.is_action_pressed("interact") or player.health <= 0:
		hold_time = 0.0
		hold_target = target
		return
	if target == -99:
		return
	hold_time += delta
	if hold_time >= 0.8:
		perform_interaction(target)
		hold_time = 0.0

func perform_interaction(target: int) -> bool:
	if target == -1:
		if phase != "DÍA":
			show_notice("El refugio recluta y cura durante el día.")
			return false
		if player.health < 100:
			player.health = 100
			show_notice("Salud restaurada en el núcleo.")
			return true
		if workers.size() >= 4:
			show_notice("Colonia completa: dos constructores y dos recuperadores.")
			return false
		if scrap < 15:
			show_notice("Necesitas 15 de chatarra para reclutar.")
			return false
		scrap -= 15
		add_worker("builder" if workers.size() == 2 else "collector")
		show_notice("Habitante reclutado. Su trabajo es automático.")
		return true
	if target < 0 or target >= sites.size():
		return false
	var site: Dictionary = sites[target]
	if site.ordered or site.hp == site.max_hp:
		return false
	var cost: int = site.cost if site.hp == 0 else 8
	if scrap < cost:
		show_notice("Falta chatarra: tus recuperadores producen durante el día.")
		return false
	if site.kind == "turret" and site.hp == 0 and energy_used() + 2 > energy_capacity:
		show_notice("Capacidad energética insuficiente.")
		return false
	scrap -= cost
	site.ordered = true
	site.progress = 0.0
	show_notice("Obra encargada. Un constructor acudirá cuando sea seguro.")
	return true

func damage_site(index: int, amount: int) -> void:
	var site: Dictionary = sites[index]
	site.hp = maxi(0, site.hp - amount)
	if site.hp == 0:
		site.ordered = false
		site.progress = 0.0

func finish(victory: bool) -> void:
	finished = true
	won = victory
	player.enabled = false
	update_hud()
	queue_redraw()

func show_notice(message: String) -> void:
	notice = message
	notice_time = 4.0

func create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.03, 0.06, 0.92)
	panel.size = Vector2(640, 82)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(12, 6)
	hud.add_theme_font_size_override("font_size", 12)
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(12, 297)
	hint.add_theme_font_size_override("font_size", 12)
	layer.add_child(hint)
	result_label = Label.new()
	result_label.position = Vector2(80, 116)
	result_label.size = Vector2(480, 130)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(result_label)
	update_hud()

func update_hud() -> void:
	if hud == null:
		return
	var left_count: int = 0
	var right_count: int = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.x < 0:
			left_count += 1
		else:
			right_count += 1
	hud.text = "CENIZA NEÓN  |  %s %d/3 · %ds  |  Chatarra %d  |  Energía %d/%d\n" % [phase, day, ceili(phase_remaining), scrap, energy_used(), energy_capacity]
	hud.text += "Vida %d  ·  Resistencia %d  ·  Núcleo %d/300  ·  Habitantes %d/4\n" % [player.health, int(player.stamina), core_health, workers.size()]
	hud.text += "Amenazas  ◀ %d / %d ▶  |  Sobrecarga IZQ %s / DER %s\n" % [left_count, right_count, overload_status(true), overload_status(false)]
	hud.text += "A/D mover · J ataque · Espacio esquiva · E obra · Q sobrecarga · Esc pausa"
	var context: String = "Defiende el núcleo. Sobrevive a tres noches."
	var target: int = interaction_target()
	if target == -1:
		context = "Mantén E: curarte / reclutar (15 chatarra, solo de día)."
	elif target >= 0:
		var site: Dictionary = sites[target]
		var title: String = "Muralla" if site.kind == "wall" else "Torreta (2 energía)"
		if site.ordered:
			context = "%s · Obra %d%% · Esperando trabajo seguro" % [title, int(site.progress / 4.0 * 100)]
		elif site.hp == site.max_hp:
			context = "%s · %d/%d de integridad" % [title, site.hp, site.max_hp]
		else:
			context = "%s · Mantén E: %s (%d chatarra)" % [title, "construir" if site.hp == 0 else "reparar", site.cost if site.hp == 0 else 8]
	if hold_time > 0.0:
		context += "  %d%%" % int(hold_time / 0.8 * 100)
	hint.text = context + "\n" + (notice if notice_time > 0.0 else "Mando: X ataque · A esquiva · Y obra · LB sobrecarga · Start pausa")
	result_label.text = ""
	if player.health <= 0:
		result_label.text = "Reenlace en %d s\n¡La colonia sigue defendiéndose!" % ceili(player.respawn_remaining)
	if get_tree().paused:
		result_label.text = "PAUSA\nEsc / Start para continuar"
	if finished:
		result_label.text = ("DISTRITO ESTABILIZADO" if won else "NÚCLEO DESTRUIDO") + "\n\nR / Select: nueva partida"

func overload_status(left: bool) -> String:
	var active: float = overload_left if left else overload_right
	var cooldown: float = cooldown_left if left else cooldown_right
	if active > 0.0:
		return "ACTIVA %ds" % ceili(active)
	return "%ds" % ceili(cooldown) if cooldown > 0.0 else "LISTA"

func _draw() -> void:
	var night: bool = phase == "NOCHE"
	for index in range(24):
		var x: float = -960.0 + index * 80.0
		var height: float = 60.0 + float((index * 37) % 95)
		draw_rect(Rect2(x, FLOOR_Y - height, 55, height), Color("0b1322") if night else Color("182639"))
		draw_rect(Rect2(x + 12, FLOOR_Y - height + 12, 4, 16), Color("477687"))
	draw_rect(Rect2(-960, FLOOR_Y, 1920, 80), Color("202c39"))
	draw_line(Vector2(-960, FLOOR_Y), Vector2(960, FLOOR_Y), Color("4c8591"), 2.0)
	draw_rect(Rect2(-30, FLOOR_Y - 65, 60, 65), Color("304356"))
	draw_rect(Rect2(-14, FLOOR_Y - 52, 28, 32), Color("e89e54"))
	draw_rect(Rect2(-30, FLOOR_Y - 74, 60.0 * core_health / 300.0, 4), Color("47dacb"))
	for site in sites:
		var x: float = site.x
		var color := Color("47dacb") if overloaded(x) else Color("8299a8")
		if site.hp > 0:
			if site.kind == "wall":
				draw_rect(Rect2(x - 10, FLOOR_Y - 45, 20, 45), color)
				draw_rect(Rect2(x - 5, FLOOR_Y - 40, 10, 30), Color("304356"))
			else:
				draw_rect(Rect2(x - 5, FLOOR_Y - 35, 10, 35), color)
				draw_rect(Rect2(x - 14, FLOOR_Y - 45, 28, 12), color)
			draw_rect(Rect2(x - 14, FLOOR_Y - 54, 28.0 * site.hp / site.max_hp, 3), Color("47dacb"))
		else:
			draw_rect(Rect2(x - 12, FLOOR_Y - 40, 24, 40), Color("b075ae"), false, 1.0)
		if site.ordered:
			draw_rect(Rect2(x - 14, FLOOR_Y - 60, 28.0 * site.progress / 4.0, 3), Color("ffce75"))
	for worker in workers:
		var color := Color("ffce75") if worker.role == "builder" else Color("b075ae")
		draw_rect(Rect2(worker.x - 5, FLOOR_Y - 19, 10, 19), color)
		if worker.cargo > 0:
			draw_rect(Rect2(worker.x + 5, FLOOR_Y - 12, 6, 6), Color("8299a8"))
	if is_instance_valid(player) and player.health > 0:
		draw_circle(player.position + Vector2(-18, -48), 5, Color("47dacb"))
	for beam in beams:
		draw_line(beam.from, beam.to, Color("ffce75"), 2.0)
