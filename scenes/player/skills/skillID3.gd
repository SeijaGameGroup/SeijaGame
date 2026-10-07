extends Skill

func _init() -> void:
	id = 3
	Name = "不光荣革命"
	cooldown = 60.0
	duration = 10.0
	cancelable = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func effect() -> void:
	player.operatable = false

func deffect() -> void:
	if is_instance_valid(player):
		player.operatable = true
