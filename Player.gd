extends CharacterBody2D

const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health : int = 150
@export var damage : float = 6
@export var tears : float = 0.3
@export var speed : float = 6
@export var damage_reduction_rate : float = 0

var SPEED : int :
	get:
		return int(speed * 50)
		
var movable : bool = true

@onready var shooting_timer = $ShootingTimer
@onready var shooting_point = $ShootingPoint

func _physics_process(delta):
	if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
		shoot()
		shooting_timer.start(tears)
	if movable:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		move_and_slide()

func dodge_start():
	movable = false

func dodge_end():
	movable = true

func shoot():
	var bullet = preload("res://bullet.tscn").instantiate()
	bullet.position = shooting_point.global_position
	bullet.velocity = bullet.position.direction_to(get_global_mouse_position())
	get_tree().current_scene.add_child(bullet)

func _on_shooting_timer_timeout():
	if Input.is_action_pressed("shoot"):
		shoot()
		shooting_timer.start(tears)
	pass # Replace with function body.
