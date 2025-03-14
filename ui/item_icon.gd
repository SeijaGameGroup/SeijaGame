class_name ItemIcon
extends TextureRect

const ITEM_ICON_PATH := "res://assets/pictures/items/"

var has_resource := true
var itemID : int

func _init(itemID: int = 0) -> void:
	self.itemID = itemID
	var img = Image.load_from_file(ITEM_ICON_PATH + "itemID%d.png" % itemID)
	if img == null:
		has_resource = false
		return
	texture = ImageTexture.new()
	texture = texture.create_from_image(img)
