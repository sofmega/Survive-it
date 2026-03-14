extends Node2D

const HERO_DEF = preload("res://data/heroes/default_hero.tres")
const FORTRESS_TIERS := [
	preload("res://data/fortress/fortress_tier_1.tres"),
	preload("res://data/fortress/fortress_tier_2.tres"),
]
const BUILDING_OPTIONS := [
	preload("res://data/buildings/arrow_tower.tres"),
	preload("res://data/buildings/slow_beacon.tres"),
	preload("res://data/buildings/repair_post.tres"),
	preload("res://data/buildings/command_banner.tres"),
]

@onready var fortress: Node2D = $World/Fortress
@onready var hero: Node2D = $World/Hero
@onready var builder: Node2D = $World/Builder
@onready var enemies_root: Node2D = $World/Enemies
@onready var structures_root: Node2D = $World/Structures
@onready var run_director: Node = $Directors/RunDirector
@onready var wave_director: Node = $Directors/WaveDirector
@onready var spawn_director: Node = $Directors/SpawnDirector
@onready var build_system: Node = $Directors/BuildSystem
@onready var economy_system: Node = $Directors/EconomySystem
@onready var combat_system: Node = $Directors/CombatSystem
@onready var hud: CanvasLayer = $UI/HUD
@onready var arrow_tower_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/ArrowTowerButton
@onready var slow_beacon_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/SlowBeaconButton
@onready var repair_post_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/RepairPostButton
@onready var command_banner_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/CommandBannerButton
@onready var repair_fortress_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/RepairFortressButton
@onready var upgrade_fortress_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/UpgradeFortressButton
@onready var build_cost_label: Label = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/CostLabel
@onready var placement_preview: Node2D = $Debug/PlacementPreview
@onready var command_marker: Node2D = $Debug/CommandMarker
@onready var selection_feedback: Node2D = $Debug/SelectionFeedback

var selected_unit: Node2D = null
var is_build_mode_active: bool = false
var build_feedback_text: String = ""
var preview_position: Vector2 = Vector2.ZERO
var preview_visible: bool = false
var preview_valid: bool = false
var alert_text: String = ""
var alert_time_remaining: float = 0.0


func _ready() -> void:
	fortress.tier_def = FORTRESS_TIERS[0]
	hero.hero_def = HERO_DEF
	fortress.destroyed.connect(_on_fortress_destroyed)

	economy_system.setup(120)
	economy_system.spend_failed.connect(_on_spend_failed)
	spawn_director.setup(
		enemies_root,
		fortress,
		structures_root,
		combat_system,
		{&"west_lane": Vector2(96.0, 450.0)}
	)
	wave_director.setup(spawn_director, economy_system)
	wave_director.elite_spawned.connect(_on_elite_spawned)
	run_director.setup(wave_director)
	build_system.setup(structures_root, fortress, economy_system, run_director, combat_system, enemies_root, hero)
	build_system.preview_updated.connect(_on_build_preview_updated)
	hero.setup(combat_system, enemies_root)
	builder.set_selected(false)
	hero.set_selected(true)
	selected_unit = hero
	builder.selected_building_def = BUILDING_OPTIONS[0]
	hud.setup(run_director, wave_director, economy_system, fortress, self)
	arrow_tower_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[0]))
	slow_beacon_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[1]))
	repair_post_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[2]))
	command_banner_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[3]))
	repair_fortress_button.pressed.connect(_on_repair_fortress_button_pressed)
	upgrade_fortress_button.pressed.connect(_on_upgrade_fortress_button_pressed)
	_update_build_cost_label()
	placement_preview.visible = false
	command_marker.visible = false


