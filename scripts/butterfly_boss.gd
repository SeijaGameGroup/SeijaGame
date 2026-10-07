extends CharacterBody2D
signal defeated
var health := 4800.0
var max_health := 4800.0
var dead := false
var targetable := false
var phase := 1
var stage := "dormant"
var clock := 0.0
var attack_index := 0
var aim := Vector2.ZERO
var origin := Vector2.ZERO
var sprite: Sprite2D
var hit_flash := 0.0
var attack_kind := 0
var battle_time := 0.0

func _ready() -> void:
	add_to_group("combat_enemies")
	collision_layer = 2
	collision_mask = 32
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 49
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/pictures/butterfly_sprite.png")
	sprite.hframes = 2
	sprite.scale = Vector2(1.65, 1.65)
	add_child(sprite)
	origin = global_position

func activate() -> void:
	if stage != "dormant":
		return
	targetable = true
	stage = "recover"
	clock = 1.8
	Game.play_music("res://assets/audio/boss.wav")

func _physics_process(delta: float) -> void:
	if dead or stage == "dormant" or Game.finishing or Game.transitioning:
		return
	battle_time += delta
	clock -= delta
	hit_flash = maxf(0, hit_flash - delta)
	sprite.frame = int(Time.get_ticks_msec() / 130) % 2
	sprite.modulate = Color("#ebafdc") if phase == 2 else Color.WHITE
	if hit_flash > 0:
		sprite.modulate = Color("#ffdbbd")
	var player := Game.player_stats.player
	if not is_instance_valid(player):
		return
	sprite.flip_h = player.global_position.x > global_position.x
	match stage:
		"recover":
			global_position = global_position.move_toward(origin + Vector2(0, sin(battle_time) * 35), delta * 180)
			if clock <= 0:
				prepare_attack()
		"warn":
			if clock <= 0:
				execute_attack()
		"attack":
			if attack_kind == 1:
				global_position = global_position.move_toward(aim, delta * 620)
				if global_position.distance_to(player.global_position) < 62:
					player.receive_damage(22, global_position)
			if clock <= 0:
				stage = "recover"
				clock = 1.8 if phase == 1 else 1.4
		"phase":
			if clock <= 0:
				stage = "recover"
				clock = 1.0
	queue_redraw()

func prepare_attack() -> void:
	stage = "warn"
	clock = 1.15
	attack_kind = attack_index % (3 if phase == 1 else 4)
	attack_index += 1
	aim = Game.player_stats.player.global_position
	if attack_kind == 0:
		var hazard = load("res://scripts/boss_hazard.gd").new()
		hazard.rect = Rect2(24, 550, Game.room.width - 48, 60)
		get_parent().add_child(hazard)
	elif attack_kind == 3:
		var hazard = load("res://scripts/boss_hazard.gd").new()
		hazard.rect = Rect2(24, 65, Game.room.width - 48, 115)
		get_parent().add_child(hazard)
	if attack_kind == 1:
		aim.x = clampf(aim.x, 90, Game.room.width - 90)
		aim.y = clampf(aim.y, 145, 535)

func execute_attack() -> void:
	stage = "attack"
	clock = 0.85
	if attack_kind == 2:
		var direction := global_position.direction_to(aim)
		# A broad fan with a deliberate central lane; no random unavoidable patterns.
		for i in range(-5, 6):
			if i == 0:
				continue
			var bullet := CombatBullet.new()
			bullet.position = global_position
			bullet.velocity = direction.rotated(i * 0.15) * (210 if phase == 1 else 255)
			bullet.damage = 16
			bullet.radius = 7
			get_parent().add_child(bullet)

func clear_danger() -> void:
	for node in get_tree().get_nodes_in_group("combat_bullets"):
		if not node.friendly:
			node.queue_free()
	for node in get_tree().get_nodes_in_group("boss_hazards"):
		node.queue_free()

func receive_damage(amount: float, _source: Vector2) -> bool:
	if dead or not targetable or stage == "phase":
		return false
	health = maxf(0, health - amount)
	hit_flash = 0.08
	if health <= 0:
		dead = true
		targetable = false
		collision_layer = 0
		clear_danger()
		Game.run.kills += 1
		Game.run.rooms["boss_room"] = true
		Game.sound("win")
		defeated.emit()
		hide()
	elif phase == 1 and health <= max_health * 0.5:
		phase = 2
		stage = "phase"
		clock = 2.0
		clear_danger()
	return true

func _draw() -> void:
	if stage == "warn":
		draw_arc(Vector2.ZERO, 95, 0, TAU, 48, Color("#ffd291"), 3)
		if attack_kind == 1:
			var point := to_local(aim)
			draw_line(Vector2.ZERO, point, Color(1, 0.6, 0.6, 0.55), 3)
			draw_arc(point, 45, 0, TAU, 24, Color("#ffd291"), 2)
	if phase == 2:
		draw_arc(Vector2.ZERO, 85, battle_time, battle_time + PI * 1.5, 40, Color("#d998e4"), 2)
