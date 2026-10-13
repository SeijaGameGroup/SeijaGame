class_name RunState
extends RefCounted

var run_seed: int
var rng := RandomNumberGenerator.new()
var items: Dictionary = {}
var rooms: Dictionary = {}
var stocks: Dictionary = {}
var reward_options: Dictionary = {}
var energy: float = 50.0
var revives_left: int = 1
var combo: int = 0
var best_combo: int = 0
var combo_left: float = 0.0
var damage_taken: float = 0.0
var challenge: bool = false
var collected: Dictionary = {}
var elapsed := 0.0
var kills := 0
var total_points := 0
var outcome := ""
var active := false
var room_id := "courtyard"
var entry_id := "entry"

func reset(seed_value: int) -> void:
	run_seed = seed_value
	rng.seed = run_seed
	items.clear()
	rooms.clear()
	stocks.clear()
	reward_options.clear()
	energy = 50.0
	revives_left = 1
	combo = 0
	best_combo = 0
	combo_left = 0.0
	damage_taken = 0.0
	collected.clear()
	elapsed = 0.0
	kills = 0
	total_points = 0
	outcome = ""
	active = true
	room_id = "regular_level1"
	entry_id = "entry"

func stock(id: String) -> Array:
	if not stocks.has(id):
		# A separate stream prevents shop rerolls through route order.
		var local_rng := RandomNumberGenerator.new()
		local_rng.seed = run_seed ^ id.hash()
		var pool := ItemCatalog.IDS.duplicate()
		var result: Array = []
		for i in 3:
			var index := local_rng.randi_range(0, pool.size() - 1)
			result.append(pool.pop_at(index))
		stocks[id] = result
	return stocks[id]
