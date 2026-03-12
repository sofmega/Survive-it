class_name WaveDef
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export var wave_number: int = 1
@export var prep_time_before_wave: float = 60.0
@export var post_wave_delay: float = 5.0
@export var spawn_entries: Array[Resource] = []
@export var clear_gold_reward: int = 20
