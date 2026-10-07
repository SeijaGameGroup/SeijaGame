class_name RunState
extends RefCounted

var run_seed: int
var rng := RandomNumberGenerator.new()
var items: Dictionary = {}
var rooms: Dictionary = {}
var stocks: Dictionary = {}
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
