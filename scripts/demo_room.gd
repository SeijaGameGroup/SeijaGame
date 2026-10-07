extends Node2D

@export var room_id := "courtyard"
@export var room_width := 1280.0
@export var tree_spacing := 165.0
@export var tree_offset := 55.0
@export var canopy_tint := Color(0.30, 0.46, 0.49, 0.65)
@export var trunk_tint := Color(0.28, 0.42, 0.47, 0.8)
@export var fog_amount := 50
@export var sky_top := Color("10192a")
@export var sky_bottom := Color("172b3d")
@export var platform_tint := Color("71655e")
@export var lantern_tint := Color("f1dba6")
@export var lantern_spacing := 260.0
var width: float = 1280.0
var room_title: String = ""
var subtitle: String = ""
var objective: String = ""
var platforms: Array[Rect2] = []
var solids: Array[Rect2] = []
var signs: Array = []
var stages: Array = []
var stage_index := 0
var enemies_left := 0
var encounter_active := false
var wave_index := 0
var wave_count := 1
var wave_delay := 0.0
var doors: Array = []
var gate: StaticBody2D
var gate_x := 0.0
var boss: Node2D
var font: Font
var player: Player
var backdrop: Node2D
var done := false
var theme: Color = Color("#8bcfbe")
const TITLES := {
	"courtyard": ["逆旅", "BUTTERFLY  /  鬼人正邪"],
	"regular_level1": ["一 · 蝶迹", "人里边缘"],
	"regular_level2": ["岔路 · 兽道", "额外战斗"],
	"regular_level3": ["二 · 迷途竹林", "竹林深处"],
	"regular_level4": ["三 · 裂隙前夜", "蝶群聚集"],
	"shop1": ["隙间小铺", "补给"],
	"shop2": ["最后的补给", "决战前"],
	"healing_room1": ["歇脚处", "恢复"],
	"healing_room2": ["月下息所", "恢复"],
	"crack1": ["逆行隙间", "竹林"],
	"crack2": ["异化之门", "蝶魁"],
	"boss_room": ["终 · 异化蝶魁", "决战"],
}

func _ready() -> void:
	Game.room = self
	Game.run.room_id = room_id
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	room_title = TITLES[room_id][0]
	subtitle = TITLES[room_id][1]
	width = room_width
	if room_id.begins_with("regular"):
		width = maxf(room_width, 3520.0)
		if not Game.run.active:
			Game.run.reset(12345)
			Game.player_stats.reset_run()
		build_combat()
	elif room_id == "boss_room":
		width = 1440
		build_boss()
	elif room_id == "courtyard":
		build_courtyard()
	else:
		build_rest()
	add_solid(Rect2(0, 610, width, 210))
	add_solid(Rect2(-40, -500, 40, 1500))
	add_solid(Rect2(width, -500, 40, 1500))
	_collect_scene_geometry()
	backdrop = get_node_or_null("RoomBackdrop")
	if not is_instance_valid(backdrop):
		backdrop = load("res://scenes/props/room_backdrop.tscn").instantiate()
		add_child(backdrop)
	backdrop.tree_spacing = tree_spacing
	backdrop.tree_offset = tree_offset
	backdrop.canopy_tint = canopy_tint
	backdrop.trunk_tint = trunk_tint
	backdrop.fog_amount = fog_amount
	backdrop.sky_top = sky_top
	backdrop.sky_bottom = sky_bottom
	backdrop.platform_tint = platform_tint
	backdrop.lantern_tint = lantern_tint
	backdrop.lantern_spacing = lantern_spacing
	backdrop.configure(width, platforms, solids, theme)
	backdrop.z_index = -10
	player = preload("res://scenes/player/player.tscn").instantiate()
	player.position = Vector2(120, 580)
	if room_id == "courtyard":
		# Keep the run summary; only the courtyard avatar is revived.
		Game.player_stats.dead = false
		Game.player_stats.health = maxf(1, Game.player_stats.health)
		Game.finishing = false
	add_child(player)
	var entrance := Marker2D.new()
	entrance.name = "Entry"
	entrance.position = player.position
	add_child(entrance)
	Game.play_music("res://assets/audio/forest.wav")
	queue_redraw()

