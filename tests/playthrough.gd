extends Node
# A deterministic input-only playthrough. No damage, currency or health cheats.
var ready_to_play := false
var tick := 0
var elapsed := 0.0
var last_room := ""
var last_x := 0.0
var stationary := 0.0
var battle_route := false
var boss_only := false
var room_started := 0.0
var boss_direction := 1.0
var result_written := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	battle_route = OS.get_cmdline_user_args().has("--battle-route")
	boss_only = OS.get_cmdline_user_args().has("--boss-only")
	start.call_deferred()

func start() -> void:
	get_tree().current_scene = null
	Game.new_run(417)
	await get_tree().create_timer(0.8).timeout
	if boss_only:
		Game.enter_room("boss_room")
		await get_tree().create_timer(0.8).timeout
	ready_to_play = true

func tap(action: String) -> void:
	Input.action_press(action)

func _physics_process(delta: float) -> void:
	if not ready_to_play:
		return
	tick += 1
	elapsed += delta
	for action in ["jump", "interact", "skill1", "skill2", "drop"]:
		Input.action_release(action)
	if Game.run.outcome != "":
		if not result_written:
			result_written = true
			print("PLAYTHROUGH: %s elapsed=%.1f kills=%d hp=%.1f room=%s" % [Game.run.outcome, Game.run.elapsed, Game.run.kills, Game.player_stats.health, last_room])
			get_tree().quit(0)
		return
	if elapsed > 1200:
		push_error("PLAYTHROUGH TIMEOUT: room=%s x=%.1f stage=%d enemies=%d" % [last_room, Game.player_stats.player.position.x, Game.room.stage_index, Game.room.enemies_left])
		get_tree().quit(1)
		return
	if Game.transitioning or not is_instance_valid(Game.player_stats.player):
		return
	var player := Game.player_stats.player
	var room: Node2D = Game.room
	if last_room != room.room_id:
		print("ENTER: %s t=%.1f hp=%.1f items=%s" % [room.room_id, elapsed, Game.player_stats.health, str(Game.run.items)])
		last_room = room.room_id
		room_started = elapsed
		stationary = 0.0
	Input.action_press("shoot")
	var desired_x: float = room.width - 150
	var target: Node2D
	if room.room_id == "boss_room" and is_instance_valid(room.boss) and room.boss.targetable:
		var boss: Node2D = room.boss
		if player.position.x > 1220:
			boss_direction = -1
		if player.position.x < 180:
			boss_direction = 1
		desired_x = player.position.x + boss_direction * 400
		if boss.stage == "warn" and boss.attack_kind == 0 and boss.clock < 0.32 and player.is_on_floor():
			if Game.inversion.available:
				tap("skill2")
			else:
				tap("jump")
		if boss.stage == "warn" and boss.attack_kind == 1 and boss.clock < 0.25 and Game.guard.available:
			tap("skill1")
		if boss.stage == "warn" and boss.attack_kind == 3 and player.upside_down:
			tap("skill2")
	else:
		for object in get_tree().get_nodes_in_group("world_interactions"):
			if object.is_used() or object.locked:
				continue
			var eligible := false
			if object.kind == "item" and absf(object.position.y - 577) < 60:
				eligible = true
			elif object.kind == "shop":
				eligible = Game.player_stats.p_points >= object.price and (object.healing <= 0 or Game.player_stats.health < Game.player_stats.max_health - 15)
			elif object.kind == "heal":
				eligible = Game.player_stats.health < Game.player_stats.max_health
			elif object.kind in ["boss", "win"]:
				eligible = true
			elif object.kind == "exit":
				eligible = true
				if room.room_id == "regular_level1":
					eligible = object.target == ("regular_level2" if battle_route else "shop1")
				elif room.room_id == "regular_level4":
					eligible = object.target == ("healing_room2" if battle_route else "shop2")
			if eligible and (target == null or object.position.x < target.position.x):
				target = object
		if target != null:
			desired_x = target.position.x
			if player.global_position.distance_to(target.global_position) < 75 and tick % 2 == 0:
				tap("interact")
		# Do not ram the last enemy; shoot from readable midrange.
		if room.encounter_active:
			var nearest: Node2D
			var nearest_distance := INF
			for enemy in get_tree().get_nodes_in_group("combat_enemies"):
				var d := player.position.distance_to(enemy.position)
				if d < nearest_distance:
					nearest = enemy
					nearest_distance = d
			if nearest != null:
				if nearest_distance < 260 and player.clear_sight(nearest.position):
					desired_x = player.position.x + (170 if player.position.x > nearest.position.x else -170)
				elif nearest_distance < 510 and player.clear_sight(nearest.position):
					desired_x = player.position.x
				else:
					desired_x = nearest.position.x - 260
				if nearest.state == CombatEnemy.State.WARN and Game.guard.available and nearest_distance < 420:
					tap("skill1")
				if Game.inversion.available and tick % 2 == 0:
					tap("skill2")
	var direction := signf(desired_x - player.position.x) if absf(desired_x - player.position.x) > 20 else 0.0
	Input.action_release("move_left")
	Input.action_release("move_right")
	if direction > 0:
		Input.action_press("move_right")
	elif direction < 0:
		Input.action_press("move_left")
	if player.is_on_wall() and player.is_on_floor() and tick % 2 == 0:
		tap("jump")
	if target != null and player.upside_down and absf(player.position.x - target.position.x) < 90 and tick % 2 == 0:
		tap("skill2")
	if target != null and not player.upside_down and player.position.y < target.position.y - 65 and absf(player.position.x - target.position.x) < 90 and tick % 2 == 0:
		tap("drop")
	if absf(player.position.x - last_x) < 1.0:
		stationary += delta
	else:
		stationary = 0.0
	last_x = player.position.x
	if elapsed - room_started > 180 and int(elapsed) % 20 == 0 and tick % 60 == 0:
		print("PROGRESS: room=%s x=%.1f hp=%.1f stage=%d left=%d" % [last_room, player.position.x, Game.player_stats.health, room.stage_index, room.enemies_left])
