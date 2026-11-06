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
	var prefs: GamePreferences = GamePreferences.current() as GamePreferences
	var previous: bool = prefs.reduced_flashes
	var ui_theme: Theme = load("res://ui/theme.tres") as Theme
	verify(ui_theme.get_type_list().has("MenuEntry"), "El tema define la variacion MenuEntry")
	var button: Button = Button.new()
	root.add_child(button)
	MenuFx.juice_button(button)
	MenuFx.juice_button(button)
	verify(button.offset_transform_enabled and button.has_meta(&"juiced"), "Boton con movimiento, sin duplicar conexiones")
	verify(button.mouse_entered.get_connections().size() == 1, "juice_button es idempotente")
	var panel: PanelContainer = PanelContainer.new()
	root.add_child(panel)
	prefs.values.reduced_flashes = false
	MenuFx.enter(panel, 20.0)
	verify(panel.modulate.a == 0.0 and panel.offset_transform_position.y == 20.0, "El panel arranca oculto y desplazado")
	prefs.values.reduced_flashes = true
	MenuFx.enter(panel, 20.0)
	verify(panel.modulate.a == 0.0 and MenuFx.reduced(), "Con destellos reducidos solo hay fundido")
	verify(ScreenFade.duration() < 0.25, "Disolvencia corta con destellos reducidos")
	prefs.values.reduced_flashes = previous
	verify(not ScreenFade.enabled(), "Sin pantalla el cambio de escena es directo")
	var menu: MainMenu = load("res://ui/main_menu.tscn").instantiate() as MainMenu
	menu.navigation_enabled = false
	root.add_child(menu)
	await process_frame
	verify(menu.neon_title != null and menu.embers != null and menu.ash != null, "Menu con neon y particulas")
	verify(menu.continue_button.theme_type_variation == &"MenuEntry", "Botones del menu usan el tema")
	menu.free()
	panel.free()
	button.free()
	print("menu_polish_test: %d comprobaciones, %d fallos" % [checks, failures])
	if failures == 0:
		print("PASS: menu_polish_test")
	quit(1 if failures > 0 else 0)
