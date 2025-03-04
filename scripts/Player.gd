class_name Player
extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health : int = 150
@export var damage : float = 6.0
@export var firedelay : float = 0.3
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
		
var GRAVITY : float : 
	get:
		return gravity * gravity_multiplier * (-1 if upside_down else 1)
		
var JUMP_VELOCITY : float :
	get:
		return jump_velocity * jump_velocity_multipler * (-1 if upside_down else 1)

var CAN_JUMP : bool :
	get:
		return (not upside_down and is_on_floor()) or (upside_down and is_on_ceiling())

@export var movable : bool = true

@export var invincible : bool = false :
	set(value):
		invincible = value
		hurtbox.set_deferred("monitorable", not value)
		
@export var operatable : bool = true

@export var upside_down : bool = false : 
	set(value):
		upside_down = value
		graphics.scale.y = -1 if value else 1

@onready var shooting_timer 	: Timer 	= $ShootingTimer
@onready var sub_shooting_timer : Timer 	= $SubShootingTimer
@onready var jump_request_timer : Timer 	= $JumpRequestTimer
@onready var sprite_2d 			: Sprite2D 	= $Graphics/Sprite2D
@onready var shooting_point = $Graphics/ShootingPoint
@onready var collision_shape_2d = $CollisionShape2D
@onready var graphics = $Graphics
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var hurtbox = $HurtBox
@onready var detected_area = $DetectedArea
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

func _physics_process(delta):
	if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
		shoot()
		shooting_timer.start(firedelay)
	
	if Input.is_action_just_pressed("shoot_sub") and sub_shooting_timer.is_stopped():
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)
	
	if movable:
		# Add the gravity.
		# if (gravity < 0 and not is_on_floor()) or (gravity > 0 and not is_on_ceiling()):
		velocity.y += GRAVITY * delta
		
		if operatable:
			# Handle Jump.addd
			if CAN_JUMP:
				if Input.is_action_just_pressed("jump") or not jump_request_timer.is_stopped():
					velocity.y = JUMP_VELOCITY
			elif Input.is_action_just_pressed("jump"):
				jump_request_timer.start(0.3)

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

func shoot():
	var bullet = preload("res://scenes/bullet.tscn").instantiate()
	bullet.position = shooting_point.global_position
	bullet.velocity = bullet.position.direction_to(get_global_mouse_position())
	get_tree().current_scene.add_child(bullet)
	bullet.damage = self.damage


func shoot_sub():
	var tracked_bullet_array = {}
	for i in range(sub_shoot_num):
		tracked_bullet_array[i] = preload("res://scenes/tracked_bullet.tscn").instantiate()
		tracked_bullet_array[i].position += shooting_point.global_position
		tracked_bullet_array[i].position += Vector2(40*cos(PI/2-PI*i/(sub_shoot_num-1)), 40*sin(PI/2-PI*i/(sub_shoot_num-1)))
		tracked_bullet_array[i].object_tracked = get_node("/root/World/butterfly")
		get_tree().current_scene.add_child(tracked_bullet_array[i])
		tracked_bullet_array[i].damage = self.damage


func _on_shooting_timer_timeout():
	if Input.is_action_pressed("shoot"):
		shoot()
		shooting_timer.start(firedelay)


func _on_sub_shooting_timer_timeout():
	if Input.is_action_pressed("shoot_sub"):
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)


func _on_hurt_box_hurt(_hitbox):
	state_machine.travel("Hurt")
