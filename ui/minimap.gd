extends SubViewport

var player : Player = Game.player_stats.player
@onready var camera_2d: Camera2D = $Camera2D

func _ready() -> void:
	world_2d = get_tree().root.world_2d

func _process(delta: float) -> void:
	camera_2d.position = player.position
