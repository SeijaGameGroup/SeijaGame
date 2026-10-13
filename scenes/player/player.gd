class_name Player
extends CharacterBody2D

# The enums retain compatibility with archived configuration resources.
enum BulletType { NormalBullet, TrackingBullet }
enum DistributionType { None, Serial, Angular, Vertical }
var operatable := true
var movable := true
var invincible := false
var upside_down := false
var facing_direction := 1.0
var enemy_tracked: Node2D
var interacting_with: Array[Interactable] = []
var viewsize := Vector2(1280, 720)
var hurt_left := 0.0
var immunity_left := 0.0
var jump_buffer := 0.0
var coyote := 0.0
var fire_left := 0.0
var drop_left := 0.0
var camera_y := 360.0
var camera_x := 640.0
@export_group("Camera")
@export_range(0.0, 320.0, 1.0) var camera_deadzone := 120.0
@export_range(100.0, 2400.0, 50.0) var camera_follow_speed := 900.0
@export_range(0.0, 160.0, 1.0) var camera_look_ahead := 0.0
@export var sprite_ground_offset := -23.0
@export var body_half_height := 22.0
var ceiling_y := 66.0
var last_safe := Vector2.ZERO
var shot_count := 0
@onready var graphics: Sprite2D = $Graphics
@onready var camera_2d: Camera2D = $Camera2D
@onready var playerstats: PlayerStats = Game.player_stats
@onready var combat: PlayerCombat = $Combat
var CAN_JUMP: bool:
	get: return is_on_floor()
var IN_AIR: bool:
	get: return not is_on_floor()

func _ready() -> void:
	Game.player_stats.player = self
	last_safe = global_position
	camera_2d.top_level = true
	camera_x = _camera_limit_x(global_position.x)
	camera_2d.global_position = Vector2(camera_x, camera_y)
	camera_2d.reset_smoothing()

func can_act() -> bool:
	return operatable and hurt_left <= 0.0 and not playerstats.dead and not Game.transitioning and not Game.finishing

func set_inverted(value: bool) -> void:
	if upside_down == value:
		return
	upside_down = value
	up_direction = Vector2.DOWN if value else Vector2.UP
	graphics.flip_v = value
	graphics.position.y = sprite_ground_offset * (-1.0 if value else 1.0)
	if value:
		camera_y = camera_2d.get_screen_center_position().y
		ceiling_y = camera_y - 360.0 + 66.0
	velocity.y = 0.0
	coyote = 0.0
	jump_buffer = 0.0

func _physics_process(delta: float) -> void:
	for property in ["hurt_left", "immunity_left", "jump_buffer", "coyote", "fire_left", "drop_left"]:
		set(property, maxf(0.0, float(get(property)) - delta))
	set_collision_mask_value(9, drop_left <= 0.0)
	if playerstats.dead or Game.finishing:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var gravity_sign := -1.0 if upside_down else 1.0
	var on_upper_edge := upside_down and global_position.y <= ceiling_y + body_half_height and velocity.y <= 0
	var grounded := is_on_floor() or on_upper_edge
	if grounded:
		coyote = 0.1
	if can_act():
		if Input.is_action_just_pressed("enemy_lock"):
			playerstats.is_locking = not playerstats.is_locking
		if Input.is_action_just_pressed("jump"):
			jump_buffer = 0.1
		if Input.is_action_just_pressed("drop") and not upside_down:
			drop_left = 0.22
			coyote = 0.0
			global_position.y += 3.0
		if Input.is_action_just_pressed("skill1"):
			Game.guard.skill_pressed()
		if Input.is_action_just_pressed("skill2"):
			Game.inversion.skill_pressed()
		if Input.is_action_just_pressed("skill3"):
			Game.revolution.skill_pressed()
		if Input.is_action_just_pressed("dodge"):
			combat.dash()
		if Input.is_action_just_pressed("interact"):
			interact_nearest()
	enemy_tracking()
	var speed := 300.0 * playerstats.speed_multiplier_item * (1.5 if upside_down else 1.0)
	var can_move: bool = can_act()
	var axis := Input.get_axis("move_left", "move_right") if can_move else 0.0
	if hurt_left <= 0.0:
		velocity.x = move_toward(velocity.x, axis * speed, (2600.0 if grounded else 1600.0) * delta)
	if axis != 0:
		facing_direction = signf(axis)
	if can_move and jump_buffer > 0 and coyote > 0:
		velocity.y = -560.0 * gravity_sign
		jump_buffer = 0.0
		coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y * gravity_sign < -220:
		velocity.y = -220.0 * gravity_sign
	var gravity_scale := playerstats.gravity_multiplier_item if velocity.y * gravity_sign > 0.0 else 1.0
	velocity.y += 1500.0 * gravity_sign * gravity_scale * delta
	velocity.y = clampf(velocity.y, -760.0, 760.0)
	if combat.dash_left > 0.0:
		velocity = Vector2(combat.dash_direction * Game.balance.dash_speed, 0.0)
	if movable:
		move_and_slide()
	if upside_down and global_position.y < ceiling_y + body_half_height:
		global_position.y = ceiling_y + body_half_height
		velocity.y = maxf(0.0, velocity.y)
	if is_instance_valid(Game.room):
		global_position.x = clampf(global_position.x, 24, Game.room.width - 24)
	if not upside_down and is_on_floor():
		last_safe = global_position
	if global_position.y > 1000.0:
		global_position = last_safe
		velocity = Vector2.ZERO
		receive_damage(15, global_position + Vector2.DOWN)
		camera_2d.reset_smoothing()
	if can_act() and Input.is_action_pressed("shoot") and fire_left <= 0:
		shoot()
		fire_left = combat.shot_interval()
	graphics.flip_h = facing_direction < 0
	graphics.flip_v = upside_down
	graphics.position.y = sprite_ground_offset * (-1.0 if upside_down else 1.0)
	graphics.modulate.a = 0.35 if immunity_left > 0 and int(immunity_left * 16) % 2 == 0 else 1.0
	var desired_y := camera_y if upside_down else 360.0
	camera_y = lerpf(camera_y, desired_y, minf(1, delta * 6))
	var room_width: float = Game.room.width if is_instance_valid(Game.room) else 1280
	var center_limit := maxf(640.0, room_width - 640.0)
	# Keep the camera still while the player changes direction near its current
	# center. It only follows after the player leaves the horizontal deadzone,
	# which prevents the old left/right look-ahead target from oscillating.
	var offset := global_position.x - camera_x
	if absf(offset) > camera_deadzone:
		var desired_x := global_position.x - signf(offset) * camera_deadzone
		if absf(velocity.x) > 24.0 and camera_look_ahead > 0.0:
			desired_x += signf(velocity.x) * camera_look_ahead
		camera_x = move_toward(camera_x, _camera_limit_x(desired_x), camera_follow_speed * delta)
	camera_x = clampf(camera_x, 640.0, center_limit)
	camera_2d.global_position = Vector2(camera_x, camera_y)
	playerstats.player_global_position = global_position
	queue_redraw()

