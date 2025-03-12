extends Item

func _init() -> void:
	ID = 4
	Type = ItemType.Passive
	Name = "御币"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.range_multipler_item += 0.1
