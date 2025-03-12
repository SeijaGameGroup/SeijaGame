extends Item

func _ready() -> void:
	ID = 13
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
