extends Node2D
var rect := Rect2()
var warning := 1.15
var active := 0.35
var age := 0.0
var hit := false
func _ready() -> void:
	add_to_group("boss_hazards")
	z_index = 3
func _physics_process(delta: float) -> void:
	age += delta
	if age >= warning + active:
		queue_free()
		return
	var player := Game.player_stats.player
	if age >= warning and not hit and is_instance_valid(player):
		var body := Rect2(player.global_position - Vector2(10, 20), Vector2(20, 40))
		if rect.intersects(body):
			hit = player.receive_damage(20, rect.get_center())
	queue_redraw()
func _draw() -> void:
	var armed := age >= warning
	draw_rect(rect, Color(1, 0.45, 0.4, 0.38 if armed else 0.08))
	draw_rect(rect, Color("#ffbda3"), false, 3 if armed else 1)
	for x in range(int(rect.position.x), int(rect.end.x), 42):
		draw_line(Vector2(x, rect.end.y), Vector2(x + 20, rect.position.y), Color(1, 0.7, 0.5, 0.5), 1)
