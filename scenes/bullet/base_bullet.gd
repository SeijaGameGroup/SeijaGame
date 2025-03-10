# base class for all bullets
class_name BaseBullet
extends Sprite2D


@export var velocity: Vector2
@export var direction: Vector2
@export var speed: float
@export var life: float
@export var target: Node
@export var shooter: Node
@export var damage: float


func _ready():
	pass

func _process(_delta):
	pass

func set_bullet(Position:Vector2, Direction:Vector2, Speed:float, Life:float, Target:Node, Shooter:Node, Damage:float) -> void:
	position = Position
	direction = Direction.normalized()
	speed = Speed
	life = Life
	target = Target
	shooter = Shooter
	damage = Damage
	rotation = direction.angle()


func duplicate_bullet(distance:float = 50.0) -> void:
	var new_bullet = duplicate()
	position += Vector2(distance/2, 0).rotated(direction.orthogonal().angle())
	new_bullet.position -= Vector2(distance/2, 0).rotated(direction.orthogonal().angle())
	get_tree().current_scene.add_child(new_bullet)
