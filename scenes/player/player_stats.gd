class_name PlayerStats

extends Stats

signal p_points_changed(p_points: int)

const SKILL_PATH = "res://scenes/player/skills/"

var player : Player

@onready var skills: Node = $Skills

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

@export var current_set : ConfigSet
@export var available_skills : Array[Skill]
var player_global_position : Vector2

func _init() -> void:
	pass
