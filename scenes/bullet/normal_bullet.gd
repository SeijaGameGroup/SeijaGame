# constant v and no target
class_name NormalBullet
extends BaseBullet

@onready var timer: Timer = $Timer
@onready var hitbox: HitBox = $HitBox


func _ready():
	add_to_group("Bullets")
	timer.start(life)
	timer.timeout.connect(_on_timer_timeout)
	hitbox.area_entered.connect(_on_hit)


func _process(delta):
	position += velocity * delta


func set_bullet(shooter, position:Vector2, direction:Vector2, speed:float, damage:float, life:float):
	self.shooter = shooter
	self.position = position
	self.direction = direction
	self.speed = speed
	self.damage = damage
	self.life = life
	velocity = direction * speed


func _on_timer_timeout():
	queue_free()


func _on_hit(_hurtbox: HurtBox):
	queue_free()
