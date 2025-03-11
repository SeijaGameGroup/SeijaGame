extends Item

func _ready() -> void:
	ID = 6
	Type = ItemType.Passive
	Name = "编号06"
	
func effect(player: Player) -> void:
	super(player)
	# todo
