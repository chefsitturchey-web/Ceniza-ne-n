extends SceneTree
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void: call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func picture(index: int) -> void:
	if not capture: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/combat-art/hud_jefe_%d.png" % index)

func run_checks() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/combat-art"))
	var colors: Dictionary = {}
	for index: int in 5:
		var arena: RecaudadorArena = load("res://levels/expedition/recaudador_arena.tscn").instantiate()
		arena.zone_index = index
		root.add_child(arena)
		arena.set_process(false)
		arena.player.set_physics_process(false)
		arena.boss.set_physics_process(false)
		arena.dynamics.set_physics_process(false)
		arena.modules.set_physics_process(false)
		var hud: BossBattleHud = arena.combat_hud
		await physics_frame
		verify(hud.player_ratio == 1 and hud.boss_ratio == 1 and hud.boss_trail == 1, "Las barras nacen llenas sin interpolación desde cero: %d" % index)
		verify(hud.zone_index == index and hud.boss_title == arena.zone.boss_title, "Marco y nombre corresponden al encuentro: %d" % index)
		verify(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "La interfaz no intercepta ataques: %d" % index)
		arena.player.take_damage(25)
		verify(hud.health == 75 and is_equal_approx(hud.player_ratio, 0.75), "Daño real actualiza la vida inmediatamente: %d" % index)
		verify(hud.player_trail == 1 and hud.player_hold > 0, "La estela conserva el daño recién recibido: %d" % index)
		hud.advance(0.2)
		verify(hud.player_trail == 1, "La estela respeta su espera inicial: %d" % index)
		arena.boss.health = int(arena.boss.max_health * 0.6)
		arena.boss.phase = 2
		arena.player.stamina = 35
		arena._process(0.01)
		verify(is_equal_approx(hud.boss_ratio, 0.6) and hud.phase == 2 and hud.stamina == 35, "Vida, fase y resistencia siguen al juego: %d" % index)
		var before: float = hud.boss_trail
		arena.set_process(true)
		paused = true
		await create_timer(0.05, true).timeout
		verify(hud.boss_trail == before, "Pausa detiene la estela de daño: %d" % index)
		paused = false
		arena.set_process(false)
		(root.get_node("DebugTools") as GameDebug).refresh_info()
		await picture(index)
		hud.advance(3)
		verify(hud.player_trail == hud.player_ratio and hud.boss_trail == hud.boss_ratio, "Las estelas convergen sin sobrepasar la vida: %d" % index)
		arena.player.health = Player.MAX_HEALTH
		arena.player.stamina = Player.MAX_STAMINA
		arena._process(0)
		verify(hud.player_ratio == 1 and hud.player_trail == 1, "Curación y reinicios de depuración actualizan la barra: %d" % index)
		if index == 2: (arena.boss as CoroSumergido).exposure_left = 2
		elif index == 4: (arena.boss as MadreCero).exposure = 2
		else: arena.boss.state = Recaudador.State.STUNNED if index == 0 else Recaudador.State.RECOVER
		arena._process(0)
		verify(hud.exposed, "El marco indica la ventana vulnerable: %d" % index)
		var badge: Button = (root.get_node("DebugTools") as GameDebug).badge
		verify(not badge.get_rect().intersects(BossBattleHud.BOSS_TRACK.grow(15)), "El botón F1 deja libre el marco del jefe: %d" % index)
		colors[hud.PALETTES[index]] = true
		arena.boss.health = 0
		arena._process(0)
		verify(hud.boss_ratio == 0, "La barra vacía representa la derrota: %d" % index)
		arena.free()
		await process_frame
	verify(colors.size() == 5, "Cinco marcos con paletas diferentes")
	print("Interfaz de jefes: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures else 0)
