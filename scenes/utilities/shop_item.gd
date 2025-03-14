extends Interactable

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var rich_text_label: RichTextLabel = $RichTextLabel

const ScriptPath := "res://items/"

enum ItemType {
	EFFECT,
	ITEM
}

@export var random_item : bool = true

@export var price 	: int
@export var type 	: ItemType
@export var healing 	: float
@export var itemID	: int
	
func _ready() -> void:
	if random_item and type == ItemType.ITEM:
		itemID = randi_range(1, 5)
	rich_text_label.text = "%d¢" % price

func interact(player: Player) -> void:
	if Game.player_stats.p_points >= price:
		Game.player_stats.p_points -= price
		effect(player)
		if random_item and type == ItemType.ITEM:
			itemID = randi_range(1, 5)
		
func effect(player: Player) -> void:
	match type:
		ItemType.EFFECT:
			Game.player_stats.health += healing
		ItemType.ITEM:
			var item = preload("res://items/item.tscn").instantiate() as Item
			var script_path = ScriptPath + "itemID%d.gd" % itemID
			var script = load(script_path)
			item.set_script(script)
			player.add_item(itemID)
			match item.Type:
				Item.ItemType.Passive:
					Game.player_stats.passive_items.append(item)
					
			
