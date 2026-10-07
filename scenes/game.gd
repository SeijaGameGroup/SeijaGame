extends CanvasLayer

const ROOM_IDS := ["courtyard", "regular_level1", "regular_level2", "regular_level3", "regular_level4", "shop1", "shop2", "healing_room1", "healing_room2", "crack1", "crack2", "boss_room"]
@onready var player_stats: PlayerStats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect
var run := RunState.new()
var guard: Skill
var inversion: Skill
var transitioning := false
var finishing := false
var room: Node2D
var music: AudioStreamPlayer
var music_path := ""
var sound_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guard = load("res://scenes/player/skills/skillID1.gd").new()
	inversion = load("res://scenes/player/skills/skillID2.gd").new()
	for skill in [guard, inversion]:
		add_child(skill)
		skill.process_mode = Node.PROCESS_MODE_PAUSABLE
	player_stats.die.connect(func(): finish_run(false))
	player_stats.reset_run()
	music = AudioStreamPlayer.new()
	music.volume_db = -20.0
	add_child(music)
	music.finished.connect(func(): music.play())
	# Keep the existing device bindings; add only the missing keyboard actions.
	add_key("jump", KEY_W)
	add_key("drop", KEY_S)
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	hud.add_child(load("res://ui/run_hud.gd").new())

func add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings") and not event.is_echo() and not transitioning:
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if run.active and not transitioning and not get_tree().paused:
		run.elapsed += delta

func new_run(seed_value: int = -1) -> void:
	if transitioning:
		return
	run.reset(seed_value if seed_value >= 0 else int(Time.get_unix_time_from_system() * 1000))
	guard.reset()
	inversion.reset()
	player_stats.reset_run()
	finishing = false
	enter_room("regular_level1")

func enter_room(id: String, entry: String = "entry") -> void:
	if transitioning or not ROOM_IDS.has(id):
		return
	transitioning = true
	get_tree().paused = false
	guard.cancel()
	inversion.cancel()
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
	guard.reset()
	inversion.reset()
	sound("win" if run.outcome == "胜利" else "hurt")
	await get_tree().create_timer(0.7, false).timeout
	enter_room("courtyard")

func acquire_item(id: int) -> bool:
	if not ItemCatalog.IDS.has(id) or player_stats.dead:
		return false
	run.items[id] = int(run.items.get(id, 0)) + 1
	player_stats.recalculate(run.items)
	if id == 3:
		player_stats.health += 20
	sound("buy")
	return true

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