func _collect_scene_geometry() -> void:
	# Platforms and optional walls are authored as StaticBody2D children in the room scene.
	# This keeps level tuning in the editor while retaining a code-created safety floor.
	for body in get_children():
		if not body is StaticBody2D or body.get_meta("runtime_floor", false):
			continue
		for shape_node in body.get_children():
			if not shape_node is CollisionShape2D or shape_node.shape == null:
				continue
			var shape_rect: Rect2 = shape_node.shape.get_rect()
			var rect := Rect2(body.position + shape_node.position + shape_rect.position, shape_rect.size)
			if body.collision_layer == 256:
				platforms.append(rect)
			else:
				solids.append(rect)

func add_solid(rect: Rect2, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 256 if one_way else 32
	body.collision_mask = 0
	body.set_meta("runtime_floor", true)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 8
	body.add_child(collision)
	add_child(body)
	if one_way:
		platforms.append(rect)
	else:
		solids.append(rect)

func interactable(kind: String, at: Vector2, title: String, detail: String = "", target: String = "") -> Node2D:
	for authored in get_children():
		if not authored is WorldInteraction or authored.kind != kind or not authored.get_meta("scene_authored", false):
			continue
		if kind == "item" and title == "清场的馈赠":
			continue
		if authored.get_meta("runtime_configured", false):
			continue
		if target != "" and authored.target != target:
			continue
		authored.position = at
		authored.title = title
		authored.detail = detail
		authored.target = target
		authored.set_meta("runtime_configured", true)
		return authored
	var node: WorldInteraction = load("res://scenes/props/world_interaction.tscn").instantiate()
	node.kind = kind
	node.position = at
	node.title = title
	node.detail = detail
	node.target = target
	add_child(node)
	return node

func exit_door(at: Vector2, title: String, target: String, locked: bool = false) -> void:
	var node := interactable("exit", at, title, "靠近后按 F 前往", target)
	node.locked = locked
	doors.append(node)

func signpost(x: float, title: String, text: String, y: float = 435) -> void:
	signs.append([Vector2(x, y), title, text])

func _scene_stages() -> Array:
	var result: Array = []
	for child in get_children():
		if not child is Node2D or not child.has_method("lineup"):
			continue
		var lineup: Array = child.lineup()
		if not lineup.is_empty():
			result.append([child.position.x, lineup, child])
	result.sort_custom(func(a, b): return a[0] < b[0])
	return result

func build_courtyard() -> void:
	objective = "靠近光门 · F 开始"
	interactable("start", Vector2(440, 577), "再启旅程" if Game.run.outcome != "" else "踏入蝶迹", "F 开始一局新的旅程")
	interactable("quit", Vector2(1120, 577), "离开", "F 退出游戏")
	signpost(135, "A/D 移动 · W 跳跃", "J 射击 · H 防护 · U 反转", 400)
	if Game.run.outcome != "":
		signpost(650, Game.run.outcome, "%02d:%02d · 击败 %d · %d P" % [int(Game.run.elapsed) / 60, int(Game.run.elapsed) % 60, Game.run.kills, Game.run.total_points], 400)
	else:
		signpost(675, "蝶翼指向竹林", "沿光门前进", 400)
	add_solid(Rect2(840, 455, 160, 12), true)

func build_combat() -> void:
	var tier := int(room_id.right(1))
	objective = "清除蝶障 · 开启出口"
	theme = Color("#8bcfbe") if tier < 3 else Color("#b7a0d1")
	# Platforms are authored in each regular_level*.tscn. The room script only places
	# encounters and exits, so designers can tune jumps without editing code.
	if tier == 1:
		signpost(170, "A/D 移动 · W 跳跃", "J 射击 · H 防护 · U 反转")
		signpost(760, "H 防护", "短暂免伤", 220)
		signpost(1530, "U 反转", "沿上沿走", 205)
	stages = _scene_stages()
	if stages.is_empty():
		stages = [[590.0, [0, 0]], [1420.0, [0, 1, 2]], [2280.0, [0, 1, 2, 3]]]
	if room_id == "regular_level1":
		exit_door(Vector2(3120, 577), "隙间小铺", "shop1", true)
		exit_door(Vector2(3380, 577), "狂躁的兽道", "regular_level2", true)
	elif room_id == "regular_level2":
		exit_door(Vector2(3220, 577), "疗愈后进入竹林", "healing_room1", true)
	elif room_id == "regular_level3":
		exit_door(Vector2(3220, 577), "裂隙前夜", "regular_level4", true)
	else:
		exit_door(Vector2(3110, 577), "最后的补给", "shop2", true)
		exit_door(Vector2(3380, 577), "月下息所", "healing_room2", true)
	if Game.run.rooms.has(room_id):
		done = true
		stage_index = stages.size()
		for door in doors:
			door.locked = false
	# Upper-route reward is always reachable by inversion or platform jumps.
	var reward := interactable("item", Vector2(2490, 374), "高处的匣子", "F 获得一件道具")
	reward.key = room_id + "/upper"
	reward.item_id = 9 if tier >= 3 else 2
	reward.icon_texture = ItemCatalog.icon(reward.item_id)
	reward.detail = ItemCatalog.description(reward.item_id)

func build_rest() -> void:
	var next := "boss_room" if room_id.ends_with("2") else "crack1"
	if room_id.begins_with("shop"):
		objective = "靠近货架 · F 购买"
		var stock := Game.run.stock(room_id)
		for i in 3:
			var id: int = stock[i]
			var node := interactable("shop", Vector2(340 + i * 205, 577), ItemCatalog.title(id), ItemCatalog.description(id))
			node.item_id = id
			node.icon_texture = ItemCatalog.icon(id)
			node.price = ItemCatalog.DATA[id][3]
			node.key = room_id + "/goods/" + str(i)
		var heal := interactable("shop", Vector2(955, 577), "疗愈露", "回复 55 生命")
		heal.healing = 55
		heal.price = 15
		heal.key = room_id + "/heal"
		signpost(235, "P 点换道具", "F 购买 · 每件一次", 310)
	elif room_id.begins_with("healing"):
		objective = "月光灯 · F 恢复"
		var heal := interactable("heal", Vector2(570, 577), "月光疗愈", "免费恢复全部生命，每局一次")
		heal.key = room_id + "/heal"
		signpost(300, "月光疗愈", "F 恢复生命", 350)
	else:
		objective = "裂隙 · F 穿越"
		signpost(290, "裂隙", "F 穿越", 350)
		next = "regular_level3" if room_id == "crack1" else "boss_room"
	exit_door(Vector2(1150, 577), "前往蝶魁" if next == "boss_room" else "继续前行", next)

func build_boss() -> void:
	objective = "异化核心 · F 挑战"
	add_solid(Rect2(270, 465, 180, 12), true)
	add_solid(Rect2(970, 465, 180, 12), true)
	boss = load("res://scripts/butterfly_boss.gd").new()
	boss.position = Vector2(930, 270)
	add_child(boss)
	boss.defeated.connect(boss_defeated)
	var core := interactable("boss", Vector2(480, 577), "异化核心", "F 挑战 · 异化蝶魁")
	core.key = "boss/activated"
	signpost(150, "蝶魁", "看预警 · 留退路", 350)
	exit_door(Vector2(1300, 577), "尚未开启", "", true)

func start_boss() -> void:
	if not is_instance_valid(boss) or boss.stage != "dormant":
		return
	objective = "异化蝶魁 · 看预警"
	boss.activate()

func boss_defeated() -> void:
	done = true
	objective = "异化之源已被击破。穿过出口，完成这次旅程。"
	for door in doors:
		door.kind = "win"
		door.title = "天光初现"
		door.detail = "F 完成旅程"
		door.locked = false
	signpost(610, "蝶群散去，万宝槌依旧沉默。", "这只是异变的先声。\n正邪抬起头，望向更远的夜空。", 390)

func make_gate(x: float) -> void:
	gate_x = x
	gate = StaticBody2D.new()
	gate.position = Vector2(x, 290)
	gate.collision_layer = 32
	gate.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 1000)
	collider.shape = shape
	gate.add_child(collider)
	add_child(gate)

