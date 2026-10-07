class_name PlayerStats
extends Stats

signal p_points_changed(value: int)
signal inventory_changed
var player: Player
@export var p_points := 0:
	set(value):
		p_points = maxi(0, value)
		p_points_changed.emit(p_points)
@export var is_locking := true
var passive_items: Array[Item] = []
var speed_multiplier_item := 1.0
var damage_multipler_item := 1.0
var damage_reduction_rate_item := 0.0
var dodge_time_multipler_item := 1.0
var cooldown_multipler_item := 1.0
var gravity_multiplier_item := 1.0
var jump_velocity_multipler_item := 1.0
var range_multipler_item := 1.0
var damage_item := 0.0
var extra_shot_chance := 0.0
var inversion_damage := 1.0
var player_global_position := Vector2.ZERO
var current_set: ConfigSet
var current_set_index := 0
var available_sets: Array[ConfigSet] = []
var available_skills: Array[Skill] = []

func switch_config() -> void:
	pass

func reset_run() -> void:
	p_points = 0
	is_locking = true
	passive_items.clear()
	recalculate({})
	reset_health(150.0)
	inventory_changed.emit()

func recalculate(counts: Dictionary) -> void:
	max_health = 150.0 + 20.0 * counts.get(3, 0)
	speed_multiplier_item = minf(1.0 + 0.15 * counts.get(2, 0), 1.75)
	damage_multipler_item = 1.0 + 0.15 * counts.get(4, 0)
	damage_reduction_rate_item = minf(0.08 * counts.get(5, 0), 0.56)
	dodge_time_multipler_item = minf(1.0 + 0.25 * counts.get(7, 0), 2.0)
	gravity_multiplier_item = maxf(1.0 - 0.15 * counts.get(8, 0), 0.4)
	extra_shot_chance = minf(0.1 * counts.get(1, 0), 0.8)
	inversion_damage = 1.0 + 0.3 * counts.get(9, 0)
	health = minf(health, max_health)
	inventory_changed.emit()
