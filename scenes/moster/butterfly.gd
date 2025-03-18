extends BaseMonster

@onready var stats 				:= $Stats
@onready var hitbox				:= $HitBox
@onready var hurtbox 			:= $HurtBox
@onready var animation_player 	:= $AnimationPlayer
@onready var animation_tree 	:= $AnimationTree
@onready var graphics			:= $Graphics
@onready var state_machine 		: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var visible_detection	: Node2D = $VisibleDetection
@onready var collision_detection: Area2D = $CollisionDetection
@onready var floor_detection_ray: RayCast2D = $FloorDetectionRay
@onready var path_finding_ray	: RayCast2D = $PathFindingRay
@onready var wandering_timer	: Timer = $WanderingTimer
@onready var detecting_timer	: Timer = $DetectingTimer

@export var knockback_impulse 	: float = 50
@export var chasing_acc			: float = 600
@export var WANDERING_SPEED 	: float = 40
@export var CHASING_SPEED 		: float = 200
@export var damage 				: float = 15.0 :
	set(value):
		damage = value
		hitbox.damage = value
@export var detecting_time	:= 0.3
@export var flying_height	:= 100

@export var detected_enemies	: Array = []
@export var visible_enemies 	: Array = []
@export var enemy				: Node
@export var current_state		: State = State.Wandering
@export var next_state 			: State
@export var velocity_target		: Vector2
@export var end_chasing			: bool = false

enum State{
	Idle,
	Wandering,
	Detecting,
	Chasing,
	Adjusting,
}


func _ready() -> void:
	super()
	current_state = State.Wandering
	stats.max_health = 60.0
	stats.health = 60.0


func _physics_process(_delta):
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
			velocity = velocity.move_toward(velocity_target, chasing_acc * _delta)
			if wandering_timer.is_stopped():
				wandering_timer.start()
				velocity_target = Vector2(WANDERING_SPEED,0).rotated(randf_range(0,TAU))
			if floor_detection_ray.is_colliding():
				if velocity.y > 0:
					velocity_target.y = - velocity_target.y
			if not enemy == null:
				next_state = State.Detecting
			else:
				next_state = State.Wandering
		State.Detecting:
			velocity = velocity.move_toward(Vector2.ZERO,chasing_acc * _delta)
			if enemy == null:
				next_state = State.Wandering
			elif detecting_timer.is_stopped():
				next_state = State.Chasing
			else:
				next_state = State.Detecting
		State.Chasing:
			if enemy == null:
				next_state = State.Wandering
			else:
				velocity = velocity.move_toward(direction_to_enemy * CHASING_SPEED, chasing_acc * _delta)
				next_state = State.Chasing
		State.Adjusting:
			if enemy == null:
				next_state = State.Wandering
			else:
				velocity = velocity.move_toward(- direction_to_enemy * CHASING_SPEED, chasing_acc * _delta)
				var distance_to_enemy = self.global_position.distance_to(enemy.global_position)
				if distance_to_enemy > 300:
					next_state = State.Chasing
				else:
					next_state = State.Adjusting
	if end_chasing:
		next_state = State.Adjusting
		end_chasing = false

	# Handle Transition Behavior
	if not current_state == next_state:
		# Handle Exit Behavior
		match current_state:
			State.Idle:
				pass
			State.Wandering:
				wandering_timer.stop()
			State.Detecting:
				detecting_timer.stop()
			State.Chasing:
				pass
			State.Adjusting:
				pass
		# Handle Entering Behavior
		match next_state:
			State.Idle:
				pass
			State.Wandering:
				wandering_timer.start()
				velocity_target = Vector2(WANDERING_SPEED,0).rotated(randf_range(0,TAU))
				state_machine.travel("wandering")
			State.Detecting:
				detecting_timer.start()
				state_machine.travel("detecting")
			State.Chasing:
				state_machine.travel("chasing")
			State.Adjusting:
				state_machine.travel("adjusting")

		current_state = next_state

	if enemy:
		graphics.scale.x = -1 if direction_to_enemy.x > 0 else 1
	elif not is_zero_approx(velocity.x):
		graphics.scale.x = -1 if velocity.x > 0 else 1
	move_and_slide()


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
	var acc = hitbox.global_position.direction_to(hurtbox.global_position) * knockback_impulse
	velocity += acc
	stats.health -= hitbox.damage


func enemy_detected(detected_area: DetectedArea):
	if not detected_enemies.has(detected_area.owner):
		detected_enemies.append(detected_area.owner)


func enemy_lost(detected_area: DetectedArea):
	if detected_enemies.has(detected_area.owner):
		detected_enemies.erase(detected_area.owner)
		visible_enemies.erase(detected_area.owner)


func hit(hurtbox: HurtBox):
	var acc = hurtbox.global_position.direction_to(hitbox.global_position) * knockback_impulse
	velocity += acc
	if current_state == State.Chasing:
		end_chasing = true
		next_state = State.Adjusting


func on_collision_detection(body: Node2D):
	pass


func die() -> void:
	var n_points = randi_range(5, 8)
	for i in range(n_points):
		var p_point = preload("res://scenes/utilities/p_point.tscn").instantiate()
		p_point.global_position = global_position
		get_tree().current_scene.add_child(p_point)
	queue_free()
