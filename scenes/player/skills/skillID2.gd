extends Skill

func _init() -> void:
	super()
	id = 2
	cooldown = 3.0
	duration = 2.0
	Name = "逆符「天地有用」"
	cancelable = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func effect() -> void:
	super()
	player.upside_down = true
	player.speed_multiplier_skill = 1.5

func deffect() -> void:
	super()
	player.upside_down = false
	player.speed_multiplier_skill = 1
