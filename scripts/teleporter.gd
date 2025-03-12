class_name Teleporter
extends Interactable

@export_file("*.tscn") var target_path: String

func interact(player: Player) -> void:
	super(player)
	get_tree().change_scene_to_file(target_path)
