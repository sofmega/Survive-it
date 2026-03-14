extends CanvasLayer

var run_director: Node = null
var wave_director: Node = null
var economy_system: Node = null
var fortress: Node2D = null
var game_root: Node = null

@onready var title_label: Label = $TopBar/MarginContainer/TopRow/TitleLabel
@onready var gold_value_label: Label = $TopBar/MarginContainer/TopRow/ResourceGroup/GoldChip/MarginContainer/GoldValueLabel
@onready var wave_value_label: Label = $TopBar/MarginContainer/TopRow/ResourceGroup/WaveChip/MarginContainer/WaveValueLabel
@onready var timer_value_label: Label = $TopBar/MarginContainer/TopRow/ResourceGroup/TimerChip/MarginContainer/TimerValueLabel
@onready var intel_value_label: Label = $TopBar/MarginContainer/TopRow/IntelGroup/IntelValueLabel
@onready var threat_value_label: Label = $TopBar/MarginContainer/TopRow/IntelGroup/ThreatValueLabel
@onready var alert_label: Label = $TopBar/MarginContainer/TopRow/AlertChip/MarginContainer/AlertLabel
@onready var minimap_display: Control = $MinimapPanel/MarginContainer/VBoxContainer/MinimapDisplay
@onready var selected_unit_panel: PanelContainer = $SelectedUnitPanel
@onready var selected_unit_name_label: Label = $SelectedUnitPanel/MarginContainer/VBoxContainer/UnitNameLabel
@onready var selected_unit_health_label: Label = $SelectedUnitPanel/MarginContainer/VBoxContainer/UnitHealthLabel
@onready var selected_unit_status_label: Label = $SelectedUnitPanel/MarginContainer/VBoxContainer/UnitStatusLabel
@onready var fortress_panel: PanelContainer = $FortressPanel
@onready var fortress_title_label: Label = $FortressPanel/MarginContainer/VBoxContainer/FortressTitleLabel
@onready var fortress_health_label: Label = $FortressPanel/MarginContainer/VBoxContainer/FortressHealthLabel
@onready var fortress_costs_label: Label = $FortressPanel/MarginContainer/VBoxContainer/FortressCostsLabel
@onready var outcome_overlay: CenterContainer = $OutcomeOverlay
@onready var outcome_title_label: Label = $OutcomeOverlay/PanelContainer/MarginContainer/VBoxContainer/OutcomeTitleLabel
@onready var outcome_detail_label: Label = $OutcomeOverlay/PanelContainer/MarginContainer/VBoxContainer/OutcomeDetailLabel


func setup(next_run_director: Node, next_wave_director: Node, next_economy_system: Node, next_fortress: Node2D, next_game_root: Node) -> void:
	run_director = next_run_director
	wave_director = next_wave_director
	economy_system = next_economy_system
	fortress = next_fortress
	game_root = next_game_root

	run_director.run_lost.connect(_on_run_lost)
	run_director.run_won.connect(_on_run_won)
	outcome_overlay.visible = false


func _process(_delta: float) -> void:
	title_label.text = "Survive it"
	gold_value_label.text = "Gold %d" % economy_system.current_gold
	wave_value_label.text = "Wave %d | %d foes" % [wave_director.get_current_wave_number(), wave_director.active_enemies]
	timer_value_label.text = "%s | %.0fs" % [run_director.get_phase_label(), run_director.get_time_remaining()]
	intel_value_label.text = game_root.get_upcoming_status_label()
	threat_value_label.text = game_root.get_upcoming_preview_label()
	alert_label.text = game_root.get_alert_label()

	selected_unit_panel.visible = game_root.should_show_selected_unit_panel()
	selected_unit_name_label.text = game_root.get_selected_unit_title()
	selected_unit_health_label.text = game_root.get_selected_unit_health_label()
	selected_unit_status_label.text = game_root.get_selected_unit_status_label()

	fortress_panel.visible = game_root.should_show_fortress_panel()
	fortress_title_label.text = game_root.get_fortress_panel_title()
	fortress_health_label.text = game_root.get_fortress_panel_health_label()
	fortress_costs_label.text = game_root.get_fortress_panel_costs_label()


func _on_run_lost(reason: String) -> void:
	outcome_title_label.text = "Fortress Lost"
	outcome_detail_label.text = reason
	outcome_overlay.visible = true


func _on_run_won() -> void:
	outcome_title_label.text = "Victory"
	outcome_detail_label.text = "The fortress held through the final wave."
	outcome_overlay.visible = true


func get_minimap_display() -> Control:
	return minimap_display
