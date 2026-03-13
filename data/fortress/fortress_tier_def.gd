class_name FortressTierDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export var tier_index: int = 1
@export var max_health: float = 250.0
@export var armor: float = 0.0
@export var upgrade_cost: int = 0
@export var repair_amount: float = 40.0
@export var repair_cost: int = 20
@export var tower_damage_bonus: float = 0.0
