extends "res://scripts/skill.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if Input.is_action_just_pressed("skill2"):
		if available:
			cooldown_timer.start(cooldown)
			duration_timer.start(duration)
			player.upside_down = true
			player.speed_multiplier = 1.5
			await duration_timer.timeout
			player.upside_down = false
			player.speed_multiplier = 1

		else:
			if not duration_timer.is_stopped():
				duration_timer.stop()
				player.upside_down = false
				player.speed_multiplier = 1
