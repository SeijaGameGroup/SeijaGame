class_name SkillIcon
extends TextureRect

var skill : Skill :
	set(value):
		if skill != null and skill.cooldown_changed.is_connected(print_cooldown):
			skill.cooldown_changed.disconnect(print_cooldown)
		skill = value
		if skill != null:
			skill.cooldown_changed.connect(print_cooldown)

@onready var cool_down: RichTextLabel = $CoolDown

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	pass

func print_cooldown(cooldown: int = -1) -> void:
	if is_instance_valid(cool_down):
		cool_down.text = "%d" % cooldown if cooldown > 0 else ""
