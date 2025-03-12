class_name StatusPanel
extends VBoxContainer

@export var player_stats : PlayerStats

@onready var health_bar := $StatusBar/HealthBar
@onready var number: Label = $P_PointsBar/Number

func _ready() -> void:
	if not player_stats:
		player_stats = Game.player_stats
	player_stats.health_changed.connect(redrawHealthBar)
	redrawHealthBar()
	player_stats.p_points_changed.connect(func(p_points: int): number.text = "%d" % p_points)
	number.text = "%d" % player_stats.p_points
	
func redrawHealthBar():
	var percentage = player_stats.health / player_stats.max_health
	health_bar.value = percentage
