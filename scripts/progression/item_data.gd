class_name ItemData
extends Resource

@export var id: int = 1
@export var title: String = ""
@export_multiline var description: String = ""
@export var category: String = ""
@export_range(1, 99) var price: int = 25
@export var icon: Texture2D
@export_group("Stack bonuses")
@export var health_bonus: float = 0.0
@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var reduction_bonus: float = 0.0
@export var guard_bonus: float = 0.0
@export var gravity_reduction: float = 0.0
@export var extra_shot: float = 0.0
@export var inversion_bonus: float = 0.0
@export var pierce: int = 0
@export var kill_heal: float = 0.0
@export var reflection_bonus: float = 0.0
@export var side_shots: int = 0
@export var energy_bonus: float = 0.0
