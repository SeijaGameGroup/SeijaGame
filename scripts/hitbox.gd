class_name HitBox
extends Area2D

@export var damage : float
var damage: float

signal hit(hurtbox:HurtBox)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	var hurtbox = area as HurtBox
	if hurtbox == null:
		return
	# print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	hurtbox.hurt.emit(self)
	hit.emit(hurtbox)
