class_name DetectingArea
extends Area2D

signal target_entered(detected_area)
signal target_lost(detected_area)

# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_lost)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_area_entered(area: Area2D):
	var detected_area = area as DetectedArea
	if detected_area:
		target_entered.emit(detected_area)

func _on_area_lost(area: Area2D):
	var detected_area = area as DetectedArea
	if detected_area:
		target_lost.emit(detected_area)
