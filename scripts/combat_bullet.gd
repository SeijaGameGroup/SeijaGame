class_name CombatBullet
extends Node2D

var velocity := Vector2.ZERO
var damage := 8.0
var friendly := false
var lifetime := 5.0
var radius := 5.0
var ignore_terrain := false
var pierces_left: int = 0
var reflected: bool = false
var _excluded: Array[RID] = []

func reflect(player: Player) -> void:
	if friendly or is_queued_for_deletion():
		return
	friendly = true
	reflected = true
	damage = maxf(damage * 2.0, 24.0) * (1.0 + Game.player_stats.reflection_bonus)
	pierces_left = 1 if Game.player_stats.reflection_bonus > 0.0 else 0
	var direction: Vector2 = -velocity.normalized()
	var nearest: float = INF
	for enemy: Node in get_tree().get_nodes_in_group("combat_enemies"):
		var distance: float = global_position.distance_squared_to(enemy.global_position)
		if enemy.targetable and not enemy.dead and distance < nearest:
			direction = global_position.direction_to(enemy.global_position)
			nearest = distance
	velocity = direction * 720.0
	global_position += direction * 28.0
	Game.gain_energy(Game.balance.reflection_energy)
	Game.feedback.pulse(player.global_position, 58.0, Color("ffd58c"))

func _ready() -> void:
	add_to_group("combat_bullets")
	z_index = 5

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	var next := global_position + velocity * delta
	var mask := (2 if friendly else 1) | (0 if ignore_terrain else 32)
	var query := PhysicsRayQueryParameters2D.create(global_position, next, mask)
	query.hit_from_inside = true
	query.exclude = _excluded
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.collider
		if not friendly and collider is Player and Game.guard.active_left > 0.0:
			reflect(collider)
			return
		if collider.has_method("receive_damage"):
			var damaged: bool = collider.receive_damage(damage, global_position)
			if friendly and damaged:
				Game.register_hit(hit.position, damage)
				if pierces_left > 0 and collider is CollisionObject2D:
					pierces_left -= 1
					_excluded.append(collider.get_rid())
					global_position = hit.position + velocity.normalized() * 3.0
					return
		queue_free()
		return
	global_position = next
	queue_redraw()

func _draw() -> void:
	var color := Color("#bafbea") if friendly else Color("#ffa27f")
	if reflected:
		color = Color("ffda85")
	draw_line(-velocity.normalized() * (15 if friendly else 9), Vector2.ZERO, Color(color, 0.35), radius * 1.5)
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.4, Color("#fff2d1"))
