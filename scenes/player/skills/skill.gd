class_name Skill
extends Node

signal cooldown_changed(value: int)
@export var id := 0
@export var cooldown := 5.0
@export var duration := 1.0
@export var Name: StringName
@export var description: StringName
@export var cancelable := false
var remaining := 0.0
var active_left := 0.0
var player: Player:
	get: return Game.player_stats.player
var available: bool:
	get: return remaining <= 0.0

func _physics_process(delta: float) -> void:
	var previous := ceili(remaining)
	remaining = maxf(0.0, remaining - delta)
	if previous != ceili(remaining):
		cooldown_changed.emit(ceili(remaining))
	if active_left > 0.0:
		active_left = maxf(0.0, active_left - delta)
		if active_left == 0.0:
			deffect()

func skill_pressed() -> void:
	if not is_instance_valid(player) or not player.can_act():
		return
	if active_left > 0.0 and cancelable:
		cancel()
	elif available:
		remaining = cooldown
		active_left = duration * (Game.player_stats.dodge_time_multipler_item if id == 1 else 1.0)
		effect()

func effect() -> void:
	pass
func deffect() -> void:
	pass
func cancel() -> void:
	active_left = 0.0
	deffect()
func reset() -> void:
	cancel()
	remaining = 0.0
	cooldown_changed.emit(0)
