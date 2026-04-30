extends Node

signal building_placed(building: Node2D)
signal preview_updated(is_visible: bool, world_position: Vector2, is_valid: bool, message: String)

const GRID_SIZE := 32.0

var structures_root: Node2D = null
var fortress: Node2D = null
var economy_system: Node = null
var run_director: Node = null
var combat_system: Node = null
var enemies_root: Node2D = null
var hero: Node2D = null
var builder: Node2D = null
var map_view: Node = null
var last_validation_key: String = ""
var last_validation_result: Dictionary = {}


func setup(next_structures_root: Node2D, next_fortress: Node2D, next_economy_system: Node, next_run_director: Node, next_combat_system: Node, next_enemies_root: Node2D, next_hero: Node2D, next_builder: Node2D, next_map_view: Node) -> void:
	structures_root = next_structures_root
	fortress = next_fortress
	economy_system = next_economy_system
	run_director = next_run_director
	combat_system = next_combat_system
	enemies_root = next_enemies_root
	hero = next_hero
	builder = next_builder
	map_view = next_map_view


func request_place_building(building_def, world_position: Vector2) -> bool:
	if structures_root == null:
		push_warning("BuildSystem cannot place building because World/Structures is missing.")
		return false

	if economy_system == null:
		push_warning("BuildSystem cannot place building because EconomySystem is missing.")
		return false

	var validation := get_placement_validation(building_def, world_position)
	if not validation.is_valid:
		push_warning("BuildSystem placement rejected: %s" % validation.message)
		preview_updated.emit(true, validation.position, false, validation.message)
		return false

	if not economy_system.spend(building_def.build_cost):
		push_warning("BuildSystem placement rejected: Not enough gold.")
		preview_updated.emit(true, validation.position, false, "Not enough gold")
		return false

	var building: Node2D = building_def.scene.instantiate()
	building.global_position = validation.position

	if building.has_method("setup"):
		building.setup(building_def, enemies_root, combat_system, fortress, structures_root, hero)
	else:
		push_warning("Placed building scene is missing setup().")

	structures_root.add_child(building)
	building_placed.emit(building)
	preview_updated.emit(false, validation.position, true, "")
	return true


func update_preview(building_def, world_position: Vector2) -> void:
	var validation := get_placement_validation(building_def, world_position)
	preview_updated.emit(true, validation.position, validation.is_valid, validation.message)


func clear_preview() -> void:
	last_validation_key = ""
	last_validation_result = {}
	preview_updated.emit(false, Vector2.ZERO, false, "")


func get_placement_validation(building_def, world_position: Vector2) -> Dictionary:
	if building_def == null or building_def.scene == null:
		push_warning("BuildSystem received a null building definition or missing building scene.")
		return _validation_result(false, world_position, "No building selected")

	var snapped_position: Vector2 = _get_snapped_position(world_position)
	var validation_key: String = _get_validation_cache_key(building_def, snapped_position)
	if validation_key == last_validation_key and not last_validation_result.is_empty():
		return last_validation_result.duplicate(true)

	var validation_result: Dictionary = _is_valid_position(building_def, snapped_position)
	last_validation_key = validation_key
	last_validation_result = validation_result.duplicate(true)
	return validation_result


func _is_valid_position(building_def, world_position: Vector2) -> Dictionary:
	if economy_system != null and economy_system.has_method("can_afford"):
		if not economy_system.can_afford(building_def.build_cost):
			return _validation_result(false, world_position, "Not enough gold")

	if not _is_inside_map_bounds(world_position):
		return _validation_result(false, world_position, "Outside map bounds")

	if _is_position_occupied(building_def, world_position):
		return _validation_result(false, world_position, "Tile already occupied")

	var intentional_entrance_seal: bool = false
	if map_view != null and map_view.has_method("is_intentional_entrance_seal"):
		intentional_entrance_seal = map_view.is_intentional_entrance_seal(building_def, world_position)

	if map_view != null and map_view.has_method("would_structure_block_unit_paths"):
		var units: Array[Node2D] = []
		if hero != null:
			units.append(hero)
		if builder != null:
			units.append(builder)
		if not intentional_entrance_seal and map_view.would_structure_block_unit_paths(building_def, world_position, units):
			return _validation_result(false, world_position, "Would block unit movement")

	if intentional_entrance_seal:
		return _validation_result(true, world_position, "Seal entrance")

	return _validation_result(true, world_position, "Ready to build")


func _is_inside_map_bounds(world_position: Vector2) -> bool:
	if map_view != null and map_view.has_method("get_world_bounds"):
		return map_view.get_world_bounds().has_point(world_position)
	return true


func _is_position_occupied(building_def, world_position: Vector2) -> bool:
	var placement_radius: float = _get_placement_radius(building_def)

	if fortress != null and fortress.global_position.distance_to(world_position) < placement_radius + 48.0:
		return true

	for structure in structures_root.get_children():
		if not (structure is Node2D):
			continue
		var occupied_radius: float = _get_structure_radius(structure)
		if structure.global_position.distance_to(world_position) < placement_radius + occupied_radius:
			return true

	return false


func _get_placement_radius(building_def) -> float:
	if building_def == null:
		return _get_grid_size() * 0.5
	var footprint: Vector2i = building_def.footprint_size
	var footprint_tiles: int = maxi(footprint.x, footprint.y)
	var grid_size: float = _get_grid_size()
	return maxf(float(footprint_tiles) * grid_size * 0.5, grid_size * 0.5)


func _get_structure_radius(structure: Node2D) -> float:
	if structure == null:
		return _get_grid_size() * 0.5
	var structure_def = structure.get("building_def")
	if structure_def != null:
		return _get_placement_radius(structure_def)
	return _get_grid_size() * 0.5


func _validation_result(is_valid: bool, world_position: Vector2, message: String) -> Dictionary:
	return {
		"is_valid": is_valid,
		"position": world_position,
		"message": message,
	}


func _get_snapped_position(world_position: Vector2) -> Vector2:
	if map_view != null and map_view.has_method("snap_to_grid"):
		return map_view.snap_to_grid(world_position)
	var grid_size: float = _get_grid_size()
	return Vector2(
		round(world_position.x / grid_size) * grid_size,
		round(world_position.y / grid_size) * grid_size
	)


func _get_validation_cache_key(building_def, snapped_position: Vector2) -> String:
	var building_id: String = "none"
	if building_def != null:
		building_id = String(building_def.id)
	var current_gold: int = -1
	if economy_system != null:
		current_gold = economy_system.current_gold
	var navigation_version: int = -1
	if map_view != null and map_view.has_method("get_navigation_version"):
		navigation_version = map_view.get_navigation_version()
	return "%s|%.0f|%.0f|%d|%d" % [building_id, snapped_position.x, snapped_position.y, current_gold, navigation_version]


func _get_grid_size() -> float:
	if map_view != null and map_view.has_method("get_grid_size"):
		return float(map_view.get_grid_size())
	return GRID_SIZE
