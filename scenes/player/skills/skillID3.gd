extends Skill

func _init() -> void:
	id = 3
	Name = "不光荣革命"
	cooldown = 0.5
	duration = 4.0

func skill_pressed() -> void:
	if not is_instance_valid(player) or not player.can_act() or active_left > 0.0:
		return
	if Game.run.energy < 100.0:
		Game.notify("逆势 %d / 100 · 命中、击杀与弹反可蓄能" % int(Game.run.energy), 1.2)
		return
	Game.run.energy = 0.0
	super.skill_pressed()

func effect() -> void:
	player.combat.revolution()
