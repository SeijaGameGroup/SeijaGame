class_name TrackedBullet
extends BaseBullet

@onready var timer: Timer = $Timer
@onready var hitbox: HitBox = $HitBox

signal target_lost


func _ready():
	add_to_group("Bullets")
	timer.start(life)
	timer.timeout.connect(_on_timer_timeout)
	hitbox.area_entered.connect(_on_hit)


func _process(delta):
	position += velocity * delta
	if target == null:
		target_lost.emit()
	else:
		velocity = self.global_position.direction_to(target.global_position) * speed
		print(self.global_position, target.global_position, target.name)


func set_bullet(shooter, target, position:Vector2, speed:float, damage:float, life:float):
	self.shooter = shooter
	self.target = target
	self.position = position
	self.speed = speed
	self.damage = damage
	self.life = life


func _on_timer_timeout():
	queue_free()


func _on_hit(_hurtbox: HurtBox):
	queue_free()