func _process(delta: float) -> void:
	alert_time_remaining = maxf(alert_time_remaining - delta, 0.0)
	if alert_time_remaining <= 0.0 and not alert_text.is_empty():
		alert_text = ""
	_update_selection_feedback()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_build_mode_active and selected_unit == builder:
			build_system.update_preview(builder.selected_building_def, _get_world_mouse_position())

	if event is InputEventMouseButton and event.pressed and not event.double_click:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _is_pointer_over_game_world():
				_handle_left_click(_get_world_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _is_pointer_over_game_world():
				_handle_right_click(_get_world_mouse_position())


func _handle_left_click(world_position: Vector2) -> void:
	if is_build_mode_active and selected_unit == builder:
		var was_built: bool = bool(build_system.request_place_building(builder.selected_building_def, world_position))
		if was_built:
			is_build_mode_active = false
			build_feedback_text = "Tower placed"
			build_system.clear_preview()
			command_marker.show_marker(world_position, Color(0.36, 0.92, 0.48, 0.9), &"build")
		return

	var clicked_selection: Node2D = _get_selectable_at_position(world_position)
	_set_selected_unit(clicked_selection)


func _handle_right_click(world_position: Vector2) -> void:
	if is_build_mode_active:
		is_build_mode_active = false
		build_feedback_text = "Build mode cancelled"
		build_system.clear_preview()
		command_marker.show_marker(world_position, Color(0.92, 0.32, 0.32, 0.9), &"cancel")
		return

	if selected_unit == hero:
		hero.set_move_target(world_position)
		command_marker.show_marker(world_position, Color(0.92, 0.95, 0.32, 0.9), &"move")
	elif selected_unit == builder:
		builder.set_move_target(world_position)
		command_marker.show_marker(world_position, Color(0.45, 0.82, 1.0, 0.9), &"move")


func _set_selected_unit(unit: Node2D) -> void:
	if selected_unit == hero:
		hero.set_selected(false)
	elif selected_unit == builder:
		builder.set_selected(false)

	selected_unit = unit

	if selected_unit == hero:
		hero.set_selected(true)
	elif selected_unit == builder:
		builder.set_selected(true)

	if selected_unit != builder:
		is_build_mode_active = false
		build_system.clear_preview()

	build_feedback_text = ""
	_update_selection_feedback()


func _get_selectable_at_position(world_position: Vector2) -> Node2D:
	if world_position.distance_to(hero.global_position) <= 28.0:
		return hero

	if world_position.distance_to(builder.global_position) <= 28.0:
		return builder

	return null


func _get_world_mouse_position() -> Vector2:
	return get_global_mouse_position()


func _is_pointer_over_game_world() -> bool:
	return true


func get_selected_unit_label() -> String:
	if selected_unit == builder:
		return "Builder (%s)" % builder.get_selected_building_name()
	if selected_unit == hero:
		return "Hero"

	return "None"


func get_build_mode_label() -> String:
	if selected_unit != builder:
		return "Build mode: Select the builder"

	if is_build_mode_active:
		return "Build mode: %s" % builder.selected_building_def.display_name

	return "Build mode: Inactive"


func get_build_feedback_label() -> String:
	return "Build feedback: %s" % build_feedback_text


func get_upcoming_status_label() -> String:
	var next_wave: int = wave_director.get_next_wave_number()
	if next_wave > 0:
		return "Next wave: %d" % next_wave
	return "Next wave: none"


func get_upcoming_preview_label() -> String:
	return "Threat: %s" % wave_director.get_next_wave_preview_text()


func get_alert_label() -> String:
	if alert_text.is_empty():
		if run_director.current_phase == run_director.COMBAT_PHASE:
			return "Alert: Hold the line"
		if run_director.current_phase == run_director.BUILD_PHASE:
			return "Alert: Prepare your defense"
		if run_director.current_phase == run_director.REWARD_PHASE:
			return "Alert: Rebuild and reposition"
		return "Alert: Stable"
	return "Alert: %s" % alert_text


func get_economy_actions_label() -> String:
	var repair_text: String = "Repair fortress: %d gold (+%.0f HP)" % [fortress.get_repair_cost(), fortress.get_repair_amount()]
	var upgrade_cost: int = fortress.get_upgrade_cost()
	var upgrade_text := "Upgrade fortress: max tier"
	if upgrade_cost > 0:
		upgrade_text = "Upgrade fortress: %d gold" % upgrade_cost
	return "%s | %s" % [repair_text, upgrade_text]


func get_hint_label() -> String:
	if is_build_mode_active and selected_unit == builder:
		return "Left click place | Right click cancel | Build inside the fortress zone"
	if selected_unit == builder:
		return "Builder selected | Right click move | Use build buttons to enter placement mode"
	if selected_unit == hero:
		return "Hero selected | Right click move | Keep the hero near towers to boost damage"
	return "Left click select | Right click move/cancel | Use the build panel for structures"


func _enter_build_mode(building_def) -> void:
	builder.selected_building_def = building_def
	_update_build_cost_label()

	if selected_unit != builder:
		build_feedback_text = "Select builder first"
		return

	if not run_director.can_build():
		build_feedback_text = "Can only build during build phase"
		return

	is_build_mode_active = true
	build_feedback_text = "Placing %s" % builder.selected_building_def.display_name
	build_system.update_preview(builder.selected_building_def, _get_world_mouse_position())


func _on_build_preview_updated(is_visible: bool, world_position: Vector2, is_valid: bool, message: String) -> void:
	preview_visible = is_visible
	preview_position = world_position
	preview_valid = is_valid
	build_feedback_text = message
	placement_preview.visible = preview_visible
	placement_preview.position = preview_position
	placement_preview.set("is_valid_preview", preview_valid)


func _update_build_cost_label() -> void:
	build_cost_label.text = "%s Cost: %d" % [builder.selected_building_def.display_name, builder.selected_building_def.build_cost]


func _on_repair_fortress_button_pressed() -> void:
	if fortress.current_health >= fortress.max_health:
		build_feedback_text = "Fortress already full"
		return

	if not economy_system.spend(fortress.get_repair_cost()):
		return

	fortress.receive_heal(fortress.get_repair_amount())
	build_feedback_text = "Fortress repaired"


func _on_upgrade_fortress_button_pressed() -> void:
	var current_tier: int = fortress.get_tier_index()
	if current_tier >= FORTRESS_TIERS.size():
		build_feedback_text = "Fortress already at max tier"
		return

	var current_cost: int = fortress.get_upgrade_cost()
	if current_cost <= 0:
		build_feedback_text = "No upgrade available"
		return

	if not economy_system.spend(current_cost):
		return

	fortress.set_tier_def(FORTRESS_TIERS[current_tier], true)
	build_feedback_text = "Fortress upgraded to tier %d" % fortress.get_tier_index()


func _on_spend_failed(reason: String) -> void:
	build_feedback_text = reason
	command_marker.show_marker(_get_world_mouse_position(), Color(0.92, 0.32, 0.32, 0.9), &"cancel")


func _on_fortress_destroyed() -> void:
	run_director.enter_game_over("The fortress fell")


func _on_elite_spawned(next_alert_text: String) -> void:
	alert_text = next_alert_text
	alert_time_remaining = 4.5


func _update_selection_feedback() -> void:
	if selected_unit == null:
		selection_feedback.set("tracked_unit", null)
		selection_feedback.visible = false
		return

	var has_move_target: bool = false
	var move_target: Vector2 = selected_unit.global_position
	if selected_unit.has_method("has_active_move_target"):
		has_move_target = selected_unit.has_active_move_target()
	if selected_unit.has_method("get_move_target"):
		move_target = selected_unit.get_move_target()

	selection_feedback.call("update_tracking", selected_unit, has_move_target, move_target)
