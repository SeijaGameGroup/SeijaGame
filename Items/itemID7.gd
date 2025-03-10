extends Item

func _ready() -> void:
	ID = 7
	Type = ItemType.Passive
	Name = "闪避布"
	
func effect(player: Player) -> void:
	super(player)
	player.dodge_time_multipler_item = 3
