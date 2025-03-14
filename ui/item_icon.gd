class_name ItemIcon
extends TextureRect

const ITEM_ICON_PATH := "res://assets/pictures/items/"

var has_resource := true
var itemID : int

func _init(itemID: int = 0) -> void:
	self.itemID = itemID
	var img = load(ITEM_ICON_PATH + "itemID%d.png" % itemID)
	if img == null:
		print("no resource")
		return
	self.texture = img
