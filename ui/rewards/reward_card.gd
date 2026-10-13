extends Button

@onready var item_icon: TextureRect = $Icon
@onready var item_title: Label = $Title
@onready var category: Label = $Category
@onready var detail: Label = $Description
@onready var hint: Label = $Hint

func present(id: int, index: int) -> void:
	var data: ItemData = ItemCatalog.data(id)
	item_icon.texture = data.icon
	item_title.text = data.title
	category.text = data.category + "  /  构筑"
	detail.text = data.description
	hint.text = "%d  选择   ·   已持有 %d" % [index + 1, Game.run.items.get(id, 0)]
