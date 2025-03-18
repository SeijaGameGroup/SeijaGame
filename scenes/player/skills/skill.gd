class_name Skill
extends Node

@export var id				: int
@export var cooldown 		: float
@export var duration 		: float
@export var Name				: StringName
@export var description		: StringName
@export var cancelable		: bool

var player : Player:
	get:
		return Game.player_stats.player

var cooldown_timer : Timer
var duration_timer : Timer

var previous_cooldown : int = 0
signal cooldown_changed(cooldown: int)

var available : bool :
	get:
		if not cooldown_timer:
			await ready
		return cooldown_timer.is_stopped()

func _init(player : Player = null) -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)

	duration_timer = Timer.new()
	duration_timer.one_shot = true
	add_child(duration_timer)
	
	duration_timer.timeout.connect(deffect)

func _process(delta: float) -> void:
	if not cooldown_timer.is_stopped():
		var current_cooldown = int(cooldown_timer.time_left)
		if current_cooldown != previous_cooldown:
			cooldown_changed.emit(current_cooldown)
			previous_cooldown = current_cooldown

func skill_pressed() -> void:
	print(cancelable)
	print(duration_timer.is_stopped())
	if cancelable and not duration_timer.is_stopped():
		cancel()
	cooldown_timer.start(cooldown)
	duration_timer.start(duration)
	effect()
	
func effect() -> void:
	pass
	
func deffect() -> void:
	pass

func cancel() -> void:
	duration_timer.stop()
	deffect()
