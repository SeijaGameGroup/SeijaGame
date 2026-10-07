class_name ItemCatalog
extends RefCounted

const IDS: Array[int] = [1, 2, 3, 4, 5, 7, 8, 9]
static var textures: Dictionary = {}
const DATA := {
	1: ["量贩型小麻薯", "额外射弹概率 +10%", "连射", 28],
	2: ["魔女扫帚", "移动速度 +15%", "疾行", 25],
	3: ["伊吹瓢", "生命上限 +20，回复 20", "生存", 30],
	4: ["御币", "所有射弹伤害 +15%", "火力", 30],
	5: ["子安贝", "受到伤害 -8%（上限 56%）", "守护", 28],
	7: ["闪避布残片", "H 防护时间 +0.25 秒", "防护", 25],
	8: ["轻身伞", "下落速度 -15%，不影响起跳", "浮游", 22],
	9: ["逆鳞", "反转期间射弹伤害 +30%", "逆转", 30],
}
static func title(id: int) -> String:
	return DATA[id][0]
static func description(id: int) -> String:
	return DATA[id][1]
static func icon(id: int) -> Texture2D:
	if not textures.has(id):
		if id <= 5:
			textures[id] = load("res://assets/pictures/items/itemID%d.png" % id)
		else:
			textures[id] = load("res://assets/pictures/" + ("energy.png" if id == 9 else "circle.png"))
	return textures[id]
