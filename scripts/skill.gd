class_name Skill
extends Node

@export var cooldown : int
@export var duration : int
@export var request_time := 0.3
@export var player : Player

@onready var cooldown_timer : Timer = $CooldownTimer
@onready var duration_timer : Timer = $DurationTimer 
@onready var request_timer	: Timer = $RequestTimer

var available : bool :
	get:
		return cooldown_timer.is_stopped() and player.operatable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
