extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health : int = 150
@export var damage : float = 6.0
@export var tears : float = 0.3
@export var sub_shoot_cd : float = 10.0
@export var sub_shoot_num : int = 6
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
		upside_down = value
		graphics.scale.y = -1 if value else 1

@onready var shooting_timer = $ShootingTimer
@onready var sub_shooting_timer = $SubShootingTimer
@onready var sprite_2d = $Graphics/Sprite2D
@onready var shooting_point = $Graphics/ShootingPoint
@onready var collision_shape_2d = $CollisionShape2D
@onready var graphics = $Graphics


func _physics_process(delta):
	if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
		shoot()
		shooting_timer.start(tears)
	
	if Input.is_action_just_pressed("shoot_sub") and sub_shooting_timer.is_stopped():
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)
	
	if movable:
		# Add the gravity.
		# if (gravity < 0 and not is_on_floor()) or (gravity > 0 and not is_on_ceiling()):
		velocity.y += GRAVITY * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump"):
			if ((not upside_down) and is_on_floor()) or (upside_down and is_on_ceiling()):
				velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED			
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		if not is_zero_approx(velocity.x):
			graphics.scale.x = -1 if velocity.x < 0 else 1
		
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


func shoot_sub():
	var tracked_bullet_array = {}
	for i in range(sub_shoot_num):
		tracked_bullet_array[i] = preload("res://tracked_bullet.tscn").instantiate()
		tracked_bullet_array[i].position += shooting_point.global_position
		tracked_bullet_array[i].position += Vector2(40*cos(PI/2-PI*i/(sub_shoot_num-1)), 40*sin(PI/2-PI*i/(sub_shoot_num-1)))
		tracked_bullet_array[i].object_tracked = get_node("/root/World/butterfly")
		get_tree().current_scene.add_child(tracked_bullet_array[i])
		tracked_bullet_array[i].damage = self.damage



func _on_shooting_timer_timeout():
	if Input.is_action_pressed("shoot"):
		shoot()
		shooting_timer.start(tears)
	pass


func _on_sub_shooting_timer_timeout():
	if Input.is_action_pressed("shoot_sub"):
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)
	pass
