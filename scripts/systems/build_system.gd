extends Node

signal building_placed(building: Node2D)

const GRID_SIZE := 64.0

var structures_root: Node2D = null
var fortress: Node2D = null
var economy_system: Node = null
var run_director: Node = null
var combat_system: Node = null
var enemies_root: Node2D = null
var lane_y: float = 450.0


func setup(next_structures_root: Node2D, next_fortress: Node2D, next_economy_system: Node, next_run_director: Node, next_combat_system: Node, next_enemies_root: Node2D) -> void:
	structures_root = next_structures_root
	fortress = next_fortress
	economy_system = next_economy_system
	run_director = next_run_director
	combat_system = next_combat_system
	enemies_root = next_enemies_root


func request_place_building(building_def, world_position: Vector2) -> bool:
	if building_def == null or building_def.scene == null:
		return false

	if not run_director.can_build():
		return false

	var snapped_position := Vector2(
		round(world_position.x / GRID_SIZE) * GRID_SIZE,
		round(world_position.y / GRID_SIZE) * GRID_SIZE
	)

	if not _is_valid_position(building_def, snapped_position):
		return false

	if not economy_system.spend(building_def.build_cost):
		return false

	var building: Node2D = building_def.scene.instantiate()
	building.global_position = snapped_position

	if building.has_method("setup"):
		building.setup(building_def, enemies_root, combat_system)

	structures_root.add_child(building)
	building_placed.emit(building)
	return true


func _is_valid_position(building_def, world_position: Vector2) -> bool:
	if world_position.distance_to(fortress.global_position) > building_def.build_radius_limit:
		return false

	if world_position.distance_to(fortress.global_position) < 120.0:
		return false

	if absf(world_position.y - lane_y) < 64.0 and building_def.blocks_path:
		return false

	for structure in structures_root.get_children():
		if structure.global_position.distance_to(world_position) < GRID_SIZE:
			return false

	return true
