class_name StatusPanel
extends HBoxContainer

@export var player_stats : Stats

@onready var health_bar := $HealthBar

func _ready() -> void:
	if not player_stats:
		player_stats = Game.player_stats
	player_stats.health_changed.connect(redrawHealthBar)
	redrawHealthBar()

func redrawHealthBar():
	var percentage = player_stats.health / player_stats.max_health
	health_bar.value = percentage
