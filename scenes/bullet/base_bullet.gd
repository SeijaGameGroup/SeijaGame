# base class for all bullets
class_name BaseBullet
extends Sprite2D


var velocity: Vector2
var direction: Vector2
var speed: float
var life: float
var target = null
var shooter = null
var damage: float


func _ready():
	pass

func _process(_delta):
	pass
