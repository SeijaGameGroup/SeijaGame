extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health : int = 150
@export var damage : float = 6
@export var tears : float = 0.3
@export var speed : float = 6
@export var jump_velocity = -400.0

@export var damage_reduction_rate : float = 0
@export var speed_multiplier : float = 1
@export var gravity_multiplier : float = 1
@export var jump_velocity_multipler : float = 1

var SPEED : int :
	get:
		return int(speed * 50 * speed_multiplier)
		
var GRAVITY : 
	get:
		return gravity * gravity_multiplier * (-1 if upside_down else 1)
		
var JUMP_VELOCITY :
	get:
		return jump_velocity * jump_velocity_multipler * (-1 if upside_down else 1)

var movable : bool = true

var upside_down : bool = false : 
	set(value):
		sprite_2d.flip_v = value
		upside_down = value

@onready var shooting_timer = $ShootingTimer
@onready var shooting_point = $ShootingPoint
@onready var sprite_2d = $Sprite2D
@onready var collision_shape_2d = $CollisionShape2D

func _physics_process(delta):
	if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
		shoot()
		shooting_timer.start(tears)
	if movable:
		# Add the gravity.
		# if (gravity < 0 and not is_on_floor()) or (gravity > 0 and not is_on_ceiling()):
		velocity.y += GRAVITY * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump"):
			if (JUMP_VELOCITY < 0 and is_on_floor()) or (JUMP_VELOCITY > 0 and is_on_ceiling()):
				velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED			
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		if not is_zero_approx(velocity.x):
			sprite_2d.flip_h = velocity.x < 0
		
		move_and_slide()

func dodge_start():
	movable = false

func dodge_end():
	movable = true
	
func skill2_start():
	upside_down = true
	speed_multiplier = 1.5

func skill2_end():
	upside_down = false
	speed_multiplier = 1

func shoot():
	var bullet = preload("res://bullet.tscn").instantiate()
	bullet.position = shooting_point.global_position
	bullet.velocity = bullet.position.direction_to(get_global_mouse_position())
	get_tree().current_scene.add_child(bullet)
	bullet.damage = self.damage

func _on_shooting_timer_timeout():
	if Input.is_action_pressed("shoot"):
		shoot()
		shooting_timer.start(tears)
	pass # Replace with function body.
