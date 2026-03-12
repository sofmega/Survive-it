class_name HeroDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var scene: PackedScene

@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 0.6

