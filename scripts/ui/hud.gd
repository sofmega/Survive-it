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

@onready var minimap_panel: Control = $MinimapPanel
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
	var displayed_wave_number: int = wave_director.get_current_wave_number()
	if displayed_wave_number <= 0 and wave_director.has_more_waves():
		displayed_wave_number = wave_director.get_next_wave_number()

	title_label.text = "Survive it"
	gold_value_label.text = "Gold %d" % economy_system.current_gold
	wave_value_label.text = "Wave %d/%d | %d foes" % [displayed_wave_number, wave_director.get_total_waves(), wave_director.active_enemies]
	timer_value_label.text = game_root.get_wave_timer_label()
	intel_value_label.text = game_root.get_hero_summary_label()
	threat_value_label.text = game_root.get_builder_summary_label()
	alert_label.text = game_root.get_alert_label()

	selected_unit_panel.visible = game_root.should_show_selected_unit_panel()
	selected_unit_name_label.text = game_root.get_selected_unit_title()
	selected_unit_health_label.text = game_root.get_selected_unit_health_label()
	selected_unit_status_label.text = game_root.get_selected_unit_status_label()

	fortress_panel.visible = game_root.should_show_fortress_panel()
	fortress_title_label.text = _get_interaction_title()
	fortress_health_label.text = _get_interaction_body()
	fortress_costs_label.text = _get_interaction_details()

	_force_fixed_interface_layout()


func _on_run_lost(reason: String) -> void:
	outcome_title_label.text = "Defeat"
	outcome_detail_label.text = reason
	outcome_overlay.visible = true


func _on_run_won() -> void:
	outcome_title_label.text = "Victory"
	outcome_detail_label.text = "Wave 100 was cleared. The survival run is complete."
	outcome_overlay.visible = true


func get_minimap_display() -> Control:
	return minimap_display


func _get_interaction_title() -> String:
	if game_root != null and game_root.has_method("get_interaction_panel_title"):
		return game_root.get_interaction_panel_title()

	return game_root.get_fortress_panel_title()


func _get_interaction_body() -> String:
	if game_root != null and game_root.has_method("get_interaction_panel_body"):
		return game_root.get_interaction_panel_body()

	return game_root.get_fortress_panel_health_label()


func _get_interaction_details() -> String:
	if game_root != null and game_root.has_method("get_interaction_panel_details"):
		return game_root.get_interaction_panel_details()

	return game_root.get_fortress_panel_costs_label()


func _force_fixed_interface_layout() -> void:
	_force_minimap_layout()
	_force_selected_unit_panel_layout()
	_force_interaction_info_panel_layout()

	_clamp_panel_to_viewport(minimap_panel, 18.0)
	_clamp_panel_to_viewport(selected_unit_panel, 18.0)
	_clamp_panel_to_viewport(fortress_panel, 18.0)


func _force_minimap_layout() -> void:
	if minimap_panel == null:
		return

	minimap_panel.anchor_left = 0.0
	minimap_panel.anchor_top = 1.0
	minimap_panel.anchor_right = 0.0
	minimap_panel.anchor_bottom = 1.0

	minimap_panel.offset_left = 18.0
	minimap_panel.offset_top = -218.0
	minimap_panel.offset_right = 286.0
	minimap_panel.offset_bottom = -18.0


func _force_selected_unit_panel_layout() -> void:
	if selected_unit_panel == null:
		return

	selected_unit_panel.anchor_left = 0.5
	selected_unit_panel.anchor_top = 1.0
	selected_unit_panel.anchor_right = 0.5
	selected_unit_panel.anchor_bottom = 1.0

	selected_unit_panel.offset_left = -220.0
	selected_unit_panel.offset_top = -123.0
	selected_unit_panel.offset_right = 220.0
	selected_unit_panel.offset_bottom = -18.0


func _force_interaction_info_panel_layout() -> void:
	if fortress_panel == null:
		return

	fortress_panel.anchor_left = 1.0
	fortress_panel.anchor_top = 0.0
	fortress_panel.anchor_right = 1.0
	fortress_panel.anchor_bottom = 0.0

	fortress_panel.offset_left = -520.0
	fortress_panel.offset_top = 150.0
	fortress_panel.offset_right = -18.0
	fortress_panel.offset_bottom = 360.0

	fortress_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fortress_health_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fortress_costs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _clamp_panel_to_viewport(panel: Control, margin: float) -> void:
	if panel == null or not panel.visible:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var max_x := maxf(margin, viewport_size.x - panel.size.x - margin)
	var max_y := maxf(margin, viewport_size.y - panel.size.y - margin)

	panel.position = Vector2(
		clampf(panel.position.x, margin, max_x),
		clampf(panel.position.y, margin, max_y)
	)
