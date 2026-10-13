class_name PlayerCombat
extends Node

var burst_left: float = 0.0
var dash_left: float = 0.0
var dash_remaining: float = 0.0
var dash_direction: float = 1.0
@onready var player: Player = get_parent() as Player

func _physics_process(delta: float) -> void:
	burst_left = maxf(0.0, burst_left - delta)
	dash_left = maxf(0.0, dash_left - delta)
	dash_remaining = maxf(0.0, dash_remaining - delta)

func damage_multiplier() -> float:
	var multiplier: float = Game.balance.flip_burst_multiplier if burst_left > 0.0 else 1.0
	if Game.revolution.active_left > 0.0:
		multiplier *= Game.balance.revolution_multiplier
	return multiplier

func shot_interval() -> float:
	return Game.balance.shot_interval * (0.65 if Game.revolution.active_left > 0.0 else 1.0)

func shoot() -> void:
	var direction: Vector2 = Vector2(player.facing_direction, 0)
	if is_instance_valid(player.enemy_tracked):
		direction = player.global_position.direction_to(player.enemy_tracked.global_position)
	var stats: PlayerStats = Game.player_stats
	var damage: float = Game.balance.shot_damage * stats.damage_multipler_item * damage_multiplier()
	if player.upside_down:
		damage *= stats.inversion_damage
	spawn_shot(direction, damage)
	if Game.run.rng.randf() < stats.extra_shot_chance:
		spawn_shot(direction.rotated(0.08), damage)
	for index: int in stats.side_shots:
		spawn_shot(direction.rotated(0.16 + index * 0.12), damage * 0.4)
		spawn_shot(direction.rotated(-0.16 - index * 0.12), damage * 0.4)
	player.shot_count += 1
	Game.sound("shoot")

func spawn_shot(direction: Vector2, damage: float) -> void:
	var bullet: CombatBullet = CombatBullet.new()
	bullet.position = player.global_position + direction * 24
	bullet.velocity = direction * 920
	bullet.damage = damage
	bullet.friendly = true
	bullet.pierces_left = Game.player_stats.pierce_count
	player.get_parent().add_child(bullet)

func flip_burst() -> void:
	burst_left = Game.balance.flip_burst_duration
	Game.feedback.pulse(player.global_position, 155.0, Color("dba5f0"))
	var absorbed: int = 0
	for bullet: Node in get_tree().get_nodes_in_group("combat_bullets"):
		if not bullet.friendly and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(player.global_position) < 155:
			bullet.queue_free()
			absorbed += 1
	Game.gain_energy(mini(absorbed, 8) * 4.0)
	Game.notify("逆转爆发 · 2 秒增伤", 1.4)

func dash() -> void:
	if dash_remaining > 0.0 or not player.can_act():
		return
	dash_direction = player.facing_direction
	dash_left = Game.balance.dash_duration
	dash_remaining = Game.balance.dash_cooldown
	Game.feedback.pulse(player.global_position, 55.0, Color("8edde0"))

func revolution() -> void:
	Game.notify("不光荣革命！弹幕反转 · 连射强化", 2.4)
	Game.feedback.pulse(player.global_position, 640, Color("f3bcdd"))
	for bullet: Node in get_tree().get_nodes_in_group("combat_bullets"):
		if not bullet.friendly and not bullet.is_queued_for_deletion() and player.in_view(bullet.global_position):
			bullet.reflect(player)
	for enemy: Node in get_tree().get_nodes_in_group("combat_enemies"):
		if enemy.targetable and not enemy.dead and player.in_view(enemy.global_position):
			enemy.receive_damage(Game.balance.revolution_damage * Game.player_stats.damage_multipler_item, player.global_position)
	player.immunity_left = maxf(player.immunity_left, 0.8)
	Game.sound("win")
