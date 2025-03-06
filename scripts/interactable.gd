class_name Interactable

extends Area2D


func _on_body_entered(body: Node2D) -> void:
	var player = body as Player
	if player == null:
		return
	if not self in player.interacting_with:
		player.interacting_with.append(self)
	


func _on_body_exited(body: Node2D) -> void:
	var player = body as Player
	if player == null:
		return
	player.interacting_with.erase(self)

func interact() -> void:
	pass
