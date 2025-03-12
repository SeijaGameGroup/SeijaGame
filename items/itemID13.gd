extends Item

func _init() -> void:
	ID = 13
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
