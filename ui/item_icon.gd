class_name ItemIcon
extends TextureRect

const ITEM_ICON_PATH := "res://assets/pictures/items/"

@onready var id: RichTextLabel = $ID

var has_resource := true
var itemID : int :
	set(value):
		itemID = value
		var img = load(ITEM_ICON_PATH + "itemID%d.png" % itemID)
		if img == null and id == null:
			await ready
			id.text = "itemID%d" % itemID
		else:
			texture = img
