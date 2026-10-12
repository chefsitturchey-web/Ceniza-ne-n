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
	session.initialize()
	presenter.publish()
