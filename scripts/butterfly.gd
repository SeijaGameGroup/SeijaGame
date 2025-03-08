extends CharacterBody2D

@onready var hurtbox 			:= $HurtBox
@onready var animation_player 	:= $AnimationPlayer
@onready var animation_tree 	:= $AnimationTree
@onready var graphics			:= $Graphics
@onready var visible_enemies 	: Array = []
@onready var state_machine 		: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

@export var knockback_acc = 20
@export var WANDERING_SPEED = 20
@export var CHASING_SPEED = 100
@export var health := 60 :
	set(value):
		if (value <= 0):
			die()
		else:
			health = value
@export var damage = 15

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(_delta):
	if not is_zero_approx(velocity.x):
		graphics.scale.x = -1 if velocity.x > 0 else 1
	move_and_slide()

func hurt(hitbox: HitBox):
	var acc = hitbox.global_position.direction_to(hurtbox.global_position) * knockback_acc
	velocity += acc
	health -= (hitbox.damage) as int

func enemy_detected(detected_area: DetectedArea):
	if not visible_enemies.has(detected_area):
		visible_enemies.append(detected_area)
		adjust()
		
func enemy_lost(detected_area: DetectedArea):
	if visible_enemies.has(detected_area):
		visible_enemies.erase(detected_area)

func adjust():
	# print("adjusing...")
	if not visible_enemies.is_empty():
		var enemy = visible_enemies.front() as DetectedArea
		velocity = global_position.direction_to(enemy.global_position) * CHASING_SPEED
		state_machine.travel("chasing")
	else:
		velocity = Vector2.from_angle(randf_range(0, 2*PI)) * WANDERING_SPEED
		state_machine.travel("wandering")
		
func die():
	queue_free()
