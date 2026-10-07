class_name PlayerSprite
extends Sprite2D

@export_range(1.0, 20.0, 0.5) var run_fps: float = 9.0
@export_range(0.5, 8.0, 0.5) var idle_fps: float = 2.0
# Baselines are source-cell coordinates: generated frames have different padding.
@export var foot_rows: PackedFloat32Array = PackedFloat32Array([438, 438, 438, 438, 390, 390, 390, 390])
var _time: float = 0.0
@onready var _player: Player = get_parent() as Player

func _process(delta: float) -> void:
	_time += delta
	var grounded: bool = _player.is_on_floor() or (_player.upside_down and _player.position.y <= _player.ceiling_y + _player.body_half_height + 1.0)
	if not grounded:
		frame = 2 if _player.velocity.y * (-1.0 if _player.upside_down else 1.0) < 0.0 else 3
	elif absf(_player.velocity.x) > 10.0:
		frame = 4 + int(_time * run_fps) % 4
	else:
		frame = int(_time * idle_fps) % 2
	if texture != null and frame < foot_rows.size():
		var cell_height: float = float(texture.get_height()) / vframes
		offset.y = (cell_height * 0.5 - foot_rows[frame]) * (-1.0 if _player.upside_down else 1.0)
