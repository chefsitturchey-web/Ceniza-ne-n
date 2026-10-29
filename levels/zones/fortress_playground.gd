extends Node
## Práctica explícita: ningún recurso ni estado se escribe en la campaña.
var world: District

func _ready() -> void:
	world = get_parent() as District
	world.get_node("Session").persistence_enabled = false
	GamePreferences.current().briefing_requested = false
	call_deferred("prepare")

func prepare() -> void:
	world.bank.scrap = 800
	world.cycle.config = world.cycle.config.duplicate() as CycleConfig
	world.cycle.config.day_duration = 900
	world.cycle.phase_remaining = 900
	world.cycle.day = 2
	for site: ConstructionSite in world.construction.sites: site.complete_work()
	world.expansion.sites[2].hp = 180
	world.expansion.sites[0].hp = 180
	world.colony.add_worker(&"builder")
	world.presenter.show_notice("PRÁCTICA: E mejora núcleo y defensas; T energía. Sin guardado.")
