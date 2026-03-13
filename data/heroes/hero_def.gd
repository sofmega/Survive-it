class_name HeroDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var scene: PackedScene

@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var attack_damage: float = 6.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 0.8
@export var support_radius: float = 180.0
@export var tower_damage_bonus: float = 0.35
