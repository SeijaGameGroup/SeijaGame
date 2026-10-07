class_name Stats
extends Node

signal die
signal health_changed
@export var max_health := 150.0
var dead := false
@export var health := 150.0:
	set(value):
		var old := health
		health = clampf(value, 0.0, max_health)
		if not is_equal_approx(old, health):
			health_changed.emit()
		if health <= 0.0 and not dead:
			dead = true
			die.emit()

func reset_health(value: float) -> void:
	dead = false
	max_health = value
	health = value
	health_changed.emit()

func take_damage(amount: float) -> bool:
	if dead or amount <= 0.0:
		return false
	health -= amount
	return true