func spawn_encounter() -> void:
	encounter_active = true
	var stage: Array = stages[stage_index]
	var start: float = stage[0]
	make_gate(start + 660)
	wave_index = 0
	wave_count = 3 if int(room_id.right(1)) >= 3 else 2
	if stages[stage_index].size() > 2 and is_instance_valid(stages[stage_index][2]):
		var marker = stages[stage_index][2]
		if marker.wave_count_override > 0:
			wave_count = marker.wave_count_override
	if room_id == "regular_level1" and stage_index == 0:
		wave_count = 1
	spawn_wave()

func spawn_wave() -> void:
	wave_delay = 0.0
	var stage: Array = stages[stage_index]
	var start: float = stage[0]
	var lineup: Array = stage[1].duplicate()
	if wave_index % 2 == 1:
		lineup.reverse()
		objective = "蝶障 %d/%d · 波次 %d/%d" % [stage_index + 1, stages.size(), wave_index + 1, wave_count]
	enemies_left = lineup.size()
	for i in lineup.size():
		var enemy := CombatEnemy.new()
		enemy.kind = lineup[i]
		enemy.tier = int(room_id.right(1))
		enemy.position = Vector2(start + 150 + (i % 3) * 145, 581 if enemy.kind == CombatEnemy.Kind.KEDAMA else (365 + (i % 2) * 110))
		if enemy.position.distance_to(player.position) < 150:
			enemy.position.x = clampf(player.position.x + (190 if player.position.x < start + 350 else -190), start + 40, start + 600)
		enemy.defeated.connect(enemy_defeated)
		add_child(enemy)

