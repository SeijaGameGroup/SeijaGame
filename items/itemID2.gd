extends Item

func _init() -> void:
	ID = 2
	Type = ItemType.Passive
	Name = "魔女扫帚"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.speed_multiplier_item += 0.15
