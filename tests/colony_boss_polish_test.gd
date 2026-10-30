extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func picture(name: String) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/validation/latest/polish-%s.png" % name)

func arena_for(zone: int) -> RecaudadorArena:
	var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
	arena.zone_index = zone
	root.add_child(arena)
	arena.set_process(false)
	arena.boss.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.dynamics.set_physics_process(false)
	arena.modules.set_physics_process(false)
	arena.combat_effects.set_physics_process(false)
	return arena

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	var menu: MainMenu = load("res://ui/main_menu.tscn").instantiate()
	menu.navigation_enabled = false
	root.add_child(menu)
	await picture("menu")
	menu.free()
	var world: District = load(CampaignRoute.SCENES[0]).instantiate()
	(world.get_node("Session") as SessionController).persistence_enabled = false
	root.add_child(world)
	world.session.set_process(false)
	world.player.set_physics_process(false)
	world.story.present_dialogue = false
	world.story.dialogue_queue.clear()
	world.experience.present_choices = false
	world.core.restore({"tier": 3, "ordered": false, "progress": 0})
	world.bank.scrap = 1000
	world.bank.stored_parts = 100
	var barracks: ExpansionOutpost
	for site: ExpansionOutpost in world.expansion.sites:
		if site.spec.id == "barracks":
			barracks = site
			break
	barracks.hp = ExpansionOutpost.MAX_HEALTH
	var first: FieldAlly = barracks.hire("ranger")
	var second: FieldAlly = barracks.hire("ranger")
	world.civic.balance_defenders()
	verify(first.defense_side() == -second.defense_side(), "One barracks distributes two riflemen across opposite fronts")
	var saved: Dictionary = second.snapshot()
	second.duty_side = 0
	second.restore(saved)
	verify(second.duty_side == int(saved.duty_side), "Assigned front persists across saving/loading")
	first.take_damage(100)
	var third: FieldAlly = barracks.hire("ranger")
	world.civic.balance_defenders()
	verify(second.defense_side() == -third.defense_side(), "Replacement rifleman restores the missing front")
	verify(ExpansionSystem.valid(world.expansion.snapshot()), "New crew metadata remains compatible with checkpoint validation")
	verify(world.interaction.target_at_x(-600) == InteractionSystem.SHOP_TARGET, "Workshop has one contextual catalog interaction")
	verify(world.interaction.perform_interaction(InteractionSystem.SHOP_TARGET) and paused, "Catalog owns the gameplay pause")
	var shop: EquipmentShop = world.equipment_shop
	shop.select_item(0)
	var scrap: int = world.bank.scrap
	shop.buy()
	verify(world.civic.tools[0] == 1 and world.bank.scrap == scrap - CivicSystem.COSTS[0], "Catalog purchase pays once and reserves a real civilian tool")
	await picture("shop")
	shop.select_item(6)
	shop.buy()
	verify(world.workshop.shovel_ready, "Catalog also crafts invasion equipment through the existing recipe")
	shop.close_panel()
	verify(not paused and shop.closed_frame == Engine.get_process_frames(), "Closing catalog restores time and guards the closing input frame")
	for wall: ConstructionSite in world.civic.walls:
		verify(not wall.z_as_relative and wall.z_index > world.settlement_backdrop.z_index, "Outer wall renders above town facades")
	for id: String in ["errante", "corredor"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		var enemy: SiegeEnemy = world.director.spawn_enemy(1, data, 1)
		var texture: Texture2D = enemy.sprite.sprite_frames.get_frame_texture(&"reposo", 0)
		var bottom: int = texture.get_image().get_used_rect().end.y
		verify(absf(enemy.sprite.position.y + (bottom - texture.get_height() * 0.5) * enemy.sprite.scale.y) < 1, "Enemy feet touch floor: " + id)
		enemy.queue_free()
	world.player.position.x = world.civic.walls[0].x
	var camera: Camera2D = world.player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	world.civic.walls[0].hp = world.civic.walls[0].max_hp
	world.presenter.publish()
	await picture("colony")
	world.free()
	for zone: int in 5:
		var arena: RecaudadorArena = arena_for(zone)
		await physics_frame
		var cover: ArenaCover
		for child: Node in arena.actors.get_children():
			if child is ArenaCover:
				cover = child
				break
		var old_obstacles: int = arena.dynamics.obstacle_rects.size()
		arena.combat_effects.impact(cover.position, 35, 2.1, 4)
		verify(cover.health > 0 and cover.health < cover.maximum, "Heavy attack visibly damages cover: %d" % zone)
		arena.combat_effects.impact(cover.position, 35, 5, 8)
		verify(cover.health == 0 and cover.collision_layer == 0, "Repeated heavy attacks destroy cover: %d" % zone)
		await process_frame
		verify(arena.dynamics.obstacle_rects.size() == old_obstacles - 1, "Destruction opens boss navigation: %d" % zone)
		var opening: Dictionary = VisualStory.scene(zone, "encounter")
		var ending: Dictionary = VisualStory.scene(zone, "ending")
		verify(opening.lines.size() >= 6 and ending.lines.size() >= 4 and opening.lines[0].speaker == BossDialogue.VOICES[zone], "Each boss introduces its own history and has a correlated ending: %d" % zone)
		verify(arena.novel.actor_texture(BossDialogue.VOICES[zone]) != null, "Each boss has a usable visual novel portrait: %d" % zone)
		if zone == 2:
			arena.novel.play(opening)
			for frame: int in 30: await process_frame
			arena.novel.body.visible_characters = -1
			arena.novel.reveal = 10000
			await picture("novel-coro")
			arena.novel.close_panel()
			await process_frame
			paused = false
		if zone == 0:
			paused = true
			verify(arena.novel.play(opening, true), "Boss lore can be replayed from pause without advancing combat")
			arena.novel.finish_close()
			verify(paused, "Reading lore from pause returns to the existing pause")
			paused = false
		arena.free()
	# Death callbacks clear hazards synchronously; stress both independent sources.
	for source: String in ["wave", "mark", "secondary", "cargo"]:
		var arena: RecaudadorArena = arena_for(2 if source != "cargo" else 0)
		await physics_frame
		arena.player.health = 1
		arena.player.invulnerable = 0
		arena.player.position = Vector2(320, 250)
		arena.boss.phase = 2
		if source in ["wave", "mark"]:
			var choir: CoroSumergido = arena.boss as CoroSumergido
			choir.pulse_timer = 50
			choir.mark_timer = 50
			if source == "wave":
				for index: int in 3: choir.waves.append({"radius": 1.0, "origin": arena.player.position - Vector2(10, 0), "hit": false})
			else:
				for index: int in 3: choir.marks.append({"position": arena.player.position, "time": 0.01, "hit": false})
			choir._physics_process(0.2)
			verify(choir.waves.is_empty() and choir.marks.is_empty(), "Death cancels all choir attacks: " + source)
		elif source == "secondary":
			for index: int in 3: arena.combat_effects.hazards.append({"kind": "burst", "origin": arena.player.position, "end": arena.player.position, "radius": 80.0, "time": 0.01, "hit": false})
			arena.combat_effects.tick(0.1)
		else:
			for index: int in 3: arena.dynamics.device_effects.append({"kind": "cargo", "position": arena.player.position, "time": 0.01})
			arena.dynamics._physics_process(0.1)
		verify(arena.player.health == 0 and arena.ending and not arena.boss.is_physics_processing(), "Phase-two defeat resolves once without invalid array access: " + source)
		arena.free()
	await process_frame
	print("Pulido colonia/jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
