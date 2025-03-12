extends Interactable

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var rich_text_label: RichTextLabel = $RichTextLabel

const ScriptPath := "res://items/"

enum ItemType {
	EFFECT,
	ITEM
}

@export var price 	: int
@export var type 	: ItemType
@export var healing 	: float
@export var itemID	: int

func _ready() -> void:
	rich_text_label.text = "%d¢" % price

func interact(player: Player) -> void:
	if Game.player_stats.p_points >= price:
		Game.player_stats.p_points -= price
		effect(player)
		
func effect(player: Player) -> void:
	match type:
		ItemType.EFFECT:
			Game.player_stats.health += healing
		ItemType.ITEM:
			var item = preload("res://items/item.tscn").instantiate() as Item
			var script_path = ScriptPath + "itemID%d.gd" % itemID
			var script = load(script_path)
			item.set_script(script)
			match item.Type:
				Item.ItemType.Passive:
					Game.player_stats.passive_items.append(item)
					
			
