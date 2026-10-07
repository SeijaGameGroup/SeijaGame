class_name CombatEnemy
extends CharacterBody2D

signal defeated(enemy: CombatEnemy)
enum Kind { BUTTERFLY, KEDAMA, RED, GREEN }
enum State { IDLE, WARN, ATTACK, RECOVER }
var kind := Kind.BUTTERFLY
var state := State.IDLE
var health := 60.0
var max_health := 60.0
var dead := false
var targetable := true
var clock := 0.7
var home := Vector2.ZERO
var aim := Vector2.ZERO
var attack_direction := Vector2.LEFT
var hit_flash := 0.0
var sprite: Sprite2D
var tier := 1
var contact_left := 0.0
var visible_radius := 22.0

func _ready() -> void:
	add_to_group("combat_enemies")
	collision_layer = 2
	collision_mask = 32 | 256
	home = position
	max_health = (72.0 if kind == Kind.KEDAMA else 48.0) + tier * 8.0
	health = max_health
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 21.0
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	var textures := ["butterfly_sprite.png", "kendama.png", "spirit2.png", "spirit1.png"]
	sprite.texture = load("res://assets/pictures/" + textures[kind])
	sprite.scale = Vector2(0.64, 0.64)
	if kind == Kind.BUTTERFLY:
		sprite.hframes = 2
	add_child(sprite)
	clock += fmod(position.x, 11.0) * 0.06

func sees_player() -> bool:
	var player := Game.player_stats.player
	if not is_instance_valid(player) or Game.player_stats.dead or not targetable:
		return false
	return player.in_view(global_position) and global_position.distance_to(player.global_position) < 760 and player.clear_sight(global_position)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(Game.player_stats.player):
		return
	var player := Game.player_stats.player
	if Game.finishing or Game.transitioning:
		return
	clock -= delta
	hit_flash = maxf(0, hit_flash - delta)
	contact_left = maxf(0, contact_left - delta)
	if kind == Kind.BUTTERFLY:
		sprite.frame = int(Time.get_ticks_msec() / 160) % 2
	sprite.modulate = Color("#ffffff") if hit_flash <= 0 else Color("#ffbcb8")
	sprite.flip_h = player.global_position.x < global_position.x
	if kind == Kind.KEDAMA:
		velocity.y += 1500 * delta
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 1100 * delta)
			if kind != Kind.KEDAMA:
				velocity.y = (home.y + sin(Time.get_ticks_msec() * 0.002 + home.x) * 15 - global_position.y) * 2
			if clock <= 0 and sees_player():
				state = State.WARN
				clock = 0.65 if kind == Kind.BUTTERFLY else 0.85
				aim = player.global_position
				attack_direction = global_position.direction_to(aim)
		State.WARN:
			velocity.x = move_toward(velocity.x, 0, 1800 * delta)
			if kind != Kind.KEDAMA:
				velocity.y = 0
			if clock <= 0:
				# Never start a new off-screen or through-wall attack.
				if not sees_player():
					state = State.IDLE
					clock = 0.6
				else:
					begin_attack()
		State.ATTACK:
			if kind == Kind.BUTTERFLY:
				velocity = attack_direction * 390
			if clock <= 0 or (kind == Kind.BUTTERFLY and is_on_wall()) or (kind == Kind.KEDAMA and is_on_floor() and velocity.y >= 0):
				state = State.RECOVER
				clock = 1.1
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0, 1000 * delta)
			if kind != Kind.KEDAMA:
				velocity.y = move_toward(velocity.y, 0, 1000 * delta)
			if clock <= 0:
				state = State.IDLE
				clock = 0.5
				# Approach between attacks to remain reachable without homing contact damage.
				if kind != Kind.KEDAMA:
					home.x = clampf(player.global_position.x + (180 if global_position.x > player.global_position.x else -180), 100, Game.room.width - 100)
					home.y = clampf(player.global_position.y - 95, 160, 470)
	if kind != Kind.KEDAMA and state == State.IDLE:
		var desired := Vector2(home.x - global_position.x, 0).limit_length(65)
		velocity.x = move_toward(velocity.x, desired.x, delta * 100)
	move_and_slide()
	global_position.x = clampf(global_position.x, 32, Game.room.width - 32)
	global_position.y = clampf(global_position.y, 105, 589)
	if state == State.ATTACK and kind <= Kind.KEDAMA and global_position.distance_to(player.global_position) < 42 and contact_left <= 0:
		player.receive_damage(12 + tier * 2, global_position)
		contact_left = 0.8
	if global_position.y > 920:
		global_position = home
	queue_redraw()

func begin_attack() -> void:
	state = State.ATTACK
	clock = 0.6
	match kind:
		Kind.BUTTERFLY:
			velocity = attack_direction * 390
		Kind.KEDAMA:
			var dx := clampf(aim.x - global_position.x, -300, 300)
			velocity = Vector2(dx / 0.75, -570)
			clock = 1.2
		Kind.RED, Kind.GREEN:
			var direction := attack_direction if kind == Kind.RED else Vector2(signf(attack_direction.x), 0)
			var count := 3 if kind == Kind.RED else 5
			for i in count:
				var angle := (i - (count - 1) / 2.0) * (0.15 if kind == Kind.RED else 0.26)
				var bullet := CombatBullet.new()
				bullet.position = global_position + direction * 30
				bullet.velocity = direction.rotated(angle) * (225 + tier * 12)
				bullet.damage = 10 + tier
				get_parent().add_child(bullet)
			state = State.RECOVER
			clock = 1.5

func receive_damage(amount: float, _source: Vector2) -> bool:
	if dead or not targetable:
		return false
	health = maxf(0, health - amount)
	hit_flash = 0.1
	Game.sound("hit")
	if health == 0:
		dead = true
		targetable = false
		collision_layer = 0
		Game.run.kills += 1
		var pickup = load("res://scripts/world_pickup.gd").new()
		pickup.position = global_position
		pickup.amount = Game.run.rng.randi_range(7, 11)
		get_parent().add_child(pickup)
		defeated.emit(self)
		queue_free()
	return true

func _draw() -> void:
	if health < max_health:
		draw_rect(Rect2(-25, -43, 50, 3), Color("#302a46"))
		draw_rect(Rect2(-25, -43, 50 * health / max_health, 3), Color("#e49caa"))
	if state == State.WARN:
		draw_arc(Vector2.ZERO, 34, 0, TAU, 24, Color("#ffd291"), 2)
		if kind == Kind.KEDAMA:
			var point := to_local(Vector2(aim.x, 605))
			draw_line(point - Vector2(32, 0), point + Vector2(32, 0), Color("#ffd291"), 3)
		else:
			draw_line(Vector2.ZERO, attack_direction * 90, Color(1, 0.75, 0.5, 0.6), 2)
