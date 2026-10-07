extends Node2D
@export var amount: int = 8
@export var healing: float = 0.0
@export var pickup_delay: float = 0.35
var collected: bool = false
var lifetime: float = 0.0
var velocity: Vector2 = Vector2(0, -110)
func _ready() -> void:
	add_to_group("point_pickups")
	z_index = 4
func collect() -> void:
	if collected:
		return
	collected = true
	if amount > 0:
		Game.add_points(amount)
	if healing > 0:
		Game.player_stats.health += healing
	amount = 0
	queue_free()
func _physics_process(delta: float) -> void:
	lifetime += delta
	var player := Game.player_stats.player
	if not is_instance_valid(player):
		return
	if lifetime <= pickup_delay:
		velocity.y += 320 * delta
		position += velocity * delta
	else:
		var speed: float = 500.0 + lifetime * 180.0
		position = position.move_toward(player.global_position, speed * delta)
	if position.distance_to(player.global_position) < 30.0:
		collect()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-7, -7, 14, 14), Color("#8cddc9") if healing > 0 else Color("#c991dd"))
	draw_rect(Rect2(-4, -4, 8, 8), Color("#f9e6d1"))
