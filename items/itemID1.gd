extends Item

func _init() -> void:
	ID = 1
	Type = ItemType.Passive
	Name = "量贩型小麻薯"
	
func effect(player: Player) -> void:
	super(player)
	# todo
