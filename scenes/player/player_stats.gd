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
var pierce_count: int = 0
var kill_heal: float = 0.0
var reflection_bonus: float = 0.0
var side_shots: int = 0
var energy_multiplier: float = 1.0
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
	max_health = 150.0
	speed_multiplier_item = 1.0
	damage_multipler_item = 1.0
	damage_reduction_rate_item = 0.0
	dodge_time_multipler_item = 1.0
	gravity_multiplier_item = 1.0
	extra_shot_chance = 0.0
	inversion_damage = 1.0
	pierce_count = 0
	kill_heal = 0.0
	reflection_bonus = 0.0
	side_shots = 0
	energy_multiplier = 1.0
	for key: Variant in counts:
		var item: ItemData = ItemCatalog.data(int(key))
		if item == null:
			continue
		var count: int = maxi(0, int(counts[key]))
		max_health += item.health_bonus * count
		speed_multiplier_item += item.speed_bonus * count
		damage_multipler_item += item.damage_bonus * count
		damage_reduction_rate_item += item.reduction_bonus * count
		dodge_time_multipler_item += item.guard_bonus * count
		gravity_multiplier_item -= item.gravity_reduction * count
		extra_shot_chance += item.extra_shot * count
		inversion_damage += item.inversion_bonus * count
		pierce_count += item.pierce * count
		kill_heal += item.kill_heal * count
		reflection_bonus += item.reflection_bonus * count
		side_shots += item.side_shots * count
		energy_multiplier += item.energy_bonus * count
	speed_multiplier_item = minf(speed_multiplier_item, 1.75)
	damage_multipler_item = minf(damage_multipler_item, 3.0)
	damage_reduction_rate_item = minf(damage_reduction_rate_item, 0.56)
	dodge_time_multipler_item = minf(dodge_time_multipler_item, 2.0)
	gravity_multiplier_item = maxf(gravity_multiplier_item, 0.4)
	extra_shot_chance = minf(extra_shot_chance, 0.8)
	inversion_damage = minf(inversion_damage, 2.5)
	pierce_count = mini(pierce_count, 3)
	kill_heal = minf(kill_heal, 6.0)
	reflection_bonus = minf(reflection_bonus, 2.0)
	side_shots = mini(side_shots, 2)
	energy_multiplier = minf(energy_multiplier, 2.0)
	health = minf(health, max_health)
	inventory_changed.emit()
