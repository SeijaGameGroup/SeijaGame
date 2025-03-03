class_name HitBox
extends Area2D

var damage : float

signal hit(hurtbox)

# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(_on_area_entered)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_area_entered(area: Area2D):
	var hurtbox = area as HurtBox
	if hurtbox:
		print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
		hurtbox.hurt.emit(self)
		hit.emit(hurtbox)
