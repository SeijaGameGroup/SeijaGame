extends HBoxContainer

@onready var shooting_config: TextureRect = $ShootingConfig

@onready var skill_icon_1: SkillIcon = $SkillIcon1
@onready var skill_icon_2: SkillIcon = $SkillIcon2
@onready var skill_icon_3: SkillIcon = $SkillIcon3

func _ready() -> void:
	skill_icon_1.skill = Game.player_stats.current_set.skill_slot1
	skill_icon_2.skill = Game.player_stats.current_set.skill_slot2
	skill_icon_3.skill = Game.player_stats.current_set.skill_slot3
