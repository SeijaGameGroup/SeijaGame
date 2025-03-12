class_name Player
extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

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
@export var jump_velocity_multipler := 1.0
@export var range_multipler			:= 1.0

var SPEED : float :
	get:
		return speed * 50 * speed_multiplier * playerstats.speed_multiplier_item

var GRAVITY : float :
	get:
		return gravity * gravity_multiplier * playerstats.gravity_multiplier_item * (-1 if upside_down else 1)

var JUMP_VELOCITY : float :
	get:
		return jump_velocity * jump_velocity_multipler * playerstats.jump_velocity_multipler_item * (-1 if upside_down else 1)

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

@onready var playerstats			: PlayerStats = Game.player_stats
@onready var shooting_timer 		:= $ShootingTimer
@onready var sub_shooting_timer 	:= $SubShootingTimer
@onready var jump_request_timer 	:= $JumpRequestTimer
@onready var sprite_2d 				:= $Graphics/Sprite2D
@onready var shooting_point 		:= $Graphics/ShootingPoint
@onready var collision_shape_2d 	:= $CollisionShape2D
@onready var graphics 				:= $Graphics
@onready var animation_player 		:= $AnimationPlayer
@onready var animation_tree 		:= $AnimationTree
@onready var hurtbox 				:= $HurtBox
@onready var detected_area			:= $DetectedArea
@onready var interaction_icon		:= $InteractionIcon
@onready var state_machine 			: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var state_machine_normal 	: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/Normal/playback")
@onready var visible_detection		: VisibleDetection = $VisibleDetection

@export var interacting_with 		: Array[Interactable]
@export var enemy_tracked			: BaseMonster

@export var bullet_type				: BulletType = BulletType.NormalBullet
@export var bullet_distribution		: DistributionType = DistributionType.None
@export var bullet_num				: int = 1

# Bullet types for shooting
enum BulletType
{
	NormalBullet,
	TrackingBullet,
}

enum DistributionType
{
	None,
	Serial,
	Angular,
	Vertical,
}

func _physics_process(delta) -> void:
	enemy_tracking()
	if Input.is_action_just_pressed("enemy_lock"):
		playerstats.is_locking = not is_locking

	# Handle Interactable
	interaction_icon.visible = not interacting_with.is_empty()
	
	if operatable:
		# Handle Shoot
		if Input.is_action_just_pressed("shoot") and shooting_timer.is_stopped():
			shoot(BulletType.NormalBullet, bullet_distribution, bullet_num)
			if bullet_distribution == DistributionType.Serial:
				shooting_timer.start(firedelay * bullet_num)
			else:
				shooting_timer.start(firedelay)
		if Input.is_action_just_pressed("shoot_sub") and sub_shooting_timer.is_stopped():
			shoot_sub()
			sub_shooting_timer.start(sub_shoot_cd)

		# Handle Interact
		if Input.is_action_just_pressed("Interact") and not interacting_with.is_empty():
			interacting_with.back().interact(self)
		# Test
		if Input.is_action_just_pressed("TestButton"):
			get_tree().call_group("Bullets", &"duplicate_bullet")

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


func shoot(bullet:BulletType, distribution:DistributionType = DistributionType.None, num:int = 1, par1:float = -1, par2:float = -1):
	match bullet:
		BulletType.NormalBullet:
			match distribution:
				DistributionType.None:
					shoot_normal_bullet()
				DistributionType.Serial:
					shoot_normal_bullet()
					if num > 1:
						var fire_delay:float = firedelay if par1 == -1 else par1
						for i:int in range(0, num-1):
							await get_tree().create_timer(fire_delay).timeout
							shoot_normal_bullet()
				DistributionType.Angular:
					if num == 1:
						shoot_normal_bullet()
					elif num > 1:
						var angle_to_enemy: float
						if enemy_tracked == null:
							angle_to_enemy = PI/48
						else:
							angle_to_enemy = asin(enemy_tracked.visible_radius / (global_position.distance_to(enemy_tracked.global_position)))
						var fire_angle:float = clamp(2*angle_to_enemy,0,PI*2/3) if par1==-1 else par1
						var angle_offset = fire_angle
						for i:int in range(0,num):
							shoot_normal_bullet(Vector2.ZERO,angle_offset)
							angle_offset -= fire_angle/(num-1)

				DistributionType.Vertical:
					if num == 1:
						shoot_normal_bullet()
					elif num > 1:
						var v_distance:float = 50 if par1 == -1 else par1
						var v_offset = Vector2(v_distance,0)
						var fire_rotation:float
						if par2 == -1:
							if enemy_tracked == null:
								var direction_to_mouse:Vector2 = shooting_point.global_position.direction_to(get_global_mouse_position())
								fire_rotation = direction_to_mouse.orthogonal().angle()
							else:
								var direction_to_enemy = shooting_point.global_position.direction_to(enemy_tracked.global_position)
								fire_rotation = direction_to_enemy.orthogonal().angle()
						else:
							fire_rotation = par2
						v_offset = v_offset.rotated(fire_rotation)
						var bullet_offset = v_offset
						for i:int in range(0,num):
							shoot_normal_bullet(bullet_offset,0)
							bullet_offset -= v_offset/(num-1)


		BulletType.TrackingBullet:
			pass


