class_name Teleporter
extends Interactable

@export_file("*.tscn") var target_path: String

func interact(player: Player) -> void:
	super(player)
	Game.change_scene(target_path)
