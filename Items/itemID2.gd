extends Item

func _ready() -> void:
	ID = 2
	Type = ItemType.Passive
	Name = "魔女扫帚"
	
func effect(player: Player) -> void:
	super(player)
	player.speed_multiplier_item += 0.15
