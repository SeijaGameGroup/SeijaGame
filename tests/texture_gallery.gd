extends Node

func _ready() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for index: int in count:
		await get_tree().physics_frame

func capture(label: String) -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("SKIP TEXTURE CAPTURE (headless): ", label)
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/qa/texture-" + label + ".png")
	print("TEXTURE CAPTURE: ", label, " frame=", Game.player_stats.player.graphics.frame)

func run() -> void:
	get_tree().current_scene = null
	DirAccess.make_dir_recursive_absolute("res://.godot/qa")
	Game.enter_room("courtyard")
	await frames(45)
	var player: Player = Game.player_stats.player
	await capture("idle")
	Input.action_press("move_right")
	await frames(16)
	await capture("run-right")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(16)
	await capture("run-left")
	Input.action_release("move_left")
	Input.action_press("jump")
	await frames(8)
	await capture("rise")
	Input.action_release("jump")
	await frames(17)
	await capture("fall")
	await frames(45)
	await capture("land")
	player.set_inverted(true)
	await frames(65)
	Input.action_press("move_right")
	await frames(12)
	await capture("inverted-run")
	Input.action_release("move_right")
	get_tree().quit()
