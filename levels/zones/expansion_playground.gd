extends Node
## Escena de práctica aislada. Los recursos extra nunca pasan a la campaña.
var demo_time: float = 0
var demo_wave: int = 0
var world: District
var prepared: bool = false

func _ready() -> void:
	world = get_parent() as District
	world.get_node("Session").persistence_enabled = false
	GamePreferences.current().briefing_requested = false
	world.get_node("Bank").scrap = 260
	call_deferred("prepare")

func prepare() -> void:
	if prepared: return
	prepared = true
	world.cycle.config = world.cycle.config.duplicate() as CycleConfig
	world.cycle.config.day_duration = 90
	world.cycle.phase_remaining = 90
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	world.presenter.show_notice("PRÁCTICA: despliega módulos con E. Partida sin guardado.")

func _process(delta: float) -> void:
	if not prepared or world.session.finished or world.expedition.active: return
	demo_time += delta
	if demo_wave < 3 and demo_time >= 20 + demo_wave * 18:
		for side: float in [-1.0, 1.0]:
			var id: String = "artillero" if side < 0 else "saboteador"
			var enemy: SiegeEnemy = world.director.spawn_enemy(side, load("res://data/enemies/" + id + ".tres"))
			enemy.position.x = side * 1410
		demo_wave += 1
		world.presenter.show_notice("Práctica: artillero por la izquierda; saboteador por la derecha")
