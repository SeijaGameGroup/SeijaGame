extends VBoxContainer

@onready var grid_container: GridContainer = $GridContainer
@onready var map_base: TextureRect = $MapBase

func add_item(itemID: int):
	var item_icon = preload("res://ui/item_icon.tscn").instantiate()
	item_icon.itemID = itemID
	grid_container.add_child(item_icon)

func _ready() -> void:
	pass
