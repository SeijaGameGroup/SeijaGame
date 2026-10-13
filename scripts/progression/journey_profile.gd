class_name JourneyProfile
extends Node

@export var persistence_enabled: bool = true
@export var save_path: String = "user://journey_v1.cfg"
var victories: int = 0
var attempts: int = 0
var best_rooms: int = 0
var discoveries: Array[int] = []
var last_outcome: String = ""

func _ready() -> void:
	# Test scenes must never alter the player's real progress.
	for arg: String in OS.get_cmdline_args():
		if arg.contains("tests/") or arg.contains("tests\\"):
			persistence_enabled = false
	if persistence_enabled:
		load_profile()

func discover(id: int) -> void:
	if not discoveries.has(id):
		discoveries.append(id)
		store_profile()

func record_run(run: RunState) -> void:
	attempts += 1
	victories += 1 if run.outcome == "胜利" else 0
	best_rooms = maxi(best_rooms, run.rooms.size())
	last_outcome = run.outcome
	store_profile()

func store_profile() -> void:
	if not persistence_enabled:
		return
	var config: ConfigFile = ConfigFile.new()
	config.set_value("journey", "version", 1)
	config.set_value("journey", "victories", victories)
	config.set_value("journey", "attempts", attempts)
	config.set_value("journey", "best_rooms", best_rooms)
	config.set_value("journey", "discoveries", discoveries)
	config.set_value("journey", "last_outcome", last_outcome)
	var error: Error = config.save(save_path)
	if error != OK:
		push_warning("旅程记录保存失败: " + error_string(error))

func load_profile() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	victories = maxi(0, int(config.get_value("journey", "victories", 0)))
	attempts = maxi(0, int(config.get_value("journey", "attempts", 0)))
	best_rooms = maxi(0, int(config.get_value("journey", "best_rooms", 0)))
	last_outcome = str(config.get_value("journey", "last_outcome", ""))
	var saved: Variant = config.get_value("journey", "discoveries", [])
	if saved is Array:
		for id: Variant in saved:
			if id is int and ItemCatalog.IDS.has(id) and not discoveries.has(id):
				discoveries.append(id)
