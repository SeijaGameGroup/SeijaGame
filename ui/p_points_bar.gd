extends HBoxContainer

@onready var player_stats = Game.player_stats
@onready var icon: TextureRect = $Icon
@onready var number: Label = $Number

func _ready() -> void:
	player_stats.p_points_changed.connect(func(p_points: int): number.text = "%d" % p_points)
	number.text = "%d" % player_stats.p_points
