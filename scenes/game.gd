extends CanvasLayer

const ROOM_IDS := ["courtyard", "regular_level1", "regular_level2", "regular_level3", "regular_level4", "shop1", "shop2", "healing_room1", "healing_room2", "crack1", "crack2", "boss_room"]
@onready var player_stats: PlayerStats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect
var run := RunState.new()
@export var balance: RunBalance
@onready var guard: Skill = $Guard
@onready var inversion: Skill = $Inversion
@onready var revolution: Skill = $Revolution
@onready var rewards: RewardController = $Rewards
@onready var profile: JourneyProfile = $Profile
@onready var feedback: CombatFeedback = $FeedbackWorld/Feedback
var notice: String = ""
var notice_left: float = 0.0
var transitioning := false
var finishing := false
var room: Node2D
@onready var music: AudioStreamPlayer = $Music
var music_path := ""
var sound_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guard.cooldown = balance.guard_cooldown
	inversion.cooldown = balance.inversion_cooldown
	inversion.duration = balance.inversion_duration
	revolution.duration = balance.revolution_duration
	$RewardLayer/RewardScreen.bind_rewards(rewards)
	player_stats.die.connect(_on_player_died)
	player_stats.reset_run()
	music.finished.connect(func(): music.play())
	# Keep the existing device bindings; add only the missing keyboard actions.
	add_key("jump", KEY_W)
	add_key("drop", KEY_S)
	add_key("skill3", KEY_I)
	add_key("dodge", KEY_K)

func add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings") and not event.is_echo() and not transitioning and not rewards.active:
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not get_tree().paused:
		notice_left = maxf(0.0, notice_left - delta)
	if run.active and not transitioning and not get_tree().paused:
		run.elapsed += delta
		run.combo_left = maxf(0.0, run.combo_left - delta)
		if run.combo_left == 0.0:
			run.combo = 0

func new_run(seed_value: int = -1, challenge: bool = false) -> void:
	if transitioning:
		return
	run.reset(seed_value if seed_value >= 0 else int(Time.get_unix_time_from_system() * 1000))
	run.challenge = challenge and profile.victories > 0
	rewards.reset()
	guard.reset()
	inversion.reset()
	revolution.reset()
	player_stats.reset_run()
	finishing = false
	enter_room("regular_level1")
	rewards.offer("starter", "起行 · 选择你的打法", true)

func enter_room(id: String, entry: String = "entry") -> void:
	if transitioning or not ROOM_IDS.has(id):
		return
	transitioning = true
	get_tree().paused = false
	guard.cancel()
	inversion.cancel()
	revolution.cancel()
	feedback.clear()
	if is_instance_valid(player_stats.player):
		player_stats.player.operatable = false
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.18)
	await tween.finished
	run.room_id = id
	run.entry_id = entry
	var err := get_tree().change_scene_to_file("res://scenes/maps/%s.tscn" % id)
	if err != OK:
		push_error("Room failed: " + id)
		transitioning = false
		color_rect.color.a = 0.0
		if is_instance_valid(player_stats.player):
			player_stats.player.operatable = true
		return
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.2)
	await tween.finished
	transitioning = false
	if is_instance_valid(player_stats.player):
		player_stats.player.operatable = true
	rewards.resume_pending()

# Legacy scene hooks remain usable, but official exits use stable room IDs.
func change_scene(path: String) -> void:
	var target := path.get_file().get_basename()
	if ROOM_IDS.has(target):
		enter_room(target)

func finish_run(won: bool) -> void:
	if finishing or not run.active:
		return
	finishing = true
	_resolve_finish.call_deferred(won)

func _resolve_finish(won: bool) -> void:
	# Lethal damage on the same physics tick takes precedence over a boss kill.
	run.outcome = "胜利" if won and not player_stats.dead else "倒下"
	run.active = false
	rewards.reset()
	profile.record_run(run)
	guard.reset()
	inversion.reset()
	revolution.reset()
	sound("win" if run.outcome == "胜利" else "hurt")
	await get_tree().create_timer(0.7, false).timeout
	enter_room("courtyard")

