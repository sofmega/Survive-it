class_name BuildingDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var scene: PackedScene

@export var build_cost: int = 40
@export var footprint_size: Vector2i = Vector2i.ONE
@export var build_radius_limit: float = 280.0
@export var blocks_path: bool = true

@export var max_health: float = 50.0
@export var attack_damage: float = 6.0
@export var attack_range: float = 180.0
@export var attack_cooldown: float = 0.8

