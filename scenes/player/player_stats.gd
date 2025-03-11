class_name PlayerStats

extends Stats

@export var damage_item	:= 0.0

@export var range_multipler_item			:= 1.0
@export var dodge_time_multipler_item		:= 1.0
@export var cooldown_multipler_item			:= 1.0
@export var damage_multipler_item			:= 1.0
@export var damage_reduction_rate_item		:= 0.0
@export var speed_multiplier_item			:= 1.0
@export var gravity_multiplier_item 		:= 1.0
@export var jump_velocity_multipler_item 	:= 1.0

@export var passive_items	: Array[Item]
@export var is_locking		: bool

func _init() -> void:
	max_health = 150.0
	health = 150.0
