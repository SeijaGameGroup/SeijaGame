extends Control

@onready var button: Button = $Button

func start_game() -> void:
	Game.change_scene("res://scenes/maps/regular_level1.tscn")

func _ready() -> void:
	button.grab_focus()
