extends Item

func _ready() -> void:
	ID = 4
	Type = ItemType.Passive
	Name = "御币"
	
func effect(player: Player) -> void:
	super(player)
	player.range_multipler_item += 0.1
