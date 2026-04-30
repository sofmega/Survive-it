extends Node

signal building_placed(building: Node2D)
signal preview_updated(is_visible: bool, world_position: Vector2, is_valid: bool, message: String)

const GRID_SIZE := 64.0

var structures_root: Node2D = null
var fortress: Node2D = null
var economy_system: Node = null
var run_director: Node = null
var combat_system: Node = null
var enemies_root: Node2D = null
var hero: Node2D = null
var map_view: Node = null


func setup(next_structures_root: Node2D, next_fortress: Node2D, next_economy_system: Node, next_run_director: Node, next_combat_system: Node, next_enemies_root: Node2D, next_hero: Node2D, next_map_view: Node) -> void:
	structures_root = next_structures_root
	fortress = next_fortress
	economy_system = next_economy_system
	run_director = next_run_director
	combat_system = next_combat_system
	enemies_root = next_enemies_root
	hero = next_hero
	map_view = next_map_view


func request_place_building(building_def, world_position: Vector2) -> bool:
	var validation := get_placement_validation(building_def, world_position)
	if not validation.is_valid:
		preview_updated.emit(true, validation.position, false, validation.message)
		return false

	if not economy_system.spend(building_def.build_cost):
		preview_updated.emit(true, validation.position, false, "Not enough gold")
		return false

	var building: Node2D = building_def.scene.instantiate()
	building.global_position = validation.position

	if building.has_method("setup"):
		building.setup(building_def, enemies_root, combat_system, fortress, structures_root, hero)

	structures_root.add_child(building)
	building_placed.emit(building)
	preview_updated.emit(false, validation.position, true, "")
	return true


func update_preview(building_def, world_position: Vector2) -> void:
	var validation := get_placement_validation(building_def, world_position)
	preview_updated.emit(true, validation.position, validation.is_valid, validation.message)


func clear_preview() -> void:
	preview_updated.emit(false, Vector2.ZERO, false, "")


func get_placement_validation(building_def, world_position: Vector2) -> Dictionary:
	if building_def == null or building_def.scene == null:
		return _validation_result(false, world_position, "No building selected")

	if not run_director.can_build():
		return _validation_result(false, world_position, "Setup phase only")

	var snapped_position := world_position
	if map_view != null and map_view.has_method("snap_to_grid"):
		snapped_position = map_view.snap_to_grid(world_position)
	else:
		snapped_position = Vector2(
			round(world_position.x / GRID_SIZE) * GRID_SIZE,
			round(world_position.y / GRID_SIZE) * GRID_SIZE
		)

	return _is_valid_position(building_def, snapped_position)


func _is_valid_position(building_def, world_position: Vector2) -> Dictionary:
	if not _is_within_build_anchor(world_position, building_def.build_radius_limit):
		return _validation_result(false, world_position, "Need to build near the relay or a banner")

	if map_view != null and map_view.has_method("is_buildable_position"):
		if not map_view.is_buildable_position(world_position, 26.0):
			return _validation_result(false, world_position, "Blocked by terrain")

	for structure in structures_root.get_children():
		if structure.global_position.distance_to(world_position) < GRID_SIZE:
			return _validation_result(false, world_position, "Tile already occupied")

	if fortress != null and fortress.global_position.distance_to(world_position) < 120.0:
		return _validation_result(false, world_position, "Too close to the relay")

	return _validation_result(true, world_position, "Ready to build")


func _is_within_build_anchor(world_position: Vector2, build_radius_limit: float) -> bool:
	for anchor_position in _get_build_anchor_positions():
		if anchor_position.distance_to(world_position) <= build_radius_limit:
			return true
	return false


func _get_build_anchor_positions() -> Array[Vector2]:
	var anchor_positions: Array[Vector2] = []
	if fortress != null:
		anchor_positions.append(fortress.global_position)
	for structure in structures_root.get_children():
		if not structure.has_method("is_build_anchor"):
			continue
		if structure.is_build_anchor():
			anchor_positions.append(structure.global_position)
	return anchor_positions


func _validation_result(is_valid: bool, world_position: Vector2, message: String) -> Dictionary:
	return {
		"is_valid": is_valid,
		"position": world_position,
		"message": message,
	}
