extends CanvasLayer

const SAVE_PATH := "user://data.sav"

@onready var player_stats: PlayerStats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect

func change_scene(path: String) -> void:
	var tree := get_tree()

	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1, 0.5)
	await tween.finished
	
	tree.change_scene_to_file(path)
	await tree.tree_changed

	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0, 0.5)
