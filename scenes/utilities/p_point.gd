class_name P_Point

extends Node2D

var gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State {
	FALLING,
	ATTRACTED,
}

@export var velocity : Vector2 = Vector2.ZERO
@export var state : State = State.FALLING
@export var speed := 150.0
@export var init_speed := 50.0

func _ready() -> void:
	$Timer.timeout.connect(func(): state = State.ATTRACTED)
	velocity = Vector2.from_angle(randf_range(0, 2*PI)) * init_speed

func _physics_process(delta: float) -> void:
	match state:
		State.FALLING:
			velocity.y += gravity * delta
			global_position += velocity * delta
		State.ATTRACTED:
			global_position = global_position.move_toward(Game.player_stats.player_global_position, speed * delta)
	if global_position.distance_to(Game.player_stats.player_global_position) < 10:
		Game.player_stats.p_points += 1
		queue_free()
