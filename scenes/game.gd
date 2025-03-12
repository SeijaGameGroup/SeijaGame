extends Node

const SAVE_PATH := "user://data.sav"

@onready var player_stats: PlayerStats = $PlayerStats

func change_scene(path: String) -> void:
	var tree := get_tree()
	
	tree.change_scene_to_file(path)
	await tree.tree_changed
