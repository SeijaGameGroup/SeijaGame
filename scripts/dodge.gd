extends "res://scripts/skill.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if available:
		if Input.is_action_just_pressed("dodge") or not request_timer.is_stopped():
			cooldown_timer.start(cooldown)
			player.movable = false
			duration_timer.start(duration)
			await duration_timer.timeout
			player.movable = true
	elif Input.is_action_just_pressed("dodge"):
		request_timer.start(request_time)
