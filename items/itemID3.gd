extends Item

func _init() -> void:
	ID = 3
	Type = ItemType.Passive
	Name = "伊吹瓢"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.cooldown_multipler_item -= 0.1
