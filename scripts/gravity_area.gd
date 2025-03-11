class_name GravityArea

extends Area2D

@export var gravity_k := 3.0

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(8, true)

func _physics_process(delta: float) -> void:
	for obj in get_overlapping_bodies():
		if obj is P_Point:
			obj.apply_force(gravity_k * global_position.distance_to(obj.global_position) * obj.global_position.direction_to(global_position))