func enemy_defeated(_enemy: CombatEnemy) -> void:
	enemies_left -= 1
	if enemies_left > 0:
		return
	wave_index += 1
	var recovery = load("res://scripts/world_pickup.gd").new()
	recovery.position = _enemy.position
	recovery.amount = 0
	recovery.healing = 22.0
	add_child(recovery)
	if wave_index < wave_count:
		wave_delay = 1.8
		objective = "蝶障尚未消散 · 月光碎片恢复生命 · 下一波即将到来"
		return
	encounter_active = false
	if is_instance_valid(gate):
		gate.queue_free()
	gate_x = 0
	stage_index += 1
	if stage_index >= stages.size():
		done = true
		Game.run.rooms[room_id] = true
		for door in doors:
			door.locked = false
		var reward := interactable("item", Vector2(width - 610, 577), "清场的馈赠", "F 领取一件道具")
		reward.key = room_id + "/clear"
		reward.item_id = ItemCatalog.IDS[Game.run.rng.randi_range(0, ItemCatalog.IDS.size() - 1)]
		reward.icon_texture = ItemCatalog.icon(reward.item_id)
		reward.detail = ItemCatalog.description(reward.item_id)
		objective = "道路已开启 · 领取道具并选择出口"

func _physics_process(delta: float) -> void:
	if wave_delay > 0.0 and not Game.finishing:
		wave_delay = maxf(0.0, wave_delay - delta)
		if wave_delay == 0.0:
			spawn_wave()
	if not done and not stages.is_empty() and not encounter_active and is_instance_valid(player):
		var trigger_distance := 370.0
		if stages[stage_index].size() > 2 and is_instance_valid(stages[stage_index][2]):
			trigger_distance = float(stages[stage_index][2].trigger_radius)
		trigger_distance = maxf(trigger_distance, 350.0)
		if player.position.x >= float(stages[stage_index][0]) - trigger_distance:
			spawn_encounter()
	queue_redraw()

func text(at: Vector2, content: String, size: int, color: Color) -> void:
	for line in content.split("\n"):
		draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		at.y += size * 1.65

func _draw() -> void:
	for sign in signs:
		text(sign[0], sign[1], 22, Color("#e8ddc8"))
		text(sign[0] + Vector2(0, 32), sign[2], 16, Color("#99b2b8"))
	if gate_x > 0:
		draw_rect(Rect2(gate_x - 6, 45, 12, 565), Color(0.8, 0.5, 0.7, 0.3))
		draw_line(Vector2(gate_x, 45), Vector2(gate_x, 610), Color("#df9fbf"), 2)
		text(Vector2(gate_x - 90, 200), "蝶障 · 击退敌人后消散", 15, Color("#dfb8ce"))
