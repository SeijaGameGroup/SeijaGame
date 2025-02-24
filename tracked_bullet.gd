class_name Tracked_Bullet
extends Bullet

var object_tracked : Node2D


func _ready():
	timer.start(life)


func _process(delta):
	if object_tracked == null:
		velocity = Vector2.ZERO
	else:
		velocity = global_position.direction_to(object_tracked.global_position)* speed_func()
		position += velocity * delta
	pass


func speed_func():
	speed = 80
	return speed


