class_name PlayerStats

extends Stats

signal p_points_changed(p_points: int)

const SKILL_PATH = "res://scenes/player/skills/"

@export var player : Player

@export var damage_item	:= 0.0

@export var range_multipler_item			:= 1.0
@export var dodge_time_multipler_item		:= 1.0
@export var cooldown_multipler_item			:= 1.0
@export var damage_multipler_item			:= 1.0
@export var damage_reduction_rate_item		:= 0.0
@export var speed_multiplier_item			:= 1.0
@export var gravity_multiplier_item 		:= 1.0
@export var jump_velocity_multipler_item 	:= 1.0

@export var p_points		:= 0 :
	set(value):
		p_points = value
		p_points_changed.emit(value)
@export var passive_items	: Array[Item]
@export var is_locking		: bool

@export var skills : Array[Skill]

class Set:
	var bullet_type : Player.BulletType
	var skill_slot1 : Skill
	var skill_slot2 : Skill
	var skill_slot3 : Skill
	
var set1 : Set
var set2 : Set
var current_set : Set
var player_global_position : Vector2

func _init() -> void:
	max_health = 150.0
	health = 150.0
	for i in range(0, 3):
		var skill = Skill.new()
		var script = load(SKILL_PATH + "skillID%d.gd" % (i+1))
		skill.set_script(script)
		skills.append(skill)
	set1 = Set.new()
	set1.bullet_type = Player.BulletType.NormalBullet
	set1.skill_slot1 = skills[0]
	set1.skill_slot2 = skills[1]
	set1.skill_slot3 = skills[2]
	current_set = set1
		
