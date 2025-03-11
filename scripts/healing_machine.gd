class_name HealingMachine
extends Interactable

func interact(player: Player) -> void:
	super(player)
	Game.player_stats.health = Game.player_stats.max_health
	queue_free()
