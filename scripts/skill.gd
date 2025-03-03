extends Node

@export var cooldown : int
@export var duration : int

@onready var cooldown_timer = $CooldownTimer as Timer
@onready var duration_timer = $DurationTimer as Timer

signal start()
signal end()

var player_operatable : bool = true

var available : bool :
	get:
		return cooldown_timer.is_stopped() and player_operatable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func duration_end():
	end.emit()

func on_player_operatable_changed(value : bool):
	player_operatable = value
