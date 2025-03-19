class_name SkillIcon
extends TextureRect

var skill : Skill :
	set(value):
		skill = value
		skill.cooldown_changed.connect(print_cooldown)
		skill.cooldown_timer.timeout.connect(print_cooldown)

@onready var cool_down: RichTextLabel = $CoolDown

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	pass

func print_cooldown(cooldown: int = -1) -> void:
	cool_down.text = "%d" % (cooldown+1) if cooldown >= 0 else ""
