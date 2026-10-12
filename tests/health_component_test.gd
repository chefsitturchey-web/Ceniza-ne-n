extends SceneTree

var checks: int = 0
var failures: int = 0
var damage_events: Array[Vector2i] = []
var heal_events: Array[Vector2i] = []
var deaths: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	var health: HealthComponent = HealthComponent.new()
	root.add_child(health)
	health.maximum = 120
	health.reset()
	health.damaged.connect(on_damage)
	health.healed.connect(on_heal)
	health.died.connect(on_death)
	verify(health.current == 120, "Inicialización con vida máxima")
	health.take_damage(0)
	health.take_damage(-10)
	verify(health.current == 120 and damage_events.is_empty(), "Ignorar daño no positivo")
	health.take_damage(35)
	verify(health.current == 85 and damage_events == [Vector2i(35, 85)], "Daño y señal con cantidad aplicada")
	health.heal(10)
	verify(health.current == 95 and heal_events == [Vector2i(10, 95)], "Curación y señal")
	health.heal(100)
	verify(health.current == 120 and heal_events.back() == Vector2i(25, 120), "Curación limitada al máximo")
	health.heal(0)
	health.heal(-5)
	health.heal(10)
	verify(heal_events.size() == 2, "No emitir curaciones vacías")
	health.take_damage(1000)
	verify(health.current == 0 and damage_events.back() == Vector2i(120, 0), "Daño letal limitado a vida restante")
	verify(deaths == 1, "Una señal de muerte")
	health.take_damage(1)
	health.heal(20)
	verify(health.current == 0 and deaths == 1 and damage_events.size() == 2, "Un muerto necesita reinicio explícito")
	health.reset()
	verify(health.current == 120, "Reinicio para reaparición u obra")
	health.take_damage(120)
	verify(deaths == 2, "Muerte después del reinicio")
	health.reset(1000)
	verify(health.current == 120, "Reinicio acotado al máximo")
	health.free()
	print("HealthComponent: %d comprobaciones; %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)

func on_damage(amount: int, remaining: int) -> void:
	damage_events.append(Vector2i(amount, remaining))

func on_heal(amount: int, remaining: int) -> void:
	heal_events.append(Vector2i(amount, remaining))

func on_death() -> void:
	deaths += 1
