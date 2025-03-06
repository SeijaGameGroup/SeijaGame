class_name Player
extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health : int = 150
@export var damage : float = 6.0
@export var shoot_damage : float = 6.0
@export var firedelay : float = 0.3
@export var sub_shoot_cd : float = 10.0
@export var sub_shoot_num : int = 6
@export var speed : float = 6.0
@export var jump_velocity = -400.0
@export var friction := 2000
#@export var acc := 1500

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

var IN_AIR : bool :
	get:
		return not (is_on_floor() or is_on_ceiling())

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

@onready var shooting_timer 		: Timer 							= $ShootingTimer
@onready var sub_shooting_timer 	: Timer 							= $SubShootingTimer
@onready var jump_request_timer 	: Timer 							= $JumpRequestTimer
@onready var sprite_2d 				: Sprite2D 							= $Graphics/Sprite2D
@onready var shooting_point 		: Node2D							= $Graphics/ShootingPoint
@onready var collision_shape_2d 	: CollisionShape2D					= $CollisionShape2D
@onready var graphics 				: Node2D							= $Graphics
@onready var animation_player 		: AnimationPlayer 					= $AnimationPlayer
@onready var animation_tree 		: AnimationTree						= $AnimationTree
@onready var hurtbox 				: HurtBox							= $HurtBox
@onready var detected_area			: DetectedArea 						= $DetectedArea
@onready var state_machine 			: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var state_machine_normal 	: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Normal/playback")

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
			# Handle Jump
			if CAN_JUMP:
				if Input.is_action_pressed("jump") or not jump_request_timer.is_stopped():
					velocity.y = JUMP_VELOCITY
					state_machine_normal.travel("Jump")
			elif Input.is_action_pressed("jump"):
				jump_request_timer.start(0.1)
			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			var direction = Input.get_axis("move_left", "move_right")
			if direction:
				velocity.x = SPEED * direction
			else:
				velocity.x = move_toward(velocity.x, 0, friction * delta)
			if not is_zero_approx(velocity.x):
				graphics.scale.x = -1 if velocity.x < 0 else 1


		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		move_and_slide()

func shoot() -> void:
	var normal_bullet = preload("res://scenes/bullet/normal_bullet.tscn").instantiate()
	normal_bullet.set_bullet(self, shooting_point.global_position, normal_bullet.position.direction_to(get_global_mouse_position()), 800, shoot_damage, 10)
	get_tree().current_scene.add_child(normal_bullet)


func shoot_sub() -> void:
	var offset: Vector2
	var tracked_enermy = enermy_tracking()
	for i:int in range(sub_shoot_num):
		var tracked_bullet
		offset = Vector2(40*cos(PI/2-PI*i/(sub_shoot_num-1)), 40*sin(PI/2-PI*i/(sub_shoot_num-1)))
		tracked_bullet = preload("res://scenes/bullet/tracked_bullet.tscn").instantiate()
		tracked_bullet.set_bullet(self, tracked_enermy, shooting_point.global_position + offset, 100, shoot_damage, 10)
		get_tree().current_scene.add_child(tracked_bullet)


func enermy_tracking():
	var enermies = get_tree().get_nodes_in_group("Enermies")
	var tracked_enermy
	tracked_enermy = get_tree().get_first_node_in_group("Enermies")
	#print("Tracking: ", tracked_enermy.name)
	return tracked_enermy


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
