extends Skill
func _init() -> void:
	id = 1
	Name = "闪避布"
	cooldown = 5.0
	duration = 1.0
func effect() -> void:
	Game.sound("guard")
