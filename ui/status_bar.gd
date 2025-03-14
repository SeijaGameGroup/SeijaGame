extends HBoxContainer

@onready var health_bar := $HealthBar
@onready var player_stats = Game.player_stats

func _ready() -> void:
	player_stats.health_changed.connect(redrawHealthBar)
	redrawHealthBar()
	
func redrawHealthBar():
	var percentage = player_stats.health / player_stats.max_health
	health_bar.value = percentage
