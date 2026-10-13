@tool
extends Node2D

@export var points: int = 20
@export var energy: float = 25.0
@export var collect_radius: float = 48.0
@onready var sprite: Sprite2D = $Sprite2D
var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = sin(_time * 2.0) * 4.0
	if Engine.is_editor_hint():
		return
	var key: String = str(get_parent().name) + "/" + str(name)
	visible = not Game.run.collected.has(key)
	if not visible:
		return
	var player: Player = Game.player_stats.player
	if is_instance_valid(player) and player.upside_down and player.global_position.distance_to(global_position) < collect_radius:
		Game.run.collected[key] = true
		Game.add_points(points)
		Game.gain_energy(energy)
		Game.feedback.pulse(global_position, 85.0, Color("d5b1ee"))
		Game.notify("逆行秘藏 · +%d P · +%d 逆势" % [points, energy])
		Game.sound("buy")
		hide()
