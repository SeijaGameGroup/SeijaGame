extends Item

func _ready() -> void:
	ID = 3
	Type = ItemType.Passive
	Name = "伊吹瓢"
	
func effect(player: Player) -> void:
	super(player)
	player.cooldown_multipler -= 0.1
