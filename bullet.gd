extends Sprite2D

var velocity : Vector2
@export var speed = 800
@export var life = 10

@onready var timer = $Timer
@onready var hitbox = $HitBox as HitBox
@onready var damage:
	set(value):
		hitbox.damage = value
		

# Called when the node enters the scene tree for the first time.
func _ready():
	velocity *= speed
	timer.start(life)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += velocity * delta
	pass


func _on_timer_timeout():
	queue_free()
	pass # Replace with function body.

func hit(hurtbox: HurtBox):
	queue_free()
