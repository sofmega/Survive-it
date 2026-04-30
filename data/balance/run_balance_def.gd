class_name RunBalanceDef
extends Resource

@export var max_waves: int = 100
@export var starting_gold: int = 180

@export var starting_prep_duration: float = 10.0
@export var min_prep_duration: float = 10.0
@export var prep_duration_decay_per_wave: float = 0.12
@export var post_wave_delay: float = 6.0

@export var base_enemy_count: int = 6
@export var enemy_count_growth_per_wave: float = 0.95
@export var extra_enemy_burst_every_ten: int = 6

@export var clear_reward_base: int = 22
@export var clear_reward_growth_per_wave: float = 2.0
@export var bonus_reward_every_five: int = 18

@export var enemy_health_scale_per_wave: float = 0.055
@export var enemy_damage_scale_per_wave: float = 0.03
@export var enemy_speed_scale_per_wave: float = 0.006
@export var max_enemy_speed_multiplier: float = 1.65

@export var second_portal_wave: int = 4
@export var third_portal_wave: int = 10
@export var fourth_portal_wave: int = 18
@export var brute_start_wave: int = 4
@export var siege_start_wave: int = 8
@export var elite_wave_interval: int = 5
@export var captain_wave_interval: int = 10
