extends Control

@onready var title: Label = $Panel/Title
@onready var summary: Label = $Panel/Summary
@onready var journal: Label = $Panel/Journal
@onready var start: Button = $Panel/Start
@onready var challenge: Button = $Panel/Challenge

func _ready() -> void:
	start.pressed.connect(func() -> void: Game.new_run())
	challenge.pressed.connect(func() -> void: Game.new_run(-1, true))

func _process(_delta: float) -> void:
	visible = is_instance_valid(Game.room) and Game.run.room_id == "courtyard" and not Game.transitioning
	if not visible:
		return
	title.text = "逆旅 · 把逆境还给世界" if Game.run.outcome.is_empty() else ("天光初现 · 旅程完成" if Game.run.outcome == "胜利" else "暂歇月下 · 再试一种打法")
	var first: String = "选择起手宝物 → 击破蝶障 → 自由构筑 → 挑战异化蝶魁"
	if not Game.run.outcome.is_empty():
		first = "%s  ·  %02d:%02d  ·  击败 %d  ·  最高连击 %d" % [Game.run.outcome, int(Game.run.elapsed) / 60, int(Game.run.elapsed) % 60, Game.run.kills, Game.run.best_combo]
	summary.text = first + "\n每局一次「不屈」救场。倒下也会保留道具发现记录。\nJ 射击 · K 冲刺 · H 弹反 · U 倒置爆发 · I 革命"
	var discovered: PackedStringArray = []
	for id: int in Game.profile.discoveries:
		discovered.append(ItemCatalog.title(id))
	journal.text = "蝶迹手记  %d / 13\n通关 %d 次 · 最远清理 %d 处\n%s" % [discovered.size(), Game.profile.victories, Game.profile.best_rooms, "尝试穿透、散射、倒置与反击构筑，收集全部宝物。" if discovered.is_empty() else "已发现：" + " · ".join(discovered)]
	challenge.disabled = Game.profile.victories == 0
	challenge.text = "异变再临 · 敌人强化 35%" if not challenge.disabled else "首次通关后解锁 · 异变再临"
	start.text = "选择宝物，启程" if Game.run.outcome.is_empty() else "带着新思路，再来一局"
