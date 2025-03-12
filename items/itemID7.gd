extends Item

func _init() -> void:
	ID = 7
	Type = ItemType.Passive
	Name = "闪避布"
	
func effect(player: Player) -> void:
	super(player)
	Game.player_stats.dodge_time_multipler_item = 3
