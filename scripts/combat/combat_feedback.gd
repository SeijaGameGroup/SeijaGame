class_name CombatFeedback
extends Node2D

var _numbers: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _font: Font = ThemeDB.fallback_font

func clear() -> void:
	_numbers.clear()
	_rings.clear()
	queue_redraw()

func hit(at: Vector2, amount: float, color: Color = Color("ffe0a5")) -> void:
	if _numbers.size() >= 36:
		_numbers.pop_front()
	_numbers.append({"at": at + Vector2(-8, -25), "text": str(roundi(amount)), "left": 0.6, "color": color})
	queue_redraw()

func pulse(at: Vector2, radius: float, color: Color) -> void:
	_rings.append({"at": at, "radius": radius, "left": 0.45, "color": color})
	queue_redraw()

func _process(delta: float) -> void:
	for number: Dictionary in _numbers:
		number.left -= delta
		number.at.y -= delta * 38.0
	for ring: Dictionary in _rings:
		ring.left -= delta
	_numbers = _numbers.filter(func(n: Dictionary) -> bool: return n.left > 0.0)
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.left > 0.0)
	queue_redraw()

func _draw() -> void:
	for number: Dictionary in _numbers:
		var color: Color = number.color
		color.a = minf(1.0, number.left * 3.0)
		draw_string(_font, number.at, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	for ring: Dictionary in _rings:
		var progress: float = 1.0 - ring.left / 0.45
		var color: Color = ring.color
		color.a *= 1.0 - progress
		draw_arc(ring.at, lerpf(16.0, ring.radius, progress), 0, TAU, 48, color, 5.0)
