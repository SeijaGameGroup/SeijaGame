extends Node
var failures := 0
var checks := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run_tests.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func visit(id: String) -> void:
	Game.enter_room(id)
	await frames(45)
	check(Game.run.room_id == id and not Game.transitioning, "room transition " + id)

func run_tests() -> void:
	# Keep the runner alive while current_scene changes.
	get_tree().current_scene = null
	var stats := Stats.new()
	var deaths := [0]
	stats.die.connect(func(): deaths[0] += 1)
	stats.reset_health(100)
	stats.take_damage(120)
	stats.take_damage(120)
	check(stats.health == 0 and deaths[0] == 1, "lethal damage stores zero and emits death once")
	stats.reset_health(100)
	stats.health = 180
	check(stats.health == 100 and not stats.dead, "healing clamps and reset revives")
	stats.free()
	var state := RunState.new()
	state.reset(417)
	var stock_a := state.stock("shop1").duplicate()
	state.stock("shop2")
	check(state.stock("shop1") == stock_a, "shop stock survives visits")
	state.reset(417)
	state.stock("shop2")
	check(state.stock("shop1") == stock_a and stock_a.size() == 3, "seeded stock independent of route order")
	Game.new_run(417)
	await frames(45)
	check(Game.run.active and not Game.transitioning, "new run enters first combat room")
	var player := Game.player_stats.player
	check(is_instance_valid(player) and player.can_act(), "player binds to current run")
	var counts := {1: 99, 2: 99, 3: 2, 4: 2, 5: 99, 7: 99, 8: 99, 9: 2}
	Game.player_stats.recalculate(counts)
	check(Game.player_stats.max_health == 190 and is_equal_approx(Game.player_stats.damage_multipler_item, 1.3), "health and damage items calculate additively")
	check(Game.player_stats.damage_reduction_rate_item <= 0.56 and Game.player_stats.extra_shot_chance <= 0.8 and Game.player_stats.gravity_multiplier_item >= 0.4, "item stacking is bounded")
	Game.player_stats.recalculate(counts)
	check(Game.player_stats.max_health == 190, "recalculation is idempotent")
	Game.player_stats.recalculate({})
	Game.guard.skill_pressed()
	var before := Game.player_stats.health
	check(not player.receive_damage(20, player.position), "guard rejects damage")
	check(Game.player_stats.health == before, "guard preserves health")
	Game.guard.cancel()
	check(player.receive_damage(20, player.position + Vector2.LEFT), "ordinary damage accepted")
	var damaged := Game.player_stats.health
	check(not player.receive_damage(20, player.position), "hurt immunity rejects repeated damage")
	await frames(10)
	check(player.hurt_left == 0 and player.immunity_left > 0 and player.can_act(), "control returns before immunity expires")
	await frames(50)
	Game.guard.reset()
	Game.inversion.skill_pressed()
	await frames(100)
	check(player.upside_down and player.position.y >= player.ceiling_y + 21, "inversion reaches a bounded upper edge")
	var bound := player.position.y
	await frames(80)
	check(absf(player.position.y - bound) < 2, "upper-edge walking does not drift upward")
	Game.guard.skill_pressed()
	check(Game.guard.active_left > 0 and player.upside_down, "guard and inversion coexist")
	Game.inversion.cancel()
	check(Game.guard.active_left > 0 and not player.upside_down, "cancel inversion preserves guard")
	var cooldown := Game.inversion.remaining
	await visit("shop1")
	check(Game.inversion.active_left == 0 and Game.inversion.remaining > 0 and Game.inversion.remaining < cooldown, "transition cancels duration but preserves cooldown")
	Game.player_stats.p_points = 100
	Game.player_stats.health = Game.player_stats.max_health
	check(Game.purchase("test/heal", 1, 15, 55) == "生命已满" and Game.player_stats.p_points == 100, "full health purchase costs nothing")
	check(Game.purchase("test/item", 4, 30) == "已获得" and Game.player_stats.p_points == 70, "purchase applies item and deducts once")
	Game.purchase("test/item", 4, 30)
	check(Game.player_stats.p_points == 70 and Game.run.items.get(4) == 1, "sold item cannot be purchased twice")
	Game.player_stats.p_points = 0
	check(Game.purchase("test/poor", 2, 25).begins_with("还差") and not Game.run.collected.has("test/poor"), "insufficient funds preserve stock")
	var damage_mult := Game.player_stats.damage_multipler_item
	for id in ["regular_level2", "healing_room1", "crack1", "regular_level3", "regular_level4", "shop2", "healing_room2", "crack2"]:
		await visit(id)
	check(Game.player_stats.damage_multipler_item == damage_mult and Game.run.items.get(4) == 1, "all routes preserve items without reapplying")
	await visit("regular_level1")
	player = Game.player_stats.player
	player.position = Vector2(552, 400)
	player.velocity = Vector2.ZERO
	await frames(45)
	check(player.is_on_floor() and absf(player.global_position.y - 507.0) < 0.1, "player lands on platform upper edge")
	player.set_inverted(true)
	player.global_position.y = 0.0
	player.velocity = Vector2.ZERO
	await frames(5)
	check(absf(player.global_position.y - (player.ceiling_y + player.body_half_height)) < 0.1, "inverted player rests on ceiling edge")
	var sprite_top: Vector2 = player.graphics.global_transform * player.graphics.get_rect().position
	check(player.graphics.flip_v and sprite_top.y >= player.ceiling_y - 2.0, "inverted sprite clears ceiling")
	player.set_inverted(false)
	var upper_chest: Node2D = Game.room.get_node("UpperChest")
	var upper_chest_position := upper_chest.position
	player.position = Vector2(1760, 581)
	player.velocity = Vector2.ZERO
	player.facing_direction = 1.0
	await frames(90)
	var camera_center := player.camera_2d.global_position.x
	player.facing_direction = -1.0
	await frames(5)
	check(absf(player.camera_2d.global_position.x - camera_center) < 1.0, "camera stays steady when facing changes at room center")
	player.global_position.x = camera_center + 60.0
	await frames(5)
	check(absf(player.camera_2d.global_position.x - camera_center) < 1.0, "camera deadzone absorbs small center movement")
	player.position.x = 310
	await frames(3)
	check(Game.room.enemies_left == 2 and Game.room.encounter_active, "first encounter starts at its authored trigger")
	for enemy in get_tree().get_nodes_in_group("combat_enemies"):
		enemy.receive_damage(10000, player.position)
	await frames(3)
	check(Game.room.stage_index == 1 and not Game.room.encounter_active and Game.room.gate_x == 0, "defeat opens encounter barrier")
	for index in [1, 2]:
		player.position.x = float(Game.room.stages[index][0]) - 350
		await frames(3)
		while Game.room.stage_index == index:
			for enemy in get_tree().get_nodes_in_group("combat_enemies"):
				enemy.receive_damage(10000, player.position)
			await frames(120)
	check(Game.run.rooms.has("regular_level1") and not Game.room.doors[0].locked, "clear room persists and unlocks both routes")
	check(is_instance_valid(upper_chest) and upper_chest.position == upper_chest_position, "upper chest remains after all encounter waves")
	# Player input uses actual physics ticks; holding jump must not auto-bounce.
	await visit("shop1")
	var shop_objects := get_tree().get_nodes_in_group("world_interactions")
	var shop_positions: Array[Vector2] = []
	for object in shop_objects:
		if object.kind == "shop":
			shop_positions.append(object.position)
	check(shop_positions.size() == 4 and shop_positions[0] != shop_positions[1] and shop_positions[1] != shop_positions[2], "shop keeps four independent shelves")
	var pickup: Node2D = load("res://scripts/world_pickup.gd").new()
	pickup.position = Game.player_stats.player.global_position + Vector2(600, 0)
	var pickup_start := pickup.position.distance_to(Game.player_stats.player.global_position)
	get_tree().current_scene.add_child(pickup)
	await frames(70)
	check((not is_instance_valid(pickup)) or pickup.position.distance_to(Game.player_stats.player.global_position) < pickup_start, "distant loot homes toward the player")
	pickup.queue_free()
	player = Game.player_stats.player
	Input.action_press("jump")
	await frames(70)
	check(player.is_on_floor(), "held jump lands without automatic repeat")
	Input.action_release("jump")
	await frames(2)
	Game.guard.reset()
	Game.guard.skill_pressed()
	var pause_remaining := Game.guard.remaining
	get_tree().paused = true
	await frames(30)
	check(Game.guard.remaining == pause_remaining, "pause freezes cooldowns")
	get_tree().paused = false
	Game.guard.reset()
	Input.action_press("shoot")
	await frames(20)
	var shots := player.shot_count
	check(shots >= 2, "holding J produces continuous fire")
	player.operatable = false
	await frames(30)
	check(player.shot_count == shots, "disabled player cannot shoot through timer callbacks")
	Input.action_release("shoot")
	player.operatable = true
	await visit("boss_room")
	Game.room.start_boss()
	var boss: Node2D = Game.room.boss
	check(boss.targetable and boss.stage != "dormant", "F core activation starts boss")
	boss.receive_damage(2500, Vector2.ZERO)
	check(boss.phase == 2 and boss.stage == "phase", "boss transitions at half health")
	await frames(130)
	boss.receive_damage(3000, Vector2.ZERO)
	check(boss.dead and Game.room.doors[0].kind == "win" and not Game.room.doors[0].locked, "boss death opens victory interaction")
	Game.finish_run(true)
	await frames(95)
	check(Game.run.outcome == "胜利" and Game.run.room_id == "courtyard", "victory returns to scene-based courtyard")
	Game.new_run(81)
	await frames(45)
	check(Game.run.items.is_empty() and Game.run.collected.is_empty() and Game.player_stats.health == 150 and Game.guard.remaining == 0 and Game.inversion.remaining == 0, "restart fully resets the run")
	Game.player_stats.take_damage(999)
	Game.finish_run(true)
	await frames(95)
	check(Game.run.outcome == "倒下" and Game.run.room_id == "courtyard", "same-frame death takes priority over victory")
	Game.new_run(82)
	await frames(45)
	check(Game.run.active and not Game.player_stats.dead, "restart after death works")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