func acquire_item(id: int) -> bool:
	if not ItemCatalog.IDS.has(id) or player_stats.dead:
		return false
	run.items[id] = int(run.items.get(id, 0)) + 1
	player_stats.recalculate(run.items)
	profile.discover(id)
	if id == 3:
		player_stats.health += 20
	sound("buy")
	return true

func notify(message: String, duration: float = 2.2) -> void:
	notice = message
	notice_left = duration

func gain_energy(amount: float) -> void:
	if revolution.active_left <= 0.0 and run.active:
		run.energy = clampf(run.energy + amount * player_stats.energy_multiplier, 0.0, 100.0)

func register_hit(at: Vector2, damage: float) -> void:
	feedback.hit(at, damage)
	gain_energy(balance.energy_per_hit)

func register_kill() -> void:
	run.combo += 1
	run.combo_left = 4.0
	run.best_combo = maxi(run.best_combo, run.combo)
	gain_energy(balance.energy_per_kill)
	player_stats.health += player_stats.kill_heal
	if run.combo % 5 == 0:
		add_points(10)
		notify("%d 连破！额外 +10 P" % run.combo)

func _on_player_died() -> void:
	if run.active and run.revives_left > 0 and is_instance_valid(player_stats.player):
		run.revives_left -= 1
		player_stats.dead = false
		player_stats.health = player_stats.max_health * balance.revive_fraction
		player_stats.player.immunity_left = balance.revive_immunity
		player_stats.player.hurt_left = 0.0
		for bullet: Node in get_tree().get_nodes_in_group("combat_bullets"):
			if not bullet.friendly:
				bullet.queue_free()
		feedback.pulse(player_stats.player.global_position, 250.0, Color("96f5d2"))
		notify("不屈 · 回复一半生命 · 短暂无敌", 3.0)
		sound("guard")
		return
	finish_run(false)

func purchase(key: String, id: int, price: int, healing: float = 0.0) -> String:
	if run.collected.has(key):
		return "已售罄"
	if healing > 0.0 and player_stats.health >= player_stats.max_health:
		return "生命已满"
	if player_stats.dead or not run.active:
		return "当前无法购买"
	if player_stats.p_points < price:
		return "还差 %d P" % (price - player_stats.p_points)
	if healing <= 0.0 and not ItemCatalog.IDS.has(id):
		return "商品不可用"
	run.collected[key] = true
	player_stats.p_points -= price
	if healing > 0:
		player_stats.health += healing
		sound("buy")
	else:
		acquire_item(id)
	return "已获得"

func add_points(amount: int) -> void:
	player_stats.p_points += amount
	run.total_points += amount

func play_music(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if path == music_path:
		return
	music_path = path
	if ResourceLoader.exists(path):
		music.stream = load(path)
		music.play()

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	sound_cache.clear()

func sound(kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not sound_cache.has(kind):
		var frequencies := {"shoot": 720.0, "hit": 180.0, "hurt": 95.0, "guard": 440.0, "invert": 330.0, "buy": 880.0, "win": 660.0}
		var freq: float = frequencies.get(kind, 440.0)
		var seconds := 0.07 if kind == "shoot" else 0.24
		var count := int(22050 * seconds)
		var bytes := PackedByteArray()
		bytes.resize(count * 2)
		for i in count:
			var t := float(i) / 22050.0
			var envelope := pow(1.0 - float(i) / count, 2.0)
			var sample := int(sin(TAU * freq * t * (1.0 + t)) * envelope * 8000)
			bytes.encode_s16(i * 2, sample)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = bytes
		sound_cache[kind] = stream
	var voice := AudioStreamPlayer.new()
	voice.stream = sound_cache[kind]
	voice.volume_db = -19.0 if kind == "shoot" else -10.0
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
