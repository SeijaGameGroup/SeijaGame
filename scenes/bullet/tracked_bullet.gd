class_name TrackedBullet
extends BaseBullet

@onready var timer: Timer = $Timer
@onready var hitbox: HitBox = $HitBox
@onready var environment_hit_box: EnvironmentHitBox = $EnvironmentHitBox

signal target_lost


func _ready():
	add_to_group("Bullets")
	timer.start(life)
	timer.timeout.connect(_on_timer_timeout)
	hitbox.hit.connect(_on_hit)
	environment_hit_box.hit.connect(_on_environment_hit)
	hitbox.damage = damage


func _process(delta):
	position += velocity * delta
	if target == null:
		target_lost.emit()
	else:
		velocity = self.global_position.direction_to(target.global_position) * speed


func set_bullet(Shooter, Target, Position:Vector2, Speed:float, Damage:float, Life:float):
	self.shooter = Shooter
	self.target = Target
	self.position = Position
	self.speed = Speed
	self.damage = Damage
	self.life = Life


func _on_timer_timeout():
	queue_free()


func _on_hit(_hurtbox: HurtBox):
	queue_free()


func _on_environment_hit(_body: Node2D):
	queue_free()
