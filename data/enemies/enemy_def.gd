class_name EnemyDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var scene: PackedScene

@export var max_health: float = 10.0
@export var move_speed: float = 60.0
@export var contact_damage: float = 1.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.0
@export var gold_reward: int = 5
@export var preferred_target: StringName = &"fortress"
@export var is_elite: bool = false
@export var alert_text: String = ""
@export var special_attack_cooldown: float = 0.0
@export var special_attack_damage: float = 0.0
@export var special_attack_radius: float = 0.0
@export var radius: float = 16.0
@export var tint: Color = Color(0.83, 0.29, 0.27)
