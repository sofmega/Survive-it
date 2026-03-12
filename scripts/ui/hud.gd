extends CanvasLayer

var run_director: Node = null
var wave_director: Node = null
var economy_system: Node = null
var fortress: Node2D = null
var game_root: Node = null

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var fortress_label: Label = $MarginContainer/VBoxContainer/FortressLabel
@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var selected_unit_label: Label = $MarginContainer/VBoxContainer/SelectedUnitLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel
@onready var outcome_label: Label = $MarginContainer/VBoxContainer/OutcomeLabel


func setup(next_run_director: Node, next_wave_director: Node, next_economy_system: Node, next_fortress: Node2D, next_game_root: Node) -> void:
	run_director = next_run_director
	wave_director = next_wave_director
	economy_system = next_economy_system
	fortress = next_fortress
	game_root = next_game_root

	run_director.run_lost.connect(_on_run_lost)
	run_director.run_won.connect(_on_run_won)


func _process(_delta: float) -> void:
	title_label.text = "Survive it"
	phase_label.text = "Phase: %s | Timer: %.0fs" % [run_director.get_phase_label(), run_director.get_time_remaining()]
	fortress_label.text = "Fortress HP: %.0f / %.0f" % [fortress.current_health, fortress.max_health]
	gold_label.text = "Gold: %d" % economy_system.current_gold
	wave_label.text = "Wave: %d | Active enemies: %d" % [wave_director.get_current_wave_number(), wave_director.active_enemies]
	selected_unit_label.text = "Controlled unit: %s" % game_root.get_controlled_unit_label()
	hint_label.text = "TAB switch unit | Move with WASD | Builder: SPACE place tower"


func _on_run_lost(reason: String) -> void:
	outcome_label.text = "Defeat: %s" % reason


func _on_run_won() -> void:
	outcome_label.text = "Victory: You survived the first defensive run."