func _camera_limit_x(value: float) -> float:
	var room_width: float = Game.room.width if is_instance_valid(Game.room) else 1280.0
	return clampf(value, 640.0, maxf(640.0, room_width - 640.0))

func enemy_tracking() -> void:
	enemy_tracked = null
	if not playerstats.is_locking:
		return
	var best := INF
	for enemy in get_tree().get_nodes_in_group("combat_enemies"):
		if not is_instance_valid(enemy) or enemy.dead or not enemy.targetable:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best and in_view(enemy.global_position) and clear_sight(enemy.global_position):
			best = distance
			enemy_tracked = enemy

func in_view(point: Vector2) -> bool:
	return Rect2(camera_2d.get_screen_center_position() - Vector2(620, 340), Vector2(1240, 680)).has_point(point)

func clear_sight(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, point, 32)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func shoot() -> void:
	combat.shoot()

func spawn_shot(direction: Vector2, damage: float) -> void:
	combat.spawn_shot(direction, damage)

func receive_damage(amount: float, source: Vector2) -> bool:
	if playerstats.dead or immunity_left > 0 or Game.guard.active_left > 0 or combat.dash_left > 0 or invincible or Game.transitioning:
		return false
	immunity_left = 0.8
	hurt_left = 0.12
	velocity = Vector2(160.0 * (1.0 if global_position.x >= source.x else -1.0), 100.0 if upside_down else -130.0)
	var damage: float = amount * Game.balance.enemy_damage_multiplier * (1.0 - playerstats.damage_reduction_rate_item)
	Game.run.damage_taken += damage
	Game.run.combo = 0
	playerstats.take_damage(damage)
	Game.sound("hurt")
	return true

func interact_nearest() -> void:
	var closest: Node2D
	var distance := 90.0
	for object in get_tree().get_nodes_in_group("world_interactions"):
		var current := global_position.distance_to(object.global_position)
		if current < distance:
			distance = current
			closest = object
	if is_instance_valid(closest):
		closest.interact(self)

func add_item(id: int) -> void:
	Game.acquire_item(id)

func _draw() -> void:
	if Game.guard.active_left > 0:
		draw_arc(Vector2.ZERO, 36, 0, TAU, 40, Color("#a1e8ef"), 3)
	if is_instance_valid(enemy_tracked):
		var point := to_local(enemy_tracked.global_position)
		draw_arc(point, 33, 0, TAU, 24, Color(0.7, 0.95, 0.9, 0.75), 1.5)
	if upside_down:
		# Keep the authored support guide just above the collision edge so it
		# does not visually cut through the inverted character's head.
		var support_y := ceiling_y - 8.0
		var left := to_local(Vector2(camera_2d.get_screen_center_position().x - 635, support_y))
		var right := left + Vector2(1270, 0)
		draw_line(left, right, Color(0.84, 0.58, 0.86, 0.7), 2)
		for i in 32:
			var p := left + Vector2(i * 40, 0)
			draw_line(p, p + Vector2(9, -6), Color(0.85, 0.58, 0.86, 0.5), 1)
