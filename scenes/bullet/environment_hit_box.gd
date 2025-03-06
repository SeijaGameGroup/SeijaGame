class_name EnvironmentHitBox
extends Area2D


signal hit


func _ready():
	body_entered.connect(_on_body_entered)


func _process(_delta):
	pass


func _on_body_entered(body: Node2D):
	var tilemaplayer = body as TileMapLayer
	var collider = body as CollisionObject2D
	if tilemaplayer:
		print("[Hit] %s => %s" % [owner.name, body.name])
		hit.emit(body)
	if collider:
		if collider.collision_layer == 6:
			print("[Hit] %s => %s" % [owner.name, body.name])
			hit.emit(body)
