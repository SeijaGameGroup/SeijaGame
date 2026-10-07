class_name CombatBullet
extends Node2D

var velocity := Vector2.ZERO
var damage := 8.0
var friendly := false
var lifetime := 5.0
var radius := 5.0
var ignore_terrain := false

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
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.collider
		if collider.has_method("receive_damage"):
			collider.receive_damage(damage, global_position)
		queue_free()
		return
	global_position = next
	queue_redraw()

func _draw() -> void:
	var color := Color("#bafbea") if friendly else Color("#ffa27f")
	draw_line(-velocity.normalized() * (15 if friendly else 9), Vector2.ZERO, Color(color, 0.35), radius * 1.5)
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.4, Color("#fff2d1"))
