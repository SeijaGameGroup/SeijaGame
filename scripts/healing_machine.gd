class_name HealingMachine
extends Interactable

func interact(player: Player) -> void:
	super(player)
	player.health = player.max_health
	queue_free()
