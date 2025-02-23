class_name Tracked_Bullet
extends Bullet

var object_tracked : Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start(life)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if object_tracked == null:
		queue_free()
	
	velocity = global_position.direction_to(object_tracked.global_position)* speed_func()
	position += velocity * delta
	pass


func speed_func():
	speed = timer.Time * 10
	return speed


