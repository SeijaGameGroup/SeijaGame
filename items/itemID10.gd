extends Item

func _init() -> void:
	ID = 10
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
