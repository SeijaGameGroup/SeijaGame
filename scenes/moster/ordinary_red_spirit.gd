extends BaseMonster

@onready var graphics			: Node2D = $Graphics
@onready var detecting_area		: DetectingArea = $DetectingArea
@onready var hurtbox			: HurtBox = $HurtBox
@onready var hitbox			: HitBox = $HitBox
@onready var animation_tree		: AnimationTree = $AnimationTree
@onready var animation_player	: AnimationPlayer = $AnimationPlayer
@onready var stats				: Stats = $Stats
@onready var visible_detection	: Node2D = $VisibleDetection
@onready var state_machine 		: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var floor_detection_ray: RayCast2D = $FloorDetectionRay
@onready var wandering_timer	: Timer = $WanderingTimer
@onready var shooting_timer		: Timer = $ShootingTimer
@onready var shooting_point		: Node2D = $Graphics/ShootingPoint

@export var shoot_cooldown		: float = 2.0
@export var shoot_damage		: int = 8
@export var shoot_num			: int = 4
@export var bullet_speed		: float = 200

@export var knockback_acc 		: float = 50
@export var acc					: float = 10
@export var WANDERING_SPEED		: float = 20

@export var detected_enemies	: Array = []
@export var visible_enemies 	: Array = []
@export var enemy				: Node
@export var current_state		: State = State.Wandering
@export var next_state 			: State
@export var velocity_target		: Vector2


enum State{
	Idle,
	Wandering,
	Shooting,
}

func _ready() -> void:
	super()
	stats.max_health = 40.0
	stats.health = 40.0


func _physics_process(delta: float) -> void:
	# Handle Searching Enemy
	get_enemy()
	var direction_to_enemy:Vector2
	if enemy and enemy is Node2D:
		direction_to_enemy = self.global_position.direction_to(enemy.global_position)

	# Handle State Behavior and Transition
	match current_state:
		State.Idle:
			velocity = Vector2.ZERO
			next_state = State.Idle
		State.Wandering:
			velocity = velocity.move_toward(velocity_target, acc)
			if wandering_timer.is_stopped():
				wandering_timer.start()
				velocity_target = Vector2(WANDERING_SPEED,0).rotated(randf_range(0,TAU))
			if floor_detection_ray.is_colliding():
				if velocity.y > 0:
					velocity_target.y = - velocity_target.y
			if not enemy == null:
				next_state = State.Shooting
			else:
				next_state = State.Wandering
		State.Shooting:
			velocity = velocity.move_toward(Vector2.ZERO, acc)
			if enemy == null:
				next_state = State.Wandering
			else:
				if shooting_timer.is_stopped():
					shoot_angular(direction_to_enemy, shoot_num, bullet_speed, shoot_damage)
					shooting_timer.start(shoot_cooldown)
				next_state = State.Shooting

	# Handle Transition Behavior
	if not current_state == next_state:
		# Handle Exit Behavior
		match current_state:
			State.Idle:
				pass
			State.Wandering:
				wandering_timer.stop()
			State.Shooting:
				pass
		# Handle Entering Behavior
		match next_state:
			State.Idle:
				pass
			State.Wandering:
				wandering_timer.start()
				velocity_target = Vector2(WANDERING_SPEED,0).rotated(randf_range(0,TAU))
				state_machine.travel("wandering")
			State.Shooting:
				state_machine.travel("shooting")

		current_state = next_state

	if enemy:
		graphics.scale.x = -1 if direction_to_enemy.x > 0 else 1
	elif not is_zero_approx(velocity.x):
		graphics.scale.x = -1 if velocity.x > 0 else 1
	move_and_slide()


func shoot_angular(direction:Vector2, num:int, speed:float, damage:float) -> void:
	if enemy == null:
		return
	else:
		var fire_angle:float = PI*2/3
		var angle_offset = fire_angle/2
		for i:int in range(0,num):
			var normal_bullet = preload("res://scenes/bullet/normal_bullet.tscn").instantiate()
			normal_bullet.set_bullet(shooting_point.global_position ,\
			direction.rotated(angle_offset), speed, 10, enemy, self, damage)
			get_tree().current_scene.add_child(normal_bullet)
			angle_offset -= fire_angle/(num-1)


func get_enemy() -> void:
	for enemy in detected_enemies:
		if visible_detection.visible_detect(enemy, 15):
			if not visible_enemies.has(enemy):
				visible_enemies.append(enemy)
		elif visible_enemies.has(enemy):
			visible_enemies.erase(enemy)
	visible_enemies.erase(null)
	if not visible_enemies.is_empty():
		enemy = visible_enemies.front()
	else:
		enemy = null


func hurt(hitbox: HitBox):
	var acc = hitbox.global_position.direction_to(hurtbox.global_position) * knockback_acc
	velocity += acc
	stats.health -= hitbox.damage


func enemy_detected(detected_area: DetectedArea):
	if not detected_enemies.has(detected_area.owner):
		detected_enemies.append(detected_area.owner)


func enemy_lost(detected_area: DetectedArea):
	if detected_enemies.has(detected_area.owner):
		detected_enemies.erase(detected_area.owner)
		visible_enemies.erase(detected_area.owner)


func die() -> void:
	var n_points = randi_range(8, 12)
	for i in range(n_points):
		var p_point = preload("res://scenes/utilities/p_point.tscn").instantiate()
		p_point.global_position = global_position
		get_tree().current_scene.add_child(p_point)
	queue_free()
