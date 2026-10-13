class_name ItemCatalog
extends RefCounted

const IDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const ITEMS: Array[ItemData] = [
	preload("res://resources/items/item_01.tres"),
	preload("res://resources/items/item_02.tres"),
	preload("res://resources/items/item_03.tres"),
	preload("res://resources/items/item_04.tres"),
	preload("res://resources/items/item_05.tres"),
	preload("res://resources/items/item_06.tres"),
	preload("res://resources/items/item_07.tres"),
	preload("res://resources/items/item_08.tres"),
	preload("res://resources/items/item_09.tres"),
	preload("res://resources/items/item_10.tres"),
	preload("res://resources/items/item_11.tres"),
	preload("res://resources/items/item_12.tres"),
	preload("res://resources/items/item_13.tres"),
]
static func data(id: int) -> ItemData:
	return ITEMS[id - 1] if id >= 1 and id <= ITEMS.size() else null
static func title(id: int) -> String:
	var item: ItemData = data(id)
	return item.title if item != null else "未知道具"
static func description(id: int) -> String:
	var item: ItemData = data(id)
	return item.description if item != null else ""
static func icon(id: int) -> Texture2D:
	var item: ItemData = data(id)
	return item.icon if item != null else null
