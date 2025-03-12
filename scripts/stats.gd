class_name Stats

extends Node

signal die()
signal health_changed()

@export var max_health : float
@export var health := max_health :
	set(value):
		if value <= 0:
			die.emit()
		elif value != health:
			health = minf(value, max_health)
			health_changed.emit()
