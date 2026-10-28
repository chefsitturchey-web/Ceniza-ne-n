class_name District
extends Node2D

@onready var player: Player = $Player
@onready var cycle: CycleSystem = $Cycle
@onready var bank: ResourceBank = $Bank
@onready var core: ColonyCore = $Core
@onready var colony: ColonySystem = $Colony
@onready var construction: ConstructionSystem = $Construction
@onready var overload: OverloadSystem = $Overload
@onready var defenses: DefenseSystem = $Defenses
@onready var director: SiegeDirector = $Director
@onready var interaction: InteractionSystem = $Interaction
@onready var session: SessionController = $Session
@onready var presenter: HudPresenter = $Presenter
@onready var view: DistrictView = $View

@onready var expedition: ExpeditionManager = $Expedition
var neural: NeuralSystem = NeuralSystem.new()
var clinic: NeuralClinic = NeuralClinic.new()
var clinic_panel: ClinicPanel = ClinicPanel.new()
var sound: GameSound = GameSound.new()
var options: SettingsPanel = SettingsPanel.new()
var modules: ModuleSystem = ModuleSystem.new()
var briefing: BriefingPanel

func _ready() -> void:
	InputSetup.configure_input()
	construction.bank = bank
	construction.create_sites()
	for site: ConstructionSite in construction.sites:
		overload.changed.connect(site.update_overload)
	bank.sites = construction.sites
	colony.sites = construction.sites
	colony.bank = bank
	colony.cycle = cycle
	colony.overload = overload
	colony.add_worker(&"builder")
	colony.add_worker(&"collector")
	cycle.director = director
	cycle.initialize()
	director.player = player
	director.construction = construction
	director.core = core
	director.bank = bank
	director.session = session
	overload.bank = bank
	overload.player = player
	defenses.player = player
	defenses.sites = construction.sites
	defenses.overload = overload
	interaction.player = player
	interaction.bank = bank
	interaction.cycle = cycle
	interaction.colony = colony
	interaction.construction = construction
	session.player = player
	session.core = core
	session.bank = bank
	session.cycle = cycle
	session.colony = colony
	session.defenses = defenses
	session.interaction = interaction
	session.overload = overload
	session.presenter = presenter
	presenter.player = player
	presenter.core = core
	presenter.cycle = cycle
	presenter.bank = bank
	presenter.colony = colony
	presenter.construction = construction
	presenter.overload = overload
	presenter.interaction = interaction
	presenter.session = session
	view.player = player
	view.cycle = cycle
	view.defenses = defenses
	cycle.dawn.connect(session.on_dawn)
	cycle.victory_requested.connect(session.win)
	cycle.notice_requested.connect(presenter.show_notice)
	construction.notice_requested.connect(presenter.show_notice)
	interaction.notice_requested.connect(presenter.show_notice)
	overload.notice_requested.connect(presenter.show_notice)
	session.frame_finished.connect(view.queue_redraw)
	presenter.updated.connect($HUD.display)
	presenter.dashboard_updated.connect($HUD.display_dashboard)
	expedition.setup(self)
	session.expedition = expedition
	interaction.expedition = expedition
	cycle.boss_required = true
	neural.player = player
	neural.defenses = defenses
	modules.actor = player
	modules.defenses = defenses
	add_child(modules)
	defenses.modules = modules
	neural.modules = modules
	player.modules = modules
	add_child(neural)
	session.neural = neural
	clinic.position = Vector2(-110, GameRules.FLOOR_Y)
	add_child(clinic)
	clinic_panel.district = self
	add_child(clinic_panel)
	add_child(options)
	session.options = options
	$HUD/PausePanel.options_requested.connect(options.open_panel)
	$HUD/PausePanel.menu_requested.connect(session.return_to_menu)
	$HUD/PausePanel.resume_requested.connect(session.resume_game)
	options.closed.connect(func() -> void:
		if get_tree().paused:
			$HUD/PausePanel.resume_button.grab_focus())
	$HUD.restart_requested.connect(session.restart)
	$HUD.menu_requested.connect(session.return_to_menu)
	session.clinic_panel = clinic_panel
	interaction.clinic_panel = clinic_panel
	interaction.clinic = clinic
	presenter.neural = neural
	neural.changed.connect(func() -> void: clinic.available = neural.points() > 0 or modules.cores > 0)
	neural.point_earned.connect(func() -> void: presenter.show_notice("Punto neuronal: visita la clínica a la izquierda del núcleo"))
	director.spawned.connect(_connect_neural)
	session.initialize()
	sound.district = self
	add_child(sound)
	presenter.publish()
	if GamePreferences.current().briefing_requested:
		GamePreferences.current().briefing_requested = false
		briefing = BriefingPanel.new()
		add_child(briefing)
		session.briefing = briefing
		briefing.open_panel()

func _connect_neural(enemy: SiegeEnemy, _side: float) -> void:
	enemy.reward_requested.connect(neural.recover_data)
	if enemy.elite:
		enemy.reward_requested.connect(func(_reward: int) -> void:
			modules.cores += 1
			neural.changed.emit()
			presenter.show_notice("Núcleo de enlace recuperado: evolución disponible en la clínica"))
