extends Item

func _init() -> void:
	ID = 5
	Type = ItemType.Passive
	Name = "子安贝"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.damage_reduction_rate_item += 0.05
