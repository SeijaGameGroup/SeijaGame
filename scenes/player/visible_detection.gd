extends Node2D

@export_flags_2d_physics var visible_collision_mask : int
@onready var player: Player = $".."

@onready var detection_ray_up: RayCast2D = $DetectionRayUp
@onready var detection_ray_mid: RayCast2D = $DetectionRayMid
@onready var detection_ray_down: RayCast2D = $DetectionRayDown
@onready var detection_rays = [detection_ray_mid, detection_ray_up, detection_ray_down]


func _ready() -> void:
	for ray:RayCast2D in detection_rays:
		ray.collision_mask = visible_collision_mask

func visible_detect(target, visible_radius:float) -> bool:
	var t_distance:Vector2 = target.global_position - self.global_position
	if visible_radius >= t_distance.length():
		return true
	var t_angle = asin(abs(visible_radius / t_distance.length()))
	detection_ray_mid.target_position = t_distance
	detection_ray_up.target_position = t_distance.rotated(t_angle)
	detection_ray_down.target_position = t_distance.rotated(-t_angle)

	var exceptions:Array = player.enemies_in_sight
	exceptions.erase(target)
	for ray:RayCast2D in detection_rays:
		if not exceptions.is_empty():
			for exception in exceptions:
				if exception:
					ray.add_exception(exception)
		ray.force_raycast_update()
		if not exceptions.is_empty():
			for exception in exceptions:
				if exception:
					ray.remove_exception(exception)
		var collider = ray.get_collider()
		if collider:
			if ray.get_collider() == target or ray.get_collider().owner == target:
				return true

	return false
