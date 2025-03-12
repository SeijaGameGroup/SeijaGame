# constant v and no tracking
class_name NormalBullet
extends BaseBullet

@onready var timer: Timer = $Timer
@onready var hitbox: HitBox = $HitBox
@onready var environment_hit_box: EnvironmentHitBox = $EnvironmentHitBox



func _ready():
	add_to_group("Bullets")
	timer.start(life)
	hitbox.damage = damage
	if shooter is Player:
		hitbox.set_collision_mask_value(3,false)
		hitbox.set_collision_mask_value(4,true)
	if shooter in get_tree().get_nodes_in_group("Monsters"):
		hitbox.set_collision_mask_value(3,true)
		hitbox.set_collision_mask_value(4,false)


func _process(delta):
	velocity = direction * speed
	position += velocity * delta
	rotation = direction.angle()


func _on_timer_timeout():
	queue_free()


func _on_hit(_hurtbox: HurtBox):
	queue_free()


func _on_environment_hit(_body: Node2D):
	queue_free()
