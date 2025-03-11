extends Item

func _ready() -> void:
	ID = 5
	Type = ItemType.Passive
	Name = "子安贝"
	
func effect(player: Player) -> void:
	super(player)
	player.damage_reduction_rate_item += 0.05
