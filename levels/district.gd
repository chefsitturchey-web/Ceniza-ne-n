class_name District
extends Node2D

@export_range(0, 2) var zone_index: int = 0
var zone: ZoneData

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
var expansion: ExpansionSystem
var experience: ExperienceSystem
var civic: CivicSystem

func _ready() -> void:
	InputSetup.configure_input()
	zone = CampaignRoute.zone(zone_index)
	if zone_index > 0:
		var blueprints: Array[StructureData] = []
		for original: StructureData in construction.blueprints:
			var copy: StructureData = original.duplicate() as StructureData
			copy.offset = zone.wall_offset if copy.blocks_enemies else zone.turret_offset
			blueprints.append(copy)
		construction.blueprints = blueprints
		cycle.config = cycle.config.duplicate() as CycleConfig
		cycle.config.day_duration = zone.day_duration
		director.waves.assign(zone.waves)
	construction.bank = bank
	construction.viewer = player
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
	session.zone_index = zone_index
	session.campaign = CampaignRoute.initial_state(zone_index)
	session.core = core
	session.bank = bank
	session.cycle = cycle
	session.colony = colony
	session.defenses = defenses
	session.interaction = interaction
	session.overload = overload
	expansion = ExpansionSystem.new()
	expansion.setup(self)
	add_child(expansion)
	session.expansion = expansion
	bank.expansion = expansion
	interaction.expansion = expansion
	director.expansion = expansion
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
	view.zone = zone
	add_child(CanalForeground.new())
	if zone_index > 0:
		var terrain: ZoneHazards = ZoneHazards.new()
		terrain.zone_index = zone_index
		terrain.player = player
		terrain.cycle = cycle
		terrain.z_index = 1
		add_child(terrain)
		session.terrain = terrain
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
	experience = ExperienceSystem.new()
	experience.setup(self)
	add_child(experience)
	neural.experience = experience
	session.experience = experience
	civic = CivicSystem.new()
	civic.setup(self)
	add_child(civic)
	construction.external_sites = civic.walls
	colony.civic = civic
	interaction.civic = civic
	session.civic = civic
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
	var arriving: bool = not CampaignRoute.pending.is_empty()
	session.initialize()
	sound.district = self
	add_child(sound)
	presenter.publish()
	if GamePreferences.current().briefing_requested or arriving:
		GamePreferences.current().briefing_requested = false
		briefing = BriefingPanel.new()
		briefing.zone = zone
		add_child(briefing)
		session.briefing = briefing
		briefing.open_panel()

func _connect_neural(enemy: SiegeEnemy, _side: float) -> void:
	enemy.reward_requested.connect(func(reward: int) -> void:
		experience.drop(enemy.position, reward, enemy.elite))
