extends Control
var font: Font
var mono: Font
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas"])
func _process(_delta: float) -> void:
	queue_redraw()
func label_at(at: Vector2, content: String, size: int = 16, color: Color = Color("#dadfdc")) -> void:
	draw_string(font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
func skill_box(at: Vector2, key: String, title: String, skill: Skill, accent: Color) -> void:
	draw_rect(Rect2(at, Vector2(230, 63)), Color(0.035, 0.07, 0.12, 0.93))
	draw_rect(Rect2(at, Vector2(3, 63)), accent)
	label_at(at + Vector2(17, 25), key + "   " + title, 19)
	var status := "就绪"
	if skill.active_left > 0:
		status = "持续 %.1f 秒" % skill.active_left
	elif skill.remaining > 0:
		status = "冷却 %.1f 秒" % skill.remaining
	label_at(at + Vector2(17, 49), status, 14, accent)
	var fraction := skill.active_left / (skill.duration * (Game.player_stats.dodge_time_multipler_item if skill.id == 1 else 1.0)) if skill.active_left > 0 else 1.0 - skill.remaining / skill.cooldown
	draw_rect(Rect2(at + Vector2(0, 60), Vector2(230 * clampf(fraction, 0, 1), 3)), accent)
func _draw() -> void:
	if not is_instance_valid(Game.room) or Game.guard == null:
		return
	var stats := Game.player_stats
	draw_rect(Rect2(0, 0, 1280, 61), Color(0.035, 0.06, 0.10, 0.95))
	label_at(Vector2(26, 28), Game.room.room_title, 23, Color("#eee0c3"))
	label_at(Vector2(26, 49), Game.room.subtitle, 12, Color("#83a4a8"))
	label_at(Vector2(650, 26), Game.room.objective, 13, Color("#b7c8c7"))
	label_at(Vector2(1080, 49), "Esc 暂停   ·   %02d:%02d" % [int(Game.run.elapsed) / 60, int(Game.run.elapsed) % 60], 13)
	if Game.run.active:
		draw_rect(Rect2(24, 82, 246, 69), Color(0.035, 0.06, 0.10, 0.88))
		label_at(Vector2(38, 105), "正邪", 17)
		label_at(Vector2(101, 104), "%d / %d" % [stats.health, stats.max_health], 15)
		draw_rect(Rect2(38, 117, 216, 8), Color("#3c3347"))
		draw_rect(Rect2(38, 117, 216 * stats.health / stats.max_health, 8), Color("#d5a6b1"))
		label_at(Vector2(38, 142), "%d P   ·   R 索敌 %s" % [stats.p_points, "开" if stats.is_locking else "关"], 13, Color("#e4c99c"))
		var x := 24.0
		for id in Game.run.items:
			draw_texture_rect(ItemCatalog.icon(id), Rect2(x, 163, 31, 31), false)
			label_at(Vector2(x + 23, 198), str(Game.run.items[id]), 12)
			x += 40
		skill_box(Vector2(24, 633), "H", "闪避布", Game.guard, Color("#9ce0d2"))
		skill_box(Vector2(266, 633), "U", "天地有用", Game.inversion, Color("#d8a4dc"))
		label_at(Vector2(535, 665), "A/D 移动  W/空格 跳跃  S 落下  J 射击  F 互动", 14, Color("#adc0c2"))
	if is_instance_valid(Game.room.boss) and Game.room.boss.targetable:
		var boss: Node2D = Game.room.boss
		label_at(Vector2(462, 93), "异化蝶魁   /   " + ("蝶翼初绽" if boss.phase == 1 else "天地皆敌"), 18, Color("#ecc6d6"))
		draw_rect(Rect2(350, 105, 580, 9), Color("#342f49"))
		draw_rect(Rect2(350, 105, 580 * boss.health / boss.max_health, 9), Color("#d48daf"))
	if get_tree().paused:
		label_at(Vector2(500, 320), "已暂停 · Esc 继续", 26, Color("#f7e4bd"))
