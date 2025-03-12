class_name Skill
extends Node

@export var cooldown 		: int
@export var duration 		: int
@export var request_time 	:= 0.1
@export var player : Player

var cooldown_timer : Timer
var duration_timer : Timer
var request_timer  : Timer

var available : bool :
	get:
		return cooldown_timer.is_stopped() and player.operatable

func _init() -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)

	duration_timer = Timer.new()
	duration_timer.one_shot = true
	add_child(duration_timer)

	request_timer = Timer.new()
	request_timer.one_shot = true
	add_child(request_timer)

func _process(_delta) -> void:
	pass
