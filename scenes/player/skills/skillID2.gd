extends Skill
func _init() -> void:
	id = 2
	Name = "天地有用"
	cooldown = 12.0
	duration = 6.0
	cancelable = true
func effect() -> void:
	player.set_inverted(true)
	player.combat.flip_burst()
	Game.sound("invert")
func deffect() -> void:
	if is_instance_valid(player):
		player.set_inverted(false)
