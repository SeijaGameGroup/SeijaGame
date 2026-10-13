extends Node
func _ready() -> void:
	Game.profile.persistence_enabled = false
	Game.rewards.presentation_enabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()
func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
func capture(file: String) -> void:
	# process_frame also works in headless CI where frame_post_draw is never emitted.
	await get_tree().process_frame
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("SKIP CAPTURE " + file + " (headless display)")
		return
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		print("SKIP CAPTURE " + file + " (no render target)")
		return
	var image := viewport_texture.get_image()
	if image == null:
		print("SKIP CAPTURE " + file + " (dummy renderer)")
		return
	image.save_png("res://.godot/qa/" + file + ".png")
	print("CAPTURED " + file)
func run() -> void:
	get_tree().current_scene = null
	DirAccess.make_dir_recursive_absolute("res://.godot/qa")
	Game.enter_room("courtyard")
	await frames(50)
	await capture("01-courtyard")
	Game.new_run(417)
	await frames(50)
	for id in ItemCatalog.IDS:
		Game.acquire_item(id)
	Game.player_stats.player.position = Vector2(970, 581)
	await frames(15)
	Game.guard.skill_pressed()
	await frames(3)
	await capture("02-combat")
	Game.inversion.skill_pressed()
	await frames(60)
	await capture("03-inversion")
	Game.enter_room("shop1")
	await frames(50)
	Game.player_stats.player.position = Vector2(520, 581)
	await frames(15)
	await capture("04-shop")
	Game.enter_room("boss_room")
	await frames(50)
	Game.room.start_boss()
	Game.player_stats.player.position = Vector2(670, 581)
	Game.room.boss.receive_damage(Game.room.boss.max_health * 0.55, Vector2.ZERO)
	await frames(220)
	await capture("05-boss")
	Game.room.boss.receive_damage(3000, Vector2.ZERO)
	await frames(5)
	await capture("06-victory")
	get_tree().quit()
