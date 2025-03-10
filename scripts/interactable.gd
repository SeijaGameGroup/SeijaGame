class_name Interactable
extends Area2D

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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

func interact(player: Player) -> void:
	# print("[Interacted] %s => %s" %[player.name, self.name])
	pass
