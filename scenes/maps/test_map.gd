extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var static_body_2d: StaticBody2D = $StaticBody2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D

const bias := Vector2(0, 10)

func _physics_process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	var point = camera_2d.get_screen_center_position() - viewport_size*0.5 / camera_2d.zoom
	static_body_2d.global_position = point + bias
