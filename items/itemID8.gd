extends Item

func _ready() -> void:
	ID = 8
	Type = ItemType.Passive
	Name = "伞"
	
func effect(player: Player) -> void:
	super(player)
	player.gravity_multiplier = 0.5
