class_name VisibleDetection
extends Node2D

@onready var detection_ray_up: RayCast2D = $DetectionRayUp
@onready var detection_ray_mid: RayCast2D = $DetectionRayMid
@onready var detection_ray_down: RayCast2D = $DetectionRayDown


func visible_detect(target:Node2D, visible_radius:float) -> bool:
	var t_distance:Vector2 = target.global_position - self.global_position
	if visible_radius >= t_distance.length():
		return true
	var t_angle = asin(abs(visible_radius / t_distance.length()))
	detection_ray_mid.target_position = t_distance
	detection_ray_up.target_position = t_distance.rotated(t_angle)
	detection_ray_down.target_position = t_distance.rotated(-t_angle)

	detection_ray_mid.force_raycast_update()
	detection_ray_up.force_raycast_update()
	detection_ray_down.force_raycast_update()

	#var collider_mid = detection_ray_mid.get_collider()
	#var collider_up = detection_ray_up.get_collider()
	#var collider_down = detection_ray_down.get_collider()
	if detection_ray_mid.get_collider() == target:
		return true
	if detection_ray_up.get_collider() == target:
		return true
	if detection_ray_down.get_collider() == target:
		return true
	return false
