extends Item

func _init() -> void:
	ID = 8
	Type = ItemType.Passive
	Name = "伞"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.gravity_multiplier_item = 0.5
