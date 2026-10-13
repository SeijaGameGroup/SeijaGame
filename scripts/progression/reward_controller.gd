class_name RewardController
extends Node

signal offered(choices: Array[int], heading: String)
signal closed
var presentation_enabled: bool = true
var auto_choose: bool = false
var active: bool = false
var choices: Array[int] = []
var _queue: Array[String] = []
var _headings: Dictionary = {}
var _current_key: String = ""

func reset() -> void:
	active = false
	_queue.clear()
	_current_key = ""
	choices.clear()
	closed.emit()
	get_tree().paused = false

func offer(key: String, heading: String, starter: bool = false) -> void:
	if Game.run.collected.has(key) or _queue.has(key) or key == _current_key:
		return
	if not Game.run.reward_options.has(key):
		var options: Array[int] = []
		if starter:
			options = [6, 9, 12]
		else:
			options = _roll(key)
		Game.run.reward_options[key] = options
	_queue.append(key)
	_headings[key] = heading
	_present.call_deferred()

func _roll(key: String) -> Array[int]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = Game.run.run_seed ^ key.hash()
	var pool: Array[int] = []
	for item_id: int in ItemCatalog.IDS:
		pool.append(item_id)
	var result: Array[int] = []
	# Favor undiscovered build pieces without forbidding useful duplicate stacks.
	for id: int in ItemCatalog.IDS:
		if Game.run.items.has(id) and pool.size() > 6:
			pool.erase(id)
	for index: int in 3:
		result.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return result

func _present() -> void:
	if active or _queue.is_empty() or not presentation_enabled or Game.finishing:
		return
	if Game.transitioning:
		return
	_current_key = _queue.pop_front()
	choices.clear()
	for item_id: Variant in Game.run.reward_options[_current_key]:
		choices.append(int(item_id))
	active = true
	if auto_choose:
		choose(0)
		return
	get_tree().paused = true
	offered.emit(choices, str(_headings[_current_key]))

func resume_pending() -> void:
	_present.call_deferred()

func choose(index: int) -> void:
	if not active or index < 0 or index >= choices.size():
		return
	if not Game.acquire_item(choices[index]):
		return
	Game.run.collected[_current_key] = true
	Game.notify("获得 " + ItemCatalog.title(choices[index]))
	active = false
	_current_key = ""
	closed.emit()
	get_tree().paused = false
	_present.call_deferred()
