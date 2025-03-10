class_name Player
extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

signal health_changed(health: float)

@export var max_health 		:= 150.0
@export var health			:= max_health :
	set(value):
		health = value
		health_changed.emit(value)	
@export var damage 			:= 6.0
@export var shoot_damage	:= 6.0
@export var firedelay 		:= 0.3
@export var shooting_range	:= 10.0
@export var sub_shoot_cd 	:= 10.0
@export var sub_shoot_num 	:= 6
@export var speed 			:= 6.0
@export var jump_velocity 	:= -700.0
@export var ground_friction := 2000.0
@export var air_friction 	:= 300.0
#@export var acc := 1500

@export var damage_reduction_rate 	:= 0.0
@export var speed_multiplier 		:= 1.0
@export var gravity_multiplier 		:= 1.0
@export var jump_velocity_multipler 	:= 1.0
@export var range_multipler			:= 1.0

@export var damage_item	:= 0.0

@export var range_multipler_item				:= 1.0
@export var dodge_time_multipler_item		:= 1.0
@export var cooldown_multipler_item			:= 1.0
@export var damage_multipler_item			:= 1.0
@export var damage_reduction_rate_item		:= 0.0
@export var speed_multiplier_item			:= 1.0
@export var gravity_multiplier_item 			:= 1.0
@export var jump_velocity_multipler_item 	:= 1.0

var SPEED : float :
	get:
		return speed * 50 * speed_multiplier * speed_multiplier_item

var GRAVITY : float :
	get:
		return gravity * gravity_multiplier * gravity_multiplier_item * (-1 if upside_down else 1)

var JUMP_VELOCITY : float :
	get:
		return jump_velocity * jump_velocity_multipler * jump_velocity_multipler_item * (-1 if upside_down else 1)

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

@onready var shooting_timer 			:= $ShootingTimer
@onready var sub_shooting_timer 		:= $SubShootingTimer
@onready var jump_request_timer 		:= $JumpRequestTimer
@onready var sprite_2d 				:= $Graphics/Sprite2D
@onready var shooting_point 			:= $Graphics/ShootingPoint
@onready var collision_shape_2d 		:= $CollisionShape2D
@onready var graphics 				:= $Graphics
@onready var animation_player 		:= $AnimationPlayer
@onready var animation_tree 			:= $AnimationTree
@onready var hurtbox 				:= $HurtBox
@onready var detected_area			:= $DetectedArea
@onready var interaction_icon		:= $InteractionIcon
@onready var state_machine 			: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var state_machine_normal 	: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Normal/playback")

@export var interacting_with 		: Array[Interactable]
@export var passive_items			: Array[Item]
@export var enemy_tracked			: BaseMonster
@export var is_locking				: bool

# Bullet types for shooting
enum Bullets
{
	NormalBullet,
	TrackedBullet,
}

func _physics_process(delta) -> void:
	
	# Handle Interactable
	interaction_icon.visible = not interacting_with.is_empty()
	
	if operatable:
		# Handle Shoot
		if Input.is_action_just_pressed("enemy_lock"):
			is_locking = true
			enemy_tracking()
		if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
			shoot(Bullets.NormalBullet)
			shooting_timer.start(firedelay)
		if Input.is_action_just_pressed("shoot_sub") and sub_shooting_timer.is_stopped():
			shoot_sub()
			sub_shooting_timer.start(sub_shoot_cd)
		if is_locking and enemy_tracked == null:
			enemy_tracking()

		# Handle Interact
		if Input.is_action_just_pressed("Interact") and not interacting_with.is_empty():
			interacting_with.back().interact(self)

	if movable:
		# Add the gravity.
		# if (gravity < 0 and not is_on_floor()) or (gravity > 0 and not is_on_ceiling()):
		velocity.y += GRAVITY * delta
		
		if operatable:
			var direction = Input.get_axis("move_left", "move_right")
			if IN_AIR:
				if direction:
					velocity.x = SPEED * direction
				else:
					velocity.x = move_toward(velocity.x, 0, air_friction * delta)

			else:
				# Handle Jump
				if CAN_JUMP:
					if Input.is_action_pressed("jump") or not jump_request_timer.is_stopped():
						velocity.y = JUMP_VELOCITY
						state_machine_normal.travel("Jump")
				elif Input.is_action_pressed("jump"):
					jump_request_timer.start(0.1)
					
				if direction:
					velocity.x = SPEED * direction
				else:
					velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
			# Handle graphics
			if not is_zero_approx(velocity.x):
				graphics.scale.x = -1 if velocity.x < 0 else 1
				
		else:
			velocity.x = move_toward(velocity.x, 0, air_friction * delta)

		move_and_slide()


func shoot(bullet:Bullets):
	match bullet:
		Bullets.NormalBullet:
			shoot_normal_bullet()
		Bullets.TrackedBullet:
			pass


func shoot_sub() -> void:
	enemy_tracking()
	if enemy_tracked == null:
		return
	var offset: Vector2
	for i:int in range(sub_shoot_num):
		offset = Vector2(40*cos(PI/2-PI*i/(sub_shoot_num-1)), 40*sin(PI/2-PI*i/(sub_shoot_num-1)))
		var tracked_bullet = preload("res://scenes/bullet/tracked_bullet.tscn").instantiate()
		tracked_bullet.set_bullet(self, enemy_tracked, shooting_point.global_position + offset, 100, shoot_damage, 10)
		get_tree().current_scene.add_child(tracked_bullet)


func enemy_tracking() :
	var enermies_tracked: Array
	for enemy in get_tree().get_nodes_in_group("Monsters"):
		if enemy is BaseMonster:
			enermies_tracked.append(enemy)
	# return the nearest enemy node
	if enermies_tracked.is_empty():
		enemy_tracked = null
	else:
		enermies_tracked.sort_custom(func(a,b):return (self.global_position.\
		distance_squared_to(a.global_position) < self.global_position.distance_squared_to(b.global_position)))
		enemy_tracked = enermies_tracked[0]


func _on_shooting_timer_timeout() -> void:
	if Input.is_action_pressed("shoot"):
		shoot(Bullets.NormalBullet)
		shooting_timer.start(firedelay)


func _on_sub_shooting_timer_timeout() -> void:
	if Input.is_action_pressed("shoot_sub"):
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)


func _on_hurt_box_hurt(hitbox: HitBox) -> void:
	state_machine.travel("Hurt")
	# animation_player_extra.play("HurtEffect")
	
	health -= hitbox.damage


func shoot_normal_bullet():
	var normal_bullet = preload("res://scenes/bullet/normal_bullet.tscn").instantiate()
	if is_locking and not (enemy_tracked == null):
		normal_bullet.set_bullet(self, shooting_point.global_position,\
		shooting_point.global_position.direction_to(enemy_tracked.global_position), 800, shoot_damage, 10)
	else:
		normal_bullet.set_bullet(self, shooting_point.global_position,\
		shooting_point.global_position.direction_to(get_global_mouse_position()), 800, shoot_damage, 10)
	get_tree().current_scene.add_child(normal_bullet)

#func reset_item_effects():
	#damage_item				= 0.0
#
	#dodge_time_multipler	= 1.0
	#cooldown_multipler		= 1.0
	#damage_multipler_item	= 1.0
	#damage_reduction_rate 	= 0.0
	#speed_multiplier 		= 1.0
	#gravity_multiplier 		= 1.0
	#jump_velocity_multipler	= 1.0
