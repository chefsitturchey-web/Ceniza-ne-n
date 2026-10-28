class_name RaidBolt
extends Node2D
## Colisión barrida: una bala no atraviesa una defensa por un fotograma largo.
var session: SessionController
var direction: float = 1
var damage: int = 14
var lifetime: float = 5
var spent: bool = false

func _physics_process(delta: float) -> void:
	if spent: return
	if session.finished:
		spent = true
		queue_free()
		return
	lifetime -= delta
	if lifetime <= 0:
		spent = true
		queue_free()
		return
	var next_x: float = position.x + direction * 300 * delta
	var candidates: Array[Node2D] = [session.core]
	if session.player.health > 0: candidates.append(session.player)
	for site: ConstructionSite in session.bank.sites:
		if site.hp > 0 and site.data.blocks_enemies: candidates.append(site)
	if session.expansion != null:
		for site: ExpansionOutpost in session.expansion.sites:
			if site.hp > 0: candidates.append(site)
	for ally: Node in get_tree().get_nodes_in_group(GameRules.ALLIES): candidates.append(ally as Node2D)
	var hit: Node2D
	var best: float = INF
	for candidate: Node2D in candidates:
		var offset: float = (candidate.position.x - position.x) * direction
		if offset < -15 or offset > absf(next_x - position.x) + 15: continue
		if offset < best:
			best = offset
			hit = candidate
	if hit != null:
		spent = true
		hit.take_damage(damage)
		queue_free()
	else:
		position.x = next_x
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-direction * 11, 0), Vector2.ZERO, Color("dd6482"), 2)
	draw_rect(Rect2(-2, -1, 4, 2), Color("ffce75"))