func shoot_sub() -> void:
	if enemy_tracked == null:
		return
	var offset: Vector2
	for i:int in range(sub_shoot_num):
		offset = Vector2(40*cos(PI/2-PI*i/(sub_shoot_num-1)), 40*sin(PI/2-PI*i/(sub_shoot_num-1)))
		var tracking_bullet = preload("res://scenes/bullet/tracking_bullet.tscn").instantiate()
		tracking_bullet.set_bullet(shooting_point.global_position + offset,\
		Vector2.ZERO, 200, 10, enemy_tracked, self, shoot_damage)
		get_tree().current_scene.add_child(tracking_bullet)



func enemy_tracking() -> void:
	var enermies_tracked: Array[BaseMonster]
	for enemy in get_tree().get_nodes_in_group("Monsters"):
		if enemy is BaseMonster:
			enermies_tracked.append(enemy)
	# return the nearest enemy node
	if enermies_tracked.is_empty():
		enemy_tracked = null
	else:
		enermies_tracked.sort_custom(func(a,b):return (self.global_position.\
		distance_squared_to(a.global_position) < self.global_position.distance_squared_to(b.global_position)))
		for i:int in range(0,enermies_tracked.size()):
			if visible_detection.visible_detect(enermies_tracked[i], enermies_tracked[i].visible_radius):
				enemy_tracked = enermies_tracked[i]
				break
		enemy_tracked == null


func _on_shooting_timer_timeout() -> void:
	if Input.is_action_pressed("shoot"):
		shoot(BulletType.NormalBullet, bullet_distribution, bullet_num)
		shooting_timer.start(firedelay)


func _on_sub_shooting_timer_timeout() -> void:
	if Input.is_action_pressed("shoot_sub"):
		shoot_sub()
		sub_shooting_timer.start(sub_shoot_cd)


func _on_hurt_box_hurt(hitbox: HitBox) -> void:
	state_machine.travel("Hurt")
	# animation_player_extra.play("HurtEffect")
	
	playerstats.health -= hitbox.damage


func shoot_normal_bullet(position_offset:Vector2 = Vector2.ZERO, angle_offset:float = 0):
	var normal_bullet = preload("res://scenes/bullet/normal_bullet.tscn").instantiate()
	if playerstats.is_locking and not (enemy_tracked == null):
		var direction_to_enemy:Vector2 = shooting_point.global_position.direction_to(enemy_tracked.global_position)
		normal_bullet.set_bullet(shooting_point.global_position + position_offset ,\
		direction_to_enemy.rotated(angle_offset), 800, 10, enemy_tracked, self, shoot_damage)
	else:
		var direction_to_mouse:Vector2 = shooting_point.global_position.direction_to(get_global_mouse_position())
		normal_bullet.set_bullet(shooting_point.global_position + position_offset ,\
		direction_to_mouse.rotated(angle_offset), 800, 10, null, self, shoot_damage)
	get_tree().current_scene.add_child(normal_bullet)

#func reset_item_effects():
	#damage_item				= 0.0

	#dodge_time_multipler		= 1.0
	#cooldown_multipler			= 1.0
	#damage_multipler_item		= 1.0
	#damage_reduction_rate 		= 0.0
	#speed_multiplier 			= 1.0
	#gravity_multiplier 		= 1.0
	#jump_velocity_multipler	= 1.0
