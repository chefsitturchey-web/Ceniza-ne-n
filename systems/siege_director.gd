class_name SiegeDirector
extends Node

signal spawned(enemy: SiegeEnemy, side: float)
@export var waves: Array[WaveData] = []
var player: Player
var construction: ConstructionSystem
var core: ColonyCore
var bank: ResourceBank
var session: SessionController
var spawn_remaining: float = 0.0
var spawn_count: int = 0
var night: int = 1
var wave: WaveData
var expansion: ExpansionSystem

func start(number: int) -> void:
	night = number
	wave = waves[number - 1]
	spawn_count = 0
	spawn_remaining = 0.0

func tick(delta: float) -> void:
	spawn_remaining -= delta
	if spawn_remaining <= 0.0 and spawn_count < wave.enemies.size():
		var side: float = wave.sides[spawn_count]
		if session.civic == null or not session.civic.side_closed(side):
			spawn_enemy(side, wave.enemies[spawn_count], night, spawn_count == wave.enemies.size() - 1)
		spawn_count += 1
		spawn_remaining = wave.cadence

func is_cleared() -> bool:
	return spawn_count >= wave.enemies.size() and get_tree().get_nodes_in_group(GameRules.ENEMIES).is_empty()

func spawn_enemy(side: float, data: EnemyData, number: int = 1, elite: bool = false) -> SiegeEnemy:
	var enemy: SiegeEnemy = data.scene.instantiate() as SiegeEnemy
	enemy.data = data
	enemy.player = player
	enemy.construction = construction
	enemy.core = core
	enemy.session = session
	enemy.night = number
	enemy.elite = elite
	enemy.reward_requested.connect(bank.deposit)
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	var distance: float = maxf(data.spawn_distance, expansion.frontier(side) + 180) if expansion != null else data.spawn_distance
	enemy.position = Vector2(side * minf(GameRules.MAP_HALF_WIDTH - 25, distance), GameRules.FLOOR_Y)
	if session.civic != null: enemy.position.x = session.civic.entrance(side)
	add_child(enemy)
	spawned.emit(enemy, side)
	return enemy
