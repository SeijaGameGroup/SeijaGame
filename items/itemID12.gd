extends Item

func _init() -> void:
	ID = 12
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
