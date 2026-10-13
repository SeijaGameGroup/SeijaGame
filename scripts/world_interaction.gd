@tool
class_name WorldInteraction
extends Node2D
@export_enum("exit", "start", "quit", "shop", "item", "heal", "boss", "win", "reward") var kind: String = "exit"
@export var title: String = ""
@export_multiline var detail: String = ""
@export var target: String = ""
@export var entry: String = "entry"
@export var key: String = ""
@export var item_id: int = 1
@export var price: int = 0
@export var healing: float = 0.0
@export var locked: bool = false
var feedback: String = ""
var feedback_left: float = 0.0
var font: Font
var icon_texture: Texture2D
var pulse: float = 0.0

func _ready() -> void:
	add_to_group("world_interactions")
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	if kind == "item" or kind == "shop":
		icon_texture = ItemCatalog.icon(item_id)

func is_used() -> bool:
	return not Engine.is_editor_hint() and key != "" and Game.run.collected.has(key)

func focused() -> bool:
	if Engine.is_editor_hint():
		return false
	var player := Game.player_stats.player
	if not is_instance_valid(player) or player.global_position.distance_to(global_position) > 90:
		return false
	for other in get_tree().get_nodes_in_group("world_interactions"):
		if other != self and other.global_position.distance_squared_to(player.global_position) < global_position.distance_squared_to(player.global_position):
			return false
	return true

func interact(_player: Player) -> void:
	if Game.transitioning or Game.finishing:
		return
	if locked:
		say("先击退此地的敌人")
		return
	if is_used():
		say("已售罄" if kind == "shop" else "已领取")
		return
	match kind:
		"exit":
			for pickup in get_tree().get_nodes_in_group("point_pickups"):
				pickup.collect()
			Game.enter_room(target, entry)
		"start":
			Game.new_run()
		"quit":
			get_tree().quit()
		"shop":
			say(Game.purchase(key, item_id, price, healing))
		"reward":
			Game.rewards.offer(key, title + " · 选择一件宝物")
		"item":
			if Game.acquire_item(item_id):
				Game.run.collected[key] = true
				say(ItemCatalog.title(item_id) + "  已获得")
		"heal":
			if Game.player_stats.health >= Game.player_stats.max_health:
				say("生命已满，可留给之后")
			else:
				Game.player_stats.health = Game.player_stats.max_health
				Game.run.collected[key] = true
				Game.sound("buy")
				say("伤势恢复")
		"boss":
			Game.room.start_boss()
			Game.run.collected[key] = true
		"win":
			Game.finish_run(true)

func say(text: String) -> void:
	feedback = text
	feedback_left = 2.0

func _process(delta: float) -> void:
	pulse += delta
	feedback_left = maxf(0, feedback_left - delta)
	queue_redraw()

func centered(text: String, y: float, size: int, color: Color) -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-text_width / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	var accent := Color("#8dddd0")
	if locked or is_used():
		accent = Color("#686d81")
	var active := focused()
	if kind in ["exit", "start", "win", "quit"]:
		draw_arc(Vector2(0, -18), 31, 0, TAU, 40, Color(accent, 0.16), 16)
		draw_arc(Vector2(0, -18), 31 + sin(pulse * 2), 0, TAU, 40, accent, 2)
		draw_line(Vector2(-40, 26), Vector2(40, 26), accent, 3)
		draw_line(Vector2(-10, -18), Vector2(12, -18), accent, 2)
		draw_line(Vector2(12, -18), Vector2(3, -26), accent, 2)
		draw_line(Vector2(12, -18), Vector2(3, -10), accent, 2)
	elif kind == "boss":
		draw_colored_polygon(PackedVector2Array([Vector2(0, -58), Vector2(30, -18), Vector2(0, 20), Vector2(-30, -18)]), Color("#976587"))
		draw_arc(Vector2(0, -18), 39, pulse, pulse + 5, 30, Color("#f0b4cb"), 2)
	else:
		draw_rect(Rect2(-30, 18, 60, 12), Color("#817069"))
		draw_rect(Rect2(-24, 30, 48, 5), Color("#383c50"))
		if not is_used():
			if is_instance_valid(icon_texture) and healing <= 0:
				draw_texture_rect(icon_texture, Rect2(-23, -37 + sin(pulse * 2) * 3, 46, 46), false)
			else:
				draw_circle(Vector2(0, -12), 21, Color("#7ecfba"))
				draw_line(Vector2(-10, -12), Vector2(10, -12), Color("#142d31"), 5)
				draw_line(Vector2(0, -22), Vector2(0, -2), Color("#142d31"), 5)
	centered(title, -70, 18, Color("#ede6d8") if not is_used() else Color("#82858f"))
	if kind == "shop":
		centered("售罄" if is_used() else "%d P" % price, 57, 16, Color("#e5c088"))
	if active:
		var prompt := "F  " + ("已领取" if is_used() else ("未开启" if locked else ("购买" if kind == "shop" else "互动")))
		centered(prompt, -102, 17, accent)
		if detail != "":
			centered(detail, -130, 15, Color("#c6d0d4"))
	if feedback_left > 0:
		centered(feedback, -156, 17, Color("#ffd8a3"))
