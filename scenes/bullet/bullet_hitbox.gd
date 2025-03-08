class_name BulletHitBox
extends HitBox


func _on_area_entered(area: Area2D):
	var collider = area as CollisionObject2D
	var hurtbox = area as HurtBox
	if hurtbox:
		print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
		hurtbox.hurt.emit(self)
		hit.emit(hurtbox)
	if collider.collision_layer == 6:	#EnvironmentCollisionArea
		hit.emit()
