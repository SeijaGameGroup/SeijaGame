class_name StatusPanel
extends HBoxContainer

@export var player: Player

@onready var health_bar := $HealthBar

func _ready() -> void:
	player.health_changed.connect(redrawHealthBar)
	
func redrawHealthBar(health: float):
	var percentage = health / player.max_health
	health_bar.value = percentage
	
