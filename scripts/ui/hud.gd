extends CanvasLayer

var run_director: Node = null
var wave_director: Node = null
var economy_system: Node = null
var fortress: Node2D = null
var game_root: Node = null

@onready var title_label: Label = $HeaderPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var phase_label: Label = $HeaderPanel/MarginContainer/VBoxContainer/PhaseLabel
@onready var fortress_label: Label = $StatusPanel/MarginContainer/VBoxContainer/FortressLabel
@onready var fortress_tier_label: Label = $StatusPanel/MarginContainer/VBoxContainer/FortressTierLabel
@onready var gold_label: Label = $StatusPanel/MarginContainer/VBoxContainer/GoldLabel
@onready var wave_label: Label = $StatusPanel/MarginContainer/VBoxContainer/WaveLabel
@onready var upcoming_label: Label = $IntelPanel/MarginContainer/VBoxContainer/UpcomingLabel
@onready var threat_preview_label: Label = $IntelPanel/MarginContainer/VBoxContainer/ThreatPreviewLabel
@onready var alert_label: Label = $IntelPanel/MarginContainer/VBoxContainer/AlertPanel/MarginContainer/AlertLabel
@onready var selected_unit_label: Label = $ControlPanel/MarginContainer/VBoxContainer/SelectedUnitLabel
@onready var build_mode_label: Label = $ControlPanel/MarginContainer/VBoxContainer/BuildModeLabel
@onready var build_feedback_label: Label = $ControlPanel/MarginContainer/VBoxContainer/BuildFeedbackLabel
@onready var economy_actions_label: Label = $ControlPanel/MarginContainer/VBoxContainer/EconomyActionsLabel
@onready var hint_label: Label = $ControlPanel/MarginContainer/VBoxContainer/HintLabel
@onready var outcome_label: Label = $ControlPanel/MarginContainer/VBoxContainer/OutcomeLabel


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
	fortress_tier_label.text = "Fortress Tier: %d" % fortress.get_tier_index()
	gold_label.text = "Gold: %d" % economy_system.current_gold
	wave_label.text = "Wave: %d | Active enemies: %d" % [wave_director.get_current_wave_number(), wave_director.active_enemies]
	upcoming_label.text = game_root.get_upcoming_status_label()
	threat_preview_label.text = game_root.get_upcoming_preview_label()
	alert_label.text = game_root.get_alert_label()
	selected_unit_label.text = "Selected: %s" % game_root.get_selected_unit_label()
	build_mode_label.text = game_root.get_build_mode_label()
	build_feedback_label.text = game_root.get_build_feedback_label()
	economy_actions_label.text = game_root.get_economy_actions_label()
	hint_label.text = game_root.get_hint_label()


func _on_run_lost(reason: String) -> void:
	outcome_label.text = "Defeat: %s" % reason


func _on_run_won() -> void:
	outcome_label.text = "Victory: You survived the first defensive run."
