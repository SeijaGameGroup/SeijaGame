class_name Item
extends Node

enum ItemType {
	Active,
	Passive,
}

@export var ID			: int
@export var Type			: ItemType
@export var Name			: StringName
@export var Description	: StringName

func effect(player:Player) -> void:
	pass
