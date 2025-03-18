# base class for all monsters
class_name BaseMonster
extends CharacterBody2D


@export var visible_radius : float = 30.0


func _ready() -> void:
	add_to_group("Monsters")
