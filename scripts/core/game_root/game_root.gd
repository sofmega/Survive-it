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
	preload("res://data/buildings/barricade.tres"),
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
@onready var battle_camera: Camera2D = $BattleCamera
@onready var map_view: Node = $Map

@onready var command_deck: PanelContainer = $UI/BuildPanel/CommandDeck
@onready var command_deck_title_label: Label = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/TitleLabel
@onready var command_deck_sub_label: Label = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/SubLabel
@onready var arrow_tower_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/ArrowTowerButton
@onready var slow_beacon_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/SlowBeaconButton
@onready var repair_post_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/RepairPostButton
@onready var command_banner_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/CommandBannerButton
@onready var barricade_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/BarricadeButton
@onready var repair_fortress_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/RepairFortressButton
@onready var upgrade_fortress_button: Button = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/AbilityGrid/UpgradeFortressButton
@onready var build_cost_label: Label = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/CostLabel
@onready var command_hint_label: Label = $UI/BuildPanel/CommandDeck/MarginContainer/VBoxContainer/HintLabel

@onready var placement_preview: Node2D = $Debug/PlacementPreview
@onready var command_marker: Node2D = $Debug/CommandMarker
@onready var selection_feedback: Node2D = $Debug/SelectionFeedback

var selected_unit: Node2D = null
var is_build_mode_active: bool = false
var build_feedback_text: String = ""
var alert_text: String = ""
var alert_time_remaining: float = 0.0
var command_hover_text: String = ""


func _ready() -> void:
	fortress.tier_def = FORTRESS_TIERS[0]
	hero.hero_def = HERO_DEF
	fortress.destroyed.connect(_on_fortress_destroyed)
	hero.destroyed.connect(_on_controlled_unit_destroyed)
	builder.destroyed.connect(_on_controlled_unit_destroyed)
	run_director.run_lost.connect(_on_run_finished)
	run_director.run_won.connect(_on_run_finished)

	if map_view != null:
		var relay_position: Vector2 = map_view.get_safe_zone_center()
		fortress.global_position = relay_position
		hero.global_position = relay_position + Vector2(72.0, -36.0)
		builder.global_position = relay_position + Vector2(132.0, 36.0)

	set_process_input(true)
	set_process_unhandled_input(true)

	spawn_director.setup(enemies_root, structures_root, combat_system, hero, builder, map_view)

	economy_system.setup(wave_director.get_starting_gold())
	economy_system.spend_failed.connect(_on_spend_failed)

	wave_director.setup(spawn_director, economy_system)
	wave_director.elite_spawned.connect(_on_elite_spawned)
	run_director.setup(wave_director)

	if map_view != null and map_view.has_method("setup_navigation"):
		map_view.setup_navigation(structures_root, fortress)

	build_system.setup(structures_root, fortress, economy_system, run_director, combat_system, enemies_root, hero, builder, map_view)
	build_system.preview_updated.connect(_on_build_preview_updated)

	hero.setup(combat_system, enemies_root, map_view)
	builder.setup(map_view)

	builder.set_selected(false)
	hero.set_selected(true)
	selected_unit = hero
	builder.selected_building_def = BUILDING_OPTIONS[0]

	hud.setup(run_director, wave_director, economy_system, fortress, self)

	arrow_tower_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[0]))
	slow_beacon_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[1]))
	repair_post_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[2]))
	command_banner_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[3]))
	barricade_button.pressed.connect(func() -> void: _enter_build_mode(BUILDING_OPTIONS[4]))
	repair_fortress_button.pressed.connect(_on_repair_fortress_button_pressed)
	upgrade_fortress_button.pressed.connect(_on_upgrade_fortress_button_pressed)

	_wire_command_hover(arrow_tower_button, BUILDING_OPTIONS[0].display_name, BUILDING_OPTIONS[0].build_cost, BUILDING_OPTIONS[0].description)
	_wire_command_hover(slow_beacon_button, BUILDING_OPTIONS[1].display_name, BUILDING_OPTIONS[1].build_cost, BUILDING_OPTIONS[1].description)
	_wire_command_hover(repair_post_button, BUILDING_OPTIONS[2].display_name, BUILDING_OPTIONS[2].build_cost, BUILDING_OPTIONS[2].description)
	_wire_command_hover(command_banner_button, BUILDING_OPTIONS[3].display_name, BUILDING_OPTIONS[3].build_cost, BUILDING_OPTIONS[3].description)
	_wire_command_hover(barricade_button, BUILDING_OPTIONS[4].display_name, BUILDING_OPTIONS[4].build_cost, BUILDING_OPTIONS[4].description)

	repair_fortress_button.mouse_entered.connect(func() -> void: command_hover_text = _get_fortress_action_summary())
	repair_fortress_button.mouse_exited.connect(_clear_command_hover)
	upgrade_fortress_button.mouse_entered.connect(func() -> void: command_hover_text = _get_fortress_action_summary())
	upgrade_fortress_button.mouse_exited.connect(_clear_command_hover)

	_update_build_cost_label()
	placement_preview.visible = false
	command_marker.visible = false

	if battle_camera != null:
		battle_camera.setup(fortress, map_view)

	var minimap_control = hud.get_minimap_display()
	if minimap_control != null:
		minimap_control.setup(fortress, hero, builder, enemies_root, structures_root, map_view)
		if battle_camera != null:
			minimap_control.focus_request.connect(battle_camera.seek_world_position)


