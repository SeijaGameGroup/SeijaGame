@tool
class_name EncounterMarker
extends Node2D

## Scene-authored encounter marker. Edit this string in the Inspector.
## B butterfly, K kedama, R red spirit, G green spirit.
@export var enemy_codes := "B"
@export var trigger_radius := 370.0
@export var wave_count_override := 0

func lineup() -> Array[int]:
	var result: Array[int] = []
	for code in enemy_codes.to_upper():
		match code:
			"B": result.append(CombatEnemy.Kind.BUTTERFLY)
			"K": result.append(CombatEnemy.Kind.KEDAMA)
			"R": result.append(CombatEnemy.Kind.RED)
			"G": result.append(CombatEnemy.Kind.GREEN)
	return result

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_line(Vector2.ZERO, Vector2(0, 610), Color(0.95, 0.64, 0.78, 0.35), 2.0)
	draw_circle(Vector2.ZERO, 8.0, Color(0.95, 0.64, 0.78, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(12, 24), enemy_codes, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.78, 0.86))
