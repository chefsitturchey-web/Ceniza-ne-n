extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	var actor: Node2D = Node2D.new()
	world.add_child(actor)
	var emitter: DebrisEmitter = DebrisEmitter.new()
	actor.add_child(emitter)
	emitter.emit_fragments(Vector2(0, GameRules.FLOOR_Y), null, 5)
	verify(DebrisEmitter.live_count == 5, "Emisor crea cinco trozos")
	actor.free()
	verify(DebrisEmitter.live_count == 5, "Los trozos sobreviven al actor")
	for child: Node in world.get_children():
		if child is DebrisEmitter.Pixel:
			child._process(0.1)
			verify(child.global_position == child.global_position.round(), "Pixel snapping")
			child.precise_position.y = GameRules.FLOOR_Y + 1
			child.velocity.y = 50
			child._process(0.01)
			verify(child.velocity.y < 0, "Trozos rebotan en el suelo")
			child._process(2.0)
	await process_frame
	verify(DebrisEmitter.live_count == 0, "Trozos se autodestruyen y liberan presupuesto")
	var player: Player = load("res://entities/player/player.tscn").instantiate() as Player
	world.add_child(player)
	player.set_physics_process(false)
	player.stamina = 20
	player.velocity.x = 10
	player.refresh_state()
	player.visual._process(0.1)
	verify(is_equal_approx(player.visual.sprite.speed_scale, 0.8), "Cansancio ralentiza solo la animación de carrera")
	verify(player.velocity.x == 10, "Cansancio no cambia velocidad física")
	player.stamina = 100
	player.visual._process(0.1)
	verify(is_equal_approx(player.visual.sprite.speed_scale, 1.0), "Recuperar energía restaura animación")
	player.take_damage(1)
	verify(player.visual.shake > 0, "Daño del jugador activa sacudida visual")
	player.free()
	for child: Node in world.get_children():
		child.free()
	var wall: ConstructionSite = ConstructionSite.new()
	wall.data = load("res://data/structures/wall.tres")
	wall.position.y = GameRules.FLOOR_Y
	world.add_child(wall)
	wall.hp = wall.max_hp
	verify(wall.effects.stage(wall.hp) == 0, "Estructura sana sin grietas")
	wall.take_damage(ceili(wall.max_hp * 0.35))
	verify(wall.effects.stage(wall.hp) == 1, "Primera etapa de daño al 66%")
	wall.take_damage(ceili(wall.max_hp * 0.33))
	verify(wall.effects.stage(wall.hp) == 2, "Segunda etapa de daño al 33%")
	var before_smoke: int = DebrisEmitter.live_count
	wall.effects._process(0.4)
	verify(DebrisEmitter.live_count == before_smoke + 1, "Daño grave emite humo")
	wall.complete_work()
	verify(wall.effects.stage(wall.hp) == 0, "Reparación elimina grietas")
	for child: Node in world.get_children():
		if child is DebrisEmitter.Pixel:
			child.free()
	wall.take_damage(wall.max_hp)
	var fragments: int = 0
	for child: Node in world.get_children():
		if child is DebrisEmitter.Pixel and child.texture == wall.data.texture:
			fragments += 1
			verify(child.region.has_area(), "Fragmento usa un recorte real")
	verify(fragments == 8 and wall.hp == 0 and not wall.ordered, "Muralla destruida genera ocho fragmentos")
	wall.effects.emit_pixels(Vector2.ZERO, 200, Color.WHITE)
	verify(DebrisEmitter.live_count == DebrisEmitter.LIMIT, "Primer emisor respeta límite")
	var second: ConstructionSite = ConstructionSite.new()
	second.data = wall.data
	world.add_child(second)
	second.effects.emit_fragments(Vector2.ZERO, wall.data.texture, 200)
	verify(DebrisEmitter.live_count == DebrisEmitter.LIMIT, "Límite compartido entre emisores")
	world.free()
	verify(DebrisEmitter.live_count == 0, "Cerrar mundo libera todas las partículas")
	var range_world: Node2D = Node2D.new()
	root.add_child(range_world)
	var turret: ConstructionSite = ConstructionSite.new()
	turret.data = load("res://data/structures/turret.tres")
	turret.position = Vector2(-180, GameRules.FLOOR_Y)
	range_world.add_child(turret)
	turret.hp = turret.max_hp
	turret.fire_effects()
	var kinds: Array[StringName] = []
	for child: Node in range_world.get_children():
		if child is DebrisEmitter.Pixel:
			kinds.append(child.effect_kind)
	verify(kinds.has(&"muzzle_flash") and kinds.has(&"casing"), "Disparo crea fogonazo y casquillo")
	verify(turret.recoil > 0.0, "Disparo aplica retroceso")
	verify(turret.muzzle_position().x < turret.global_position.x, "Cañón del frente izquierdo apunta hacia afuera")
	var dust_emitter: DebrisEmitter = DebrisEmitter.new()
	range_world.add_child(dust_emitter)
	var before_dust: int = DebrisEmitter.live_count
	dust_emitter.emit_dust(Vector2(0, GameRules.FLOOR_Y), 3)
	verify(DebrisEmitter.live_count == before_dust + 3, "Polvo crea partículas")
	range_world.free()
	var hud: GameHud = load("res://ui/hud.tscn").instantiate() as GameHud
	root.add_child(hud)
	verify(hud.pause_panel.icons.size() == 11, "HUD instancia los once íconos")
	var all_loaded: bool = true
	for key: String in hud.pause_panel.icons:
		all_loaded = all_loaded and (hud.pause_panel.icons[key] as TextureRect).texture != null
	verify(all_loaded, "Todos los íconos del HUD tienen textura")
	hud.display_dashboard({"phase": "NOCHE", "day": 2, "nights": 3, "seconds": 9, "scrap": 40, "energy": 1,
		"capacity": 4, "population": 2, "population_max": 4, "health": 70, "stamina": 50, "core": 200,
		"left": 1, "right": 2, "overload_left": "LISTA", "overload_right": "LISTA"})
	verify(hud.icons.noche.visible and not hud.icons.dia.visible, "Ícono de fase cambia con la noche")
	verify(hud.pause_panel.bars.nucleo.value == 200 and hud.values.chatarra.text == "40", "Pausa conserva integridad y HUD muestra chatarra")
	hud.free()
	print("Efectos: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
