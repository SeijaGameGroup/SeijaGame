extends Item

func _init() -> void:
	ID = 9
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
