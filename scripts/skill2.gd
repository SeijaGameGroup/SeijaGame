extends "res://scripts/skill.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("skill2"):
		if available:
			cooldown_timer.start(cooldown)
			start.emit()
			duration_timer.start(duration)
			
		else: 
			if not duration_timer.is_stopped():
				duration_timer.stop()
				end.emit()
	pass
