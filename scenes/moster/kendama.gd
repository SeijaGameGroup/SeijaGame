extends BaseMonster

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var graphics			: Node2D = $Graphics
@onready var detecting_area		: DetectingArea = $DetectingArea
@onready var front_hurtbox		: HurtBox = $FrontHurtBox
@onready var hurtbox			: HurtBox = $HurtBox
@onready var hitbox				: HitBox = $HitBox
@onready var animation_tree		: AnimationTree = $AnimationTree
@onready var animation_player	: AnimationPlayer = $AnimationPlayer
@onready var stats				: Stats = $Stats
@onready var visible_detection	: Node2D = $VisibleDetection
@onready var state_machine 		: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var walking_timer		: Timer = $WalkingTimer
@onready var charging_timer		: Timer = $ChargingTimer
@onready var hovering_timer		: Timer = $HoveringTimer
@onready var cooldown_timer		: Timer = $CoolDownTimer

@export var hit_damage			: float = 8.0 :
	set(value):
		hit_damage = value
		hitbox.damage = value
@export var hit_cooldown		: float = 1.0
@export var hurt_reduction_rate	: float = 0.9
@export var resistance_rate		: float = 0.6

@export var knockback_impulse 	: float = 50
@export var walking_acc			: float = 200
@export var WALIKNG_SPEED		: float = 50
@export var JUMP_SPEED			: float = -500
@export var walking_time		: float = 3.0

@export var detected_enemies	: Array = []
@export var visible_enemies 	: Array = []
@export var enemy				: Node
@export var current_state		: State = State.Walking
@export var next_state 			: State
@export var velocity_target		: Vector2
@export var target_position		: Vector2
@export var direction_in_air	: bool			# true <=> RIGHT

enum State{
	Idle,
	Walking,
	Jump,
	Rising,
	Hovering,
	Falling,
	Hit,
	Chasing,
}
const StatesInAir = [State.Rising, State.Hovering, State.Falling]

func _ready() -> void:
	super()
	current_state = State.Walking
	stats.max_health = 80.0
	stats.health = 80.0


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
		State.Walking:
			velocity = velocity.move_toward(velocity_target, walking_acc * delta)
			if walking_timer.is_stopped():
				walking_timer.start(randf_range(walking_time/2, walking_time))
				velocity_target = WALIKNG_SPEED * Vector2.LEFT if randi()%2 == 1 else WALIKNG_SPEED * Vector2.RIGHT
			if not enemy == null:
				if cooldown_timer.is_stopped():
					next_state = State.Jump
			else:
					next_state = State.Walking
		State.Jump:
			velocity = velocity.move_toward(Vector2.ZERO, walking_acc * delta)
			if enemy:
				if charging_timer.is_stopped():
					next_state = State.Rising
				else:
					next_state = State.Jump
			else:
					next_state = State.Walking
		State.Rising:
			if velocity.y >= 0:
				next_state = State.Hovering
			else:
				next_state = State.Rising
		State.Hovering:
			velocity = velocity.move_toward(Vector2.ZERO, walking_acc * delta)
			if hovering_timer.is_stopped():
				next_state = State.Falling
			else:
				next_state = State.Hovering
		State.Falling:
			velocity.x = 0
			if is_on_floor():
				next_state = State.Hit
			else:
				next_state = State.Falling
		State.Hit:
			next_state = State.Chasing
		State.Chasing:
			velocity_target = WALIKNG_SPEED * Vector2.LEFT if direction_to_enemy.x < 0 else WALIKNG_SPEED * Vector2.RIGHT
			velocity = velocity.move_toward(velocity_target, walking_acc * delta)
			if enemy:
				if cooldown_timer.is_stopped():
					next_state = State.Jump
				else:
					next_state = State.Chasing
			else:
				next_state = State.Walking
	# Handle Transition Behavior
	if not current_state == next_state:
		# Handle Exit Behavior
		match current_state:
			State.Idle:
				pass
			State.Walking:
				walking_timer.stop()
			State.Jump:
				charging_timer.stop()
			State.Rising:
				pass
			State.Hovering:
				hovering_timer.stop()
			State.Falling:
				pass
			State.Hit:
				pass
			State.Chasing:
				pass

		# Handle Entering Behavior
		match next_state:
			State.Idle:
				pass
			State.Walking:
				walking_timer.start(randf_range(walking_time/2, walking_time))
				velocity_target = WALIKNG_SPEED * Vector2.LEFT if randi()%2 == 1 else WALIKNG_SPEED * Vector2.RIGHT
			State.Jump:
				charging_timer.start()
			State.Rising:
				velocity.y = JUMP_SPEED
				if enemy and enemy is Node2D:
					var target_distance_x = enemy.global_position.x - self.global_position.x
					velocity.x = target_distance_x * -gravity / JUMP_SPEED
			State.Hovering:
				velocity = Vector2.ZERO
				hovering_timer.start()
			State.Falling:
				velocity.x = 0
				velocity.y = - JUMP_SPEED
			State.Hit:
				pass
			State.Chasing:
				cooldown_timer.start(hit_cooldown)


		current_state = next_state

	if not current_state == State.Hovering:
		velocity.y += gravity * delta

	if not is_zero_approx(velocity.x):
		if current_state == State.Jump:
			graphics.scale.x = -1 if direction_to_enemy.x > 0 else 1
			hurtbox.scale.x = -1 if direction_to_enemy.x > 0 else 1
			front_hurtbox.scale.x = -1 if direction_to_enemy.x > 0 else 1
		elif StatesInAir.has(State):
			graphics.scale.x = -1 if direction_in_air else 1
			hurtbox.scale.x = -1 if direction_in_air else 1
			front_hurtbox.scale.x = -1 if direction_in_air else 1
		else:
			graphics.scale.x = -1 if velocity.x > 0 else 1
			hurtbox.scale.x = -1 if velocity.x > 0 else 1
			front_hurtbox.scale.x = -1 if velocity.x > 0 else 1

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


func hurt_front(hit: HitBox):
	var acc = hitbox.global_position.direction_to(hurtbox.global_position) * knockback_impulse
	velocity += acc * resistance_rate
	stats.health -= hitbox.damage * hurt_reduction_rate


func enemy_detected(detected_area: DetectedArea):
	if not detected_enemies.has(detected_area.owner):
		detected_enemies.append(detected_area.owner)


func hit(hurtbox: HurtBox):
	var acc = hurtbox.global_position.direction_to(hitbox.global_position) * knockback_impulse
	velocity += acc


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
