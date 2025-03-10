extends Item

func _ready() -> void:
	ID = 9
	Type = ItemType.Passive
	Name = ""
	
func effect(player: Player) -> void:
	super(player)
	# todo