func _process(delta: float) -> void:
	alert_time_remaining = maxf(alert_time_remaining - delta, 0.0)
	if alert_time_remaining <= 0.0 and not alert_text.is_empty():
		alert_text = ""

	_update_selection_feedback()
	_update_contextual_command_panel()
	_force_command_deck_layout()
	_clamp_command_deck_to_viewport()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_build_mode_active and selected_unit == builder:
			build_system.update_preview(builder.selected_building_def, _get_world_mouse_position())

	if event is InputEventMouseButton and event.pressed and not event.double_click:
		if event.button_index == MOUSE_BUTTON_LEFT and _is_pointer_over_game_world():
			_handle_left_click(_get_world_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and _is_pointer_over_game_world():
			_handle_right_click(_get_world_mouse_position())


func _handle_left_click(world_position: Vector2) -> void:
	if is_build_mode_active and selected_unit == builder:
		var was_built: bool = bool(build_system.request_place_building(builder.selected_building_def, world_position))
		if was_built:
			is_build_mode_active = false
			build_feedback_text = "%s placed" % builder.selected_building_def.display_name
			build_system.clear_preview()
			command_marker.show_marker(world_position, Color(0.36, 0.92, 0.48, 0.9), &"build")
		return

	_set_selected_unit(_get_selectable_at_position(world_position))


func _handle_right_click(world_position: Vector2) -> void:
	if is_build_mode_active:
		is_build_mode_active = false
		build_feedback_text = "Build mode cancelled"
		build_system.clear_preview()
		command_marker.show_marker(world_position, Color(0.92, 0.32, 0.32, 0.9), &"cancel")
		return

	_issue_move_command(world_position)


func _issue_move_command(world_position: Vector2) -> void:
	var target_unit: Node2D = selected_unit
	if target_unit == null or not target_unit.has_method("set_move_target"):
		target_unit = hero
		_set_selected_unit(hero)

	if target_unit == hero or target_unit == builder:
		var marker_color := Color(0.92, 0.95, 0.32, 0.9)
		if target_unit == builder:
			marker_color = Color(0.45, 0.82, 1.0, 0.9)
		target_unit.call("set_move_target", world_position)
		command_marker.show_marker(world_position, marker_color, &"move")


func _set_selected_unit(unit: Node2D) -> void:
	if selected_unit == hero and is_instance_valid(hero):
		hero.set_selected(false)
	elif selected_unit == builder and is_instance_valid(builder):
		builder.set_selected(false)

	selected_unit = unit

	if selected_unit == hero and is_instance_valid(hero):
		hero.set_selected(true)
	elif selected_unit == builder and is_instance_valid(builder):
		builder.set_selected(true)

	if selected_unit != builder:
		is_build_mode_active = false
		build_system.clear_preview()

	build_feedback_text = ""
	_update_selection_feedback()


func _get_selectable_at_position(world_position: Vector2) -> Node2D:
	if is_instance_valid(hero) and world_position.distance_to(hero.global_position) <= 28.0:
		return hero
	if is_instance_valid(builder) and world_position.distance_to(builder.global_position) <= 28.0:
		return builder
	return null


func _get_world_mouse_position() -> Vector2:
	return get_global_mouse_position()


func _is_pointer_over_game_world() -> bool:
	return true


func should_show_selected_unit_panel() -> bool:
	return selected_unit != null and is_instance_valid(selected_unit)


func get_selected_unit_title() -> String:
	if selected_unit == hero and is_instance_valid(hero):
		return "Hero"
	if selected_unit == builder and is_instance_valid(builder):
		return "Builder"
	return "No Unit Selected"


func get_selected_unit_health_label() -> String:
	if selected_unit == hero and is_instance_valid(hero) and hero.hero_def != null:
		return "HP %.0f / %.0f | Range %.0f" % [hero.current_health, hero.hero_def.max_health, hero.hero_def.attack_range]
	if selected_unit == builder and is_instance_valid(builder):
		return "HP %.0f / %.0f | Move speed %.0f" % [builder.current_health, builder.max_health, builder.move_speed]
	return ""


func get_selected_unit_status_label() -> String:
	if selected_unit == builder and is_instance_valid(builder):
		if is_build_mode_active:
			return "Placing %s | %s" % [builder.selected_building_def.display_name, build_feedback_text]
		return "Builder alive | %s" % builder.get_selected_building_name()
	if selected_unit == hero and is_instance_valid(hero):
		return "Escort, kite, and protect the builder | %s" % get_hint_label()
	return ""


func should_show_fortress_panel() -> bool:
	return selected_unit != null or _is_cursor_near_fortress() or not build_feedback_text.is_empty()


func get_fortress_panel_title() -> String:
	if _is_cursor_near_fortress():
		return "Support Relay"
	if selected_unit == builder and is_instance_valid(builder):
		return "Builder Orders"
	if selected_unit == hero and is_instance_valid(hero):
		return "Survival Orders"
	return "Survival Intel"


func get_fortress_panel_health_label() -> String:
	if _is_cursor_near_fortress():
		return "Relay HP %.0f / %.0f | Tier %d" % [fortress.current_health, fortress.max_health, fortress.get_tier_index()]
	if selected_unit == builder and is_instance_valid(builder):
		return "Expand territory with towers, barricades, and banners. The relay is support, not the loss condition."
	if selected_unit == hero and is_instance_valid(hero):
		return "The run fails only when both the hero and builder are dead. Use the hero to cover retreats and leaks."
	return "Survive by keeping both field units alive, building territory, and outlasting the portals."


func get_fortress_panel_costs_label() -> String:
	if _is_cursor_near_fortress():
		return _get_fortress_action_summary()
	if not build_feedback_text.is_empty():
		return build_feedback_text
	return get_upcoming_preview_label()


func get_upcoming_preview_label() -> String:
	return "Pressure: %s" % wave_director.get_next_wave_preview_text()


func get_alert_label() -> String:
	if alert_text.is_empty():
		match run_director.current_phase:
			run_director.COMBAT_PHASE:
				return "Alert: Portals are active"
			run_director.BUILD_PHASE:
				return "Alert: Build and reposition before the hunt begins"
			run_director.REWARD_PHASE:
				return "Alert: Rebuild while the next portals charge"
			run_director.GAME_OVER:
				return "Alert: Survival run failed"
			run_director.VICTORY:
				return "Alert: Wave 100 cleared"
		return "Alert: Stable"
	return "Alert: %s" % alert_text


func get_hint_label() -> String:
	if is_build_mode_active and selected_unit == builder:
		return "Left click place | Right click cancel | Build anywhere that is free and affordable"
	if selected_unit == builder:
		return "Builder selected | Right click move | Use the command deck to build anywhere on the map"
	if selected_unit == hero:
		return "Hero selected | Right click move | Kite enemies away from the builder and towers"
	return "Left click select | Right click move/cancel | Survive the portal waves"


func get_wave_timer_label() -> String:
	match run_director.current_phase:
		run_director.BUILD_PHASE:
			return "Prepare | Wave %d starts in %.0fs" % [wave_director.get_next_wave_number(), run_director.get_time_remaining()]
		run_director.REWARD_PHASE:
			return "Intermission | Wave %d starts in %.0fs" % [wave_director.get_next_wave_number(), run_director.get_time_remaining()]
		run_director.COMBAT_PHASE:
			return "Combat | Wave %d/100 in progress" % wave_director.get_current_wave_number()
		run_director.GAME_OVER:
			return "Defeat"
		run_director.VICTORY:
			return "Victory"
	return "%s | %.0fs" % [run_director.get_phase_label(), run_director.get_time_remaining()]


func get_hero_summary_label() -> String:
	if not is_instance_valid(hero):
		return "Hero KO"
	return "Hero HP %.0f / %.0f" % [hero.current_health, hero.hero_def.max_health]


func get_builder_summary_label() -> String:
	if not is_instance_valid(builder):
		return "Builder KO"
	return "Builder HP %.0f / %.0f" % [builder.current_health, builder.max_health]


func _is_cursor_near_fortress() -> bool:
	return _get_world_mouse_position().distance_to(fortress.global_position) <= 140.0


func _enter_build_mode(building_def) -> void:
	if not _is_survival_unit_alive(builder):
		build_feedback_text = "Builder unavailable"
		return

	if selected_unit != builder:
		_set_selected_unit(builder)

	builder.selected_building_def = building_def
	_update_build_cost_label()

	is_build_mode_active = true
	build_feedback_text = "Placing %s" % builder.selected_building_def.display_name
	build_system.update_preview(builder.selected_building_def, _get_world_mouse_position())


func _on_build_preview_updated(is_visible: bool, world_position: Vector2, is_valid: bool, message: String) -> void:
	placement_preview.visible = is_visible
	placement_preview.position = world_position
	placement_preview.set("is_valid_preview", is_valid)
	build_feedback_text = message


func _update_build_cost_label() -> void:
	build_cost_label.text = "%s Cost: %d" % [builder.selected_building_def.display_name, builder.selected_building_def.build_cost]


func _on_repair_fortress_button_pressed() -> void:
	if fortress.current_health >= fortress.max_health:
		build_feedback_text = "Support relay already full"
		return
	if not economy_system.spend(fortress.get_repair_cost()):
		return
	fortress.receive_heal(fortress.get_repair_amount())
	build_feedback_text = "Support relay repaired"


func _on_upgrade_fortress_button_pressed() -> void:
	var current_tier: int = fortress.get_tier_index()
	if current_tier >= FORTRESS_TIERS.size():
		build_feedback_text = "Support relay already at max tier"
		return

	var current_cost: int = fortress.get_upgrade_cost()
	if current_cost <= 0:
		build_feedback_text = "No upgrade available"
		return
	if not economy_system.spend(current_cost):
		return

	fortress.set_tier_def(FORTRESS_TIERS[current_tier], true)
	build_feedback_text = "Support relay upgraded to tier %d" % fortress.get_tier_index()


func _on_spend_failed(reason: String) -> void:
	build_feedback_text = reason
	command_marker.show_marker(_get_world_mouse_position(), Color(0.92, 0.32, 0.32, 0.9), &"cancel")


func _on_elite_spawned(next_alert_text: String) -> void:
	alert_text = next_alert_text
	alert_time_remaining = 4.5


func _update_selection_feedback() -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
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


func _update_contextual_command_panel() -> void:
	var show_builder_commands: bool = selected_unit == builder
	var show_fortress_actions: bool = not show_builder_commands and _is_cursor_near_fortress()
	var show_hero_commands: bool = selected_unit == hero and not show_fortress_actions

	command_deck.visible = show_builder_commands or show_fortress_actions or show_hero_commands
	if not command_deck.visible:
		command_hover_text = ""
		return

	arrow_tower_button.visible = show_builder_commands
	slow_beacon_button.visible = show_builder_commands
	repair_post_button.visible = show_builder_commands
	command_banner_button.visible = show_builder_commands
	barricade_button.visible = show_builder_commands
	repair_fortress_button.visible = show_fortress_actions
	upgrade_fortress_button.visible = show_fortress_actions

	if show_builder_commands:
		command_deck_title_label.text = "Abilities: Builder"
		command_deck_sub_label.text = "Choose a structure, then place it anywhere on the map as long as it is free and you can afford it."
		_update_build_cost_label()
		command_hint_label.text = command_hover_text if not command_hover_text.is_empty() else get_hint_label()
	elif show_fortress_actions:
		command_deck_title_label.text = "Abilities: Support Relay"
		command_deck_sub_label.text = "Repair or upgrade the relay for stronger tower support. Losing it does not end the run."
		build_cost_label.text = _get_fortress_action_summary()
		command_hint_label.text = command_hover_text if not command_hover_text.is_empty() else "Use relay support to stabilize long runs."
	else:
		command_deck_title_label.text = "Abilities: Hero"
		command_deck_sub_label.text = "Hero actives are not unlocked yet."
		build_cost_label.text = "Passive: protect the builder, peel for towers, and kite portal packs."
		command_hint_label.text = get_hint_label()


func _force_command_deck_layout() -> void:
	if command_deck == null or not command_deck.visible:
		return

	var is_builder_panel: bool = selected_unit == builder
	var panel_width := 360.0
	var panel_height := 300.0 if is_builder_panel else 170.0

	command_deck.anchor_left = 1.0
	command_deck.anchor_top = 1.0
	command_deck.anchor_right = 1.0
	command_deck.anchor_bottom = 1.0
	command_deck.offset_left = -panel_width - 18.0
	command_deck.offset_top = -panel_height - 18.0
	command_deck.offset_right = -18.0
	command_deck.offset_bottom = -18.0
	command_deck.custom_minimum_size = Vector2(panel_width, panel_height)
	command_deck.size = Vector2(panel_width, panel_height)

	var box := command_deck.get_node("MarginContainer/VBoxContainer") as VBoxContainer
	box.add_theme_constant_override("separation", 2)

	for button in [
		arrow_tower_button,
		slow_beacon_button,
		repair_post_button,
		command_banner_button,
		barricade_button,
		repair_fortress_button,
		upgrade_fortress_button,
	]:
		button.custom_minimum_size = Vector2(0.0, 24.0)

	command_deck_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	command_deck_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	command_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _get_fortress_action_summary() -> String:
	var repair_text: String = "Repair %d gold (+%.0f HP)" % [fortress.get_repair_cost(), fortress.get_repair_amount()]
	var upgrade_cost: int = fortress.get_upgrade_cost()
	if upgrade_cost > 0:
		return "%s | Upgrade %d gold" % [repair_text, upgrade_cost]
	return "%s | Upgrade unavailable" % repair_text


func _wire_command_hover(button: Button, display_name: String, cost: int, description: String) -> void:
	button.mouse_entered.connect(func() -> void:
		command_hover_text = "%s | %d gold | %s" % [display_name, cost, description]
	)
	button.mouse_exited.connect(_clear_command_hover)


func _clear_command_hover() -> void:
	command_hover_text = ""


func _clamp_command_deck_to_viewport() -> void:
	if command_deck == null or not command_deck.visible:
		return
	var viewport_rect := get_viewport_rect()
	var margin := 18.0
	var max_x := maxf(margin, viewport_rect.size.x - command_deck.size.x - margin)
	var max_y := maxf(margin, viewport_rect.size.y - command_deck.size.y - margin)
	command_deck.position = Vector2(
		clampf(command_deck.position.x, margin, max_x),
		clampf(command_deck.position.y, margin, max_y)
	)


func _on_controlled_unit_destroyed(unit: Node) -> void:
	if selected_unit == unit:
		selected_unit = null

	if _is_survival_unit_alive(hero):
		_set_selected_unit(hero)
	elif _is_survival_unit_alive(builder):
		_set_selected_unit(builder)
	else:
		is_build_mode_active = false
		build_system.clear_preview()
		run_director.enter_game_over("Both survival units were killed before Wave %d/%d ended." % [maxi(wave_director.get_current_wave_number(), 1), wave_director.get_total_waves()])


func _on_fortress_destroyed() -> void:
	alert_text = "Support relay destroyed"
	alert_time_remaining = 6.0
	build_feedback_text = "The relay is gone. You can still win if the hero and builder survive."


func _on_run_finished(_arg = null) -> void:
	is_build_mode_active = false
	build_system.clear_preview()
	wave_director.stop_wave_flow()


func _is_survival_unit_alive(unit: Node2D) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	var unit_health: Variant = unit.get("current_health")
	if unit_health != null:
		return float(unit_health) > 0.0
	return true
