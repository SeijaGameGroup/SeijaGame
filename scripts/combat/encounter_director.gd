extends Node

@onready var _room: Node2D = get_parent() as Node2D

func make_gate(x: float) -> void:
	_room.gate_x = x
	_room.gate = StaticBody2D.new()
	_room.gate.position = Vector2(x, 290)
	_room.gate.collision_layer = 32
	_room.gate.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 1000)
	collider.shape = shape
	_room.gate.add_child(collider)
	add_child(_room.gate)

func spawn_encounter() -> void:
	_room.encounter_active = true
	var stage: Array = _room.stages[_room.stage_index]
	var start: float = stage[0]
	make_gate(start + 660)
	_room.wave_index = 0
	_room.wave_count = 2
	if _room.stages[_room.stage_index].size() > 2 and is_instance_valid(_room.stages[_room.stage_index][2]):
		var marker: EncounterMarker = _room.stages[_room.stage_index][2]
		if marker.wave_count_override > 0:
			_room.wave_count = marker.wave_count_override
	if _room.room_id == "regular_level1" and _room.stage_index == 0:
		_room.wave_count = 1
	spawn_wave()

func spawn_wave() -> void:
	_room.wave_delay = 0.0
	var stage: Array = _room.stages[_room.stage_index]
	var start: float = stage[0]
	var lineup: Array = stage[1].duplicate()
	if _room.wave_index % 2 == 1:
		lineup.reverse()
		_room.objective = "蝶障 %d/%d · 波次 %d/%d" % [_room.stage_index + 1, _room.stages.size(), _room.wave_index + 1, _room.wave_count]
	_room.enemies_left = lineup.size()
	for i: int in lineup.size():
		var enemy: CombatEnemy = preload("res://scenes/moster/combat_enemy.tscn").instantiate()
		enemy.kind = lineup[i]
		enemy.tier = int(_room.room_id.right(1))
		enemy.position = Vector2(start + 150 + (i % 3) * 145, 581 if enemy.kind == CombatEnemy.Kind.KEDAMA else (365 + (i % 2) * 110))
		if enemy.position.distance_to(_room.player.position) < 150:
			enemy.position.x = clampf(_room.player.position.x + (190 if _room.player.position.x < start + 350 else -190), start + 40, start + 600)
		enemy.defeated.connect(enemy_defeated)
		add_child(enemy)

func enemy_defeated(_enemy: CombatEnemy) -> void:
	_room.enemies_left -= 1
	if _room.enemies_left > 0:
		return
	_room.wave_index += 1
	var recovery: Node2D = load("res://scripts/world_pickup.gd").new()
	recovery.position = _enemy.position
	recovery.amount = 0
	recovery.healing = Game.balance.wave_healing
	add_child(recovery)
	if _room.wave_index < _room.wave_count:
		_room.wave_delay = 1.8
		_room.objective = "蝶障尚未消散 · 月光碎片恢复生命 · 下一波即将到来"
		return
	_room.encounter_active = false
	if is_instance_valid(_room.gate):
		_room.gate.queue_free()
	_room.gate_x = 0
	_room.stage_index += 1
	var reward_key: String = _room.room_id + "/encounter/" + str(_room.stage_index)
	if not Game.run.reward_options.has(reward_key) and not Game.run.collected.has(reward_key):
		Game.add_points(Game.balance.stage_points)
		Game.gain_energy(15.0)
	Game.rewards.offer(reward_key, "蝶障击破 · 选择一件宝物")
	if _room.stage_index >= _room.stages.size():
		_room.done = true
		Game.run.rooms[_room.room_id] = true
		for door in _room.doors:
			door.locked = false
		_room.objective = "道路已开启 · 高处仍有宝物 · 选择下一条路线"

func _physics_process(delta: float) -> void:
	if _room.wave_delay > 0.0 and not Game.finishing:
		_room.wave_delay = maxf(0.0, _room.wave_delay - delta)
		if _room.wave_delay == 0.0:
			spawn_wave()
	if not _room.done and not _room.stages.is_empty() and not _room.encounter_active and is_instance_valid(_room.player):
		var trigger_distance: float = 370.0
		if _room.stages[_room.stage_index].size() > 2 and is_instance_valid(_room.stages[_room.stage_index][2]):
			trigger_distance = float(_room.stages[_room.stage_index][2].trigger_radius)
		trigger_distance = maxf(trigger_distance, 350.0)
		if _room.player.position.x >= float(_room.stages[_room.stage_index][0]) - trigger_distance:
			spawn_encounter()
	_room.queue_redraw()

