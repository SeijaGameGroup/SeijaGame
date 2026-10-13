class_name RunBalance
extends Resource

@export_group("Player")
@export var shot_damage: float = 12.0
@export var shot_interval: float = 0.17
@export var guard_cooldown: float = 3.5
@export var inversion_cooldown: float = 7.0
@export var inversion_duration: float = 5.0
@export var flip_burst_duration: float = 2.0
@export var flip_burst_multiplier: float = 1.5
@export var dash_speed: float = 780.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.85
@export_group("Revolution")
@export var energy_per_hit: float = 2.0
@export var energy_per_kill: float = 14.0
@export var reflection_energy: float = 10.0
@export var revolution_damage: float = 95.0
@export var revolution_duration: float = 4.0
@export var revolution_multiplier: float = 1.75
@export_group("Encounters")
@export var enemy_health: PackedFloat32Array = PackedFloat32Array([42, 66, 48, 48])
@export var health_per_tier: float = 6.0
@export var boss_health: float = 2600.0
@export var enemy_damage_multiplier: float = 0.85
@export var stage_points: int = 18
@export var wave_healing: float = 18.0
@export var revive_fraction: float = 0.5
@export var revive_immunity: float = 2.5
