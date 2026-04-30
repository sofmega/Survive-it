extends Node2D

const MAP_CELLS := Vector2i(128, 128)
const GRID_SIZE := 32.0
const WORLD_SIZE := Vector2(float(MAP_CELLS.x) * GRID_SIZE, float(MAP_CELLS.y) * GRID_SIZE)
const UNIT_RADIUS := 20.0
const PORTAL_PAD_SIZE := Vector2i(2, 2)
const TERRITORY_PAD := Rect2i(62, 62, 4, 4)

const WALL_CELL_RECTS := [
	Rect2i(0, 0, 128, 2),
	Rect2i(0, 126, 128, 2),
	Rect2i(0, 0, 2, 128),
	Rect2i(126, 0, 2, 128),
	Rect2i(46, 46, 17, 2),
	Rect2i(65, 46, 17, 2),
	Rect2i(46, 80, 17, 2),
	Rect2i(65, 80, 17, 2),
	Rect2i(46, 46, 2, 17),
	Rect2i(46, 65, 2, 17),
	Rect2i(80, 46, 2, 17),
	Rect2i(80, 65, 2, 17),
	Rect2i(2, 58, 44, 2),
	Rect2i(2, 68, 44, 2),
	Rect2i(82, 58, 44, 2),
	Rect2i(82, 68, 44, 2),
	Rect2i(58, 2, 2, 44),
	Rect2i(68, 2, 2, 44),
	Rect2i(58, 82, 2, 44),
	Rect2i(68, 82, 2, 44),
	Rect2i(14, 14, 22, 2),
	Rect2i(14, 14, 2, 18),
	Rect2i(34, 14, 2, 18),
	Rect2i(20, 28, 16, 2),
	Rect2i(18, 20, 12, 2),
	Rect2i(92, 14, 22, 2),
	Rect2i(92, 14, 2, 18),
	Rect2i(112, 14, 2, 18),
	Rect2i(92, 28, 16, 2),
	Rect2i(98, 20, 12, 2),
	Rect2i(14, 96, 22, 2),
	Rect2i(14, 96, 2, 18),
	Rect2i(34, 96, 2, 18),
	Rect2i(20, 96, 16, 2),
	Rect2i(18, 106, 12, 2),
	Rect2i(92, 96, 22, 2),
	Rect2i(92, 96, 2, 18),
	Rect2i(112, 96, 2, 18),
	Rect2i(92, 96, 16, 2),
	Rect2i(98, 106, 12, 2),
]

const PORTAL_CELLS := {
	&"left_center": Vector2i(4, 63),
	&"top_center": Vector2i(63, 4),
	&"bottom_center": Vector2i(63, 122),
	&"right_center": Vector2i(122, 63),
}

const PATH_NODE_CELLS := {
	&"center": Vector2i(64, 64),
	&"west_gate": Vector2i(47, 64),
	&"east_gate": Vector2i(80, 64),
	&"north_gate": Vector2i(64, 47),
	&"south_gate": Vector2i(64, 80),
	&"north_west_room": Vector2i(26, 26),
	&"north_east_room": Vector2i(102, 26),
	&"south_west_room": Vector2i(26, 102),
	&"south_east_room": Vector2i(102, 102),
}

const PATH_CONNECTIONS := {
	&"center": [&"west_gate", &"east_gate", &"north_gate", &"south_gate"],
	&"west_gate": [&"center", &"north_west_room", &"south_west_room"],
	&"east_gate": [&"center", &"north_east_room", &"south_east_room"],
	&"north_gate": [&"center", &"north_west_room", &"north_east_room"],
	&"south_gate": [&"center", &"south_west_room", &"south_east_room"],
	&"north_west_room": [&"west_gate", &"north_gate"],
	&"north_east_room": [&"east_gate", &"north_gate"],
	&"south_west_room": [&"west_gate", &"south_gate"],
	&"south_east_room": [&"east_gate", &"south_gate"],
}

const BLOCKABLE_ENTRANCE_DEFS := [
	{
		"id": &"north_gate",
		"cell_rect": Rect2i(63, 46, 2, 2),
		"seal_cell": Vector2i(63, 46),
		"required_blocker_footprint": Vector2i(2, 2),
		"outside_test_cell": Vector2i(64, 40),
		"inside_test_cell": Vector2i(64, 50),
		"allows_full_block": true,
	},
	{
		"id": &"south_gate",
		"cell_rect": Rect2i(63, 80, 2, 2),
		"seal_cell": Vector2i(63, 80),
		"required_blocker_footprint": Vector2i(2, 2),
		"outside_test_cell": Vector2i(64, 86),
		"inside_test_cell": Vector2i(64, 76),
		"allows_full_block": true,
	},
	{
		"id": &"west_gate",
		"cell_rect": Rect2i(46, 63, 2, 2),
		"seal_cell": Vector2i(46, 63),
		"required_blocker_footprint": Vector2i(2, 2),
		"outside_test_cell": Vector2i(40, 64),
		"inside_test_cell": Vector2i(50, 64),
		"allows_full_block": true,
	},
	{
		"id": &"east_gate",
		"cell_rect": Rect2i(80, 63, 2, 2),
		"seal_cell": Vector2i(80, 63),
		"required_blocker_footprint": Vector2i(2, 2),
		"outside_test_cell": Vector2i(86, 64),
		"inside_test_cell": Vector2i(76, 64),
		"allows_full_block": true,
	},
]

@export var build_radius := 320.0
@export var debug_navigation_paths: bool = false
@export var ambient_redraw_interval: float = 0.12

var ambient_time: float = 0.0
var ambient_redraw_accumulator: float = 0.0
var structures_root: Node2D = null
var fortress: Node2D = null
var navigation_dirty: bool = true
var navigation_version: int = 0
var static_blocked_cells: Dictionary = {}
var dynamic_blocked_cells: Dictionary = {}
var route_cache: Dictionary = {}
var wall_rects: Array[Rect2] = []
var path_nodes_world: Dictionary = {}
var blockable_entrances_world: Array[Dictionary] = []
var portal_positions: Dictionary = {}
var entrance_floor_cells: Dictionary = {}

@onready var territory_anchor: Marker2D = $TerritoryAnchor
@onready var left_center_portal: Marker2D = $SpawnPoints/LeftCenterPortal
@onready var top_center_portal: Marker2D = $SpawnPoints/TopCenterPortal
@onready var bottom_center_portal: Marker2D = $SpawnPoints/BottomCenterPortal
@onready var right_center_portal: Marker2D = $SpawnPoints/RightCenterPortal


func _ready() -> void:
	_rebuild_layout_cache()
	_sync_scene_markers()
	_validate_entrance_layout()
	queue_redraw()


func _process(delta: float) -> void:
	ambient_time += delta
	ambient_redraw_accumulator += delta
	if ambient_redraw_accumulator >= ambient_redraw_interval:
		ambient_redraw_accumulator = 0.0
		queue_redraw()


func setup_navigation(next_structures_root: Node2D, next_fortress: Node2D) -> void:
	structures_root = next_structures_root
	fortress = next_fortress
	if structures_root != null:
		if not structures_root.child_entered_tree.is_connected(_on_structure_tree_changed):
			structures_root.child_entered_tree.connect(_on_structure_tree_changed)
		if not structures_root.child_exiting_tree.is_connected(_on_structure_tree_changed):
			structures_root.child_exiting_tree.connect(_on_structure_tree_changed)
	mark_navigation_dirty()


func get_world_size() -> Vector2:
	return WORLD_SIZE


func get_grid_size() -> float:
	return GRID_SIZE


func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, WORLD_SIZE)


func get_wall_rects() -> Array[Rect2]:
	var walls: Array[Rect2] = []
	for wall_rect in wall_rects:
		walls.append(wall_rect)
	return walls


func get_spawn_portal_positions() -> Dictionary:
	return portal_positions.duplicate(true)


func get_spawn_position(portal_id: StringName) -> Vector2:
	if not portal_positions.has(portal_id):
		push_warning("MapView is missing spawn portal id '%s'. Falling back to left_center." % String(portal_id))
	var spawn_position: Vector2 = portal_positions.get(portal_id, portal_positions.get(&"left_center", get_safe_zone_center()))
	return find_nearest_walkable_position(spawn_position, UNIT_RADIUS)


func get_search_route_for_portal(portal_id: StringName) -> Array[Vector2]:
	var route: Array[Vector2] = []
	match portal_id:
		&"left_center":
			route.append(path_nodes_world[&"west_gate"])
			route.append(path_nodes_world[&"north_west_room"])
		&"top_center":
			route.append(path_nodes_world[&"north_gate"])
			route.append(path_nodes_world[&"north_east_room"])
		&"bottom_center":
			route.append(path_nodes_world[&"south_gate"])
			route.append(path_nodes_world[&"south_west_room"])
		&"right_center":
			route.append(path_nodes_world[&"east_gate"])
			route.append(path_nodes_world[&"south_east_room"])
	route.append(get_safe_zone_center())
	return route


func get_safe_zone_center() -> Vector2:
	return territory_anchor.global_position


func snap_to_grid(world_position: Vector2) -> Vector2:
	return Vector2(
		round(world_position.x / GRID_SIZE) * GRID_SIZE,
		round(world_position.y / GRID_SIZE) * GRID_SIZE
	)


func is_buildable_position(world_position: Vector2, radius: float = 24.0) -> bool:
	return is_position_walkable(world_position, radius)


func is_position_walkable(world_position: Vector2, radius: float = UNIT_RADIUS) -> bool:
	var inset_rect := Rect2(Vector2(radius, radius), WORLD_SIZE - Vector2.ONE * radius * 2.0)
	if not inset_rect.has_point(world_position):
		return false

	var world_cell: Vector2i = _world_to_cell(world_position)
	if entrance_floor_cells.has(world_cell):
		return true

	for wall_rect in wall_rects:
		if _circle_intersects_rect(world_position, radius, wall_rect):
			return false

	return true


func resolve_movement(current_position: Vector2, desired_position: Vector2, radius: float = UNIT_RADIUS) -> Vector2:
	_ensure_navigation_cache()
	var clamped_position := Vector2(
		clampf(desired_position.x, radius, WORLD_SIZE.x - radius),
		clampf(desired_position.y, radius, WORLD_SIZE.y - radius)
	)

	if _is_position_open_for_unit(clamped_position, radius):
		return clamped_position

	var x_only := Vector2(clamped_position.x, current_position.y)
	if _is_position_open_for_unit(x_only, radius):
		return x_only

	var y_only := Vector2(current_position.x, clamped_position.y)
	if _is_position_open_for_unit(y_only, radius):
		return y_only

	return current_position


func get_navigation_path(start_position: Vector2, target_position: Vector2, radius: float = UNIT_RADIUS) -> Array[Vector2]:
	_ensure_navigation_cache()
	var start_cell: Vector2i = _world_to_cell(start_position)
	var target_cell: Vector2i = _world_to_cell(target_position)
	var cache_key: String = "%d|%d|%d|%d|%d|%d" % [navigation_version, int(round(radius)), start_cell.x, start_cell.y, target_cell.x, target_cell.y]
	if route_cache.has(cache_key):
		return route_cache[cache_key].duplicate()

	var route: Array[Vector2] = _find_grid_path(start_position, target_position, radius)
	route_cache[cache_key] = route.duplicate()
	return route


func has_navigation_path(start_position: Vector2, target_position: Vector2, radius: float = UNIT_RADIUS, simulated_structure: Dictionary = {}) -> bool:
	_ensure_navigation_cache()
	return not _find_grid_path(start_position, target_position, radius, simulated_structure).is_empty()


func would_structure_block_unit_paths(building_def, world_position: Vector2, units: Array[Node2D]) -> bool:
	if building_def == null or not bool(building_def.blocks_path):
		return false

	var simulated_structure: Dictionary = {
		"position": world_position,
		"radius": _get_structure_radius_from_def(building_def),
		"blocked_cells": _get_blocked_cells_for_structure(world_position, building_def.footprint_size),
	}

	for unit in units:
		if unit == null or not is_instance_valid(unit):
			continue
		var unit_health: Variant = unit.get("current_health")
		if unit_health != null and float(unit_health) <= 0.0:
			continue

		var target_position: Vector2 = get_safe_zone_center()
		if unit.has_method("has_active_move_target") and unit.has_method("get_move_target") and unit.has_active_move_target():
			target_position = unit.get_move_target()

		if not has_navigation_path(unit.global_position, target_position, UNIT_RADIUS, simulated_structure):
			return true

	return false


func get_blockable_entrances() -> Array[Dictionary]:
	var entrances: Array[Dictionary] = []
	for entrance in blockable_entrances_world:
		entrances.append(entrance.duplicate(true))
	return entrances


func is_intentional_entrance_seal(building_def, world_position: Vector2) -> bool:
	if building_def == null or not bool(building_def.allows_entrance_seal):
		return false

	var snapped_position: Vector2 = snap_to_grid(world_position)
	for entrance in blockable_entrances_world:
		if not bool(entrance.get("allows_full_block", false)):
			continue
		if Vector2(entrance.get("seal_origin", Vector2.ZERO)) != snapped_position:
			continue
		if Vector2i(entrance.get("required_blocker_footprint", Vector2i.ONE)) != building_def.footprint_size:
			continue
		return true

	return false


func is_structure_sealing_entrance(structure: Node2D) -> bool:
	if structure == null or not is_instance_valid(structure):
		return false
	var structure_def = structure.get("building_def")
	if structure_def == null:
		return false
	return is_intentional_entrance_seal(structure_def, structure.global_position)


func get_preferred_blocking_structure(from_position: Vector2, target_position: Vector2, next_structures_root: Node2D, prefers_blocking_structures: bool) -> Node2D:
	if next_structures_root == null:
		return null

	var route_exists: bool = has_navigation_path(from_position, target_position, UNIT_RADIUS)
	var best_structure: Node2D = null
	var best_distance: float = INF

	for structure in next_structures_root.get_children():
		if not (structure is Node2D):
			continue
		if not structure.has_method("blocks_enemy_path") or not structure.blocks_enemy_path():
			continue

		var should_consider: bool = false
		if is_structure_sealing_entrance(structure):
			should_consider = not route_exists or prefers_blocking_structures
		elif prefers_blocking_structures and is_structure_blocking_path(structure, from_position, target_position):
			should_consider = true
		elif not route_exists and is_structure_blocking_path(structure, from_position, target_position):
			should_consider = true

		if not should_consider:
			continue

		var distance: float = from_position.distance_to(structure.global_position)
		if distance < best_distance:
			best_distance = distance
			best_structure = structure

	return best_structure


func is_structure_blocking_path(structure: Node2D, from_position: Vector2, to_position: Vector2) -> bool:
	if structure == null:
		return false
	if not structure.has_method("blocks_enemy_path"):
		return false
	if not structure.blocks_enemy_path():
		return false

	var distance := _distance_to_segment(structure.global_position, from_position, to_position)
	if distance > GRID_SIZE * 1.25:
		return false

	return structure.global_position.distance_to(from_position) < to_position.distance_to(from_position)


func get_debug_path(start_position: Vector2, target_position: Vector2, radius: float = UNIT_RADIUS) -> Array[Vector2]:
	return get_navigation_path(start_position, target_position, radius)


func should_draw_navigation_debug() -> bool:
	return debug_navigation_paths


func get_navigation_version() -> int:
	return navigation_version


func mark_navigation_dirty() -> void:
	navigation_dirty = true
	navigation_version += 1
	route_cache.clear()


func _draw() -> void:
	var floor_tint := Color(0.06, 0.08, 0.08)
	var lower_tint := Color(0.08, 0.11, 0.1, 0.42)
	var ambient_glow_alpha: float = 0.05 + (sin(ambient_time * 0.7) + 1.0) * 0.03
	var safe_zone_alpha: float = 0.09 + (sin(ambient_time * 1.15) + 1.0) * 0.04
	var territory_center := get_safe_zone_center()

	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), floor_tint, true)
	draw_rect(Rect2(Vector2(0.0, WORLD_SIZE.y * 0.5), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.5)), lower_tint, true)

	for x in range(MAP_CELLS.x + 1):
		var world_x: float = float(x) * GRID_SIZE
		draw_line(Vector2(world_x, 0.0), Vector2(world_x, WORLD_SIZE.y), Color(0.18, 0.24, 0.22, 0.18), 1.0)

	for y in range(MAP_CELLS.y + 1):
		var world_y: float = float(y) * GRID_SIZE
		draw_line(Vector2(0.0, world_y), Vector2(WORLD_SIZE.x, world_y), Color(0.18, 0.24, 0.22, 0.18), 1.0)

	for wall_rect in wall_rects:
		draw_rect(wall_rect, Color(0.12, 0.15, 0.15), true)
		draw_rect(wall_rect.grow(-4.0), Color(0.08, 0.1, 0.1), true)

	for anchor_id in PATH_CONNECTIONS.keys():
		for neighbor_id in PATH_CONNECTIONS[anchor_id]:
			if StringName(anchor_id) > StringName(neighbor_id):
				continue
			draw_line(path_nodes_world[anchor_id], path_nodes_world[neighbor_id], Color(0.48, 0.26, 0.18, 0.35), 10.0)

	draw_circle(territory_center, build_radius + 32.0, Color(0.14, 0.18, 0.24, 0.18))
	draw_circle(territory_center, build_radius, Color(0.24, 0.39, 0.74, 0.08))
	draw_arc(territory_center, build_radius, 0.0, TAU, 72, Color(0.38, 0.6, 0.9, 0.18), 2.0)

	draw_circle(territory_center, 52.0, Color(0.72, 0.76, 0.86, 0.88))
	draw_circle(territory_center, 28.0, Color(0.19, 0.24, 0.32, 0.96))
	draw_arc(territory_center, 72.0, 0.0, TAU, 30, Color(0.75, 0.83, 0.98, 0.32), 3.0)

	for portal_position in portal_positions.values():
		_draw_portal(portal_position)

	for pocket_id in [&"north_west_room", &"north_east_room", &"south_west_room", &"south_east_room", &"center"]:
		draw_circle(path_nodes_world[pocket_id], 112.0, Color(0.16, 0.23, 0.2, ambient_glow_alpha))

	draw_circle(territory_center, 170.0, Color(0.18, 0.27, 0.22, safe_zone_alpha))
	draw_circle(territory_center, 96.0, Color(0.22, 0.36, 0.29, safe_zone_alpha * 1.2))
	draw_arc(territory_center, 148.0, 0.0, TAU, 48, Color(0.52, 0.88, 0.62, 0.22), 3.0)

	for entrance in blockable_entrances_world:
		_draw_blockable_entrance(entrance)


func _draw_portal(portal_position: Vector2) -> void:
	draw_circle(portal_position, 20.0, Color(0.18, 0.04, 0.05, 0.88))
	draw_arc(portal_position, 30.0, 0.0, TAU, 40, Color(0.96, 0.42, 0.2, 0.92), 5.0)
	draw_arc(portal_position, 20.0, 0.0, TAU, 40, Color(0.98, 0.72, 0.22, 0.85), 2.0)
	draw_circle(portal_position, 10.0, Color(0.94, 0.18, 0.18, 0.55))
	draw_rect(Rect2(portal_position + Vector2(-28.0, -8.0), Vector2(10.0, 16.0)), Color(0.28, 0.13, 0.08), true)
	draw_rect(Rect2(portal_position + Vector2(18.0, -8.0), Vector2(10.0, 16.0)), Color(0.28, 0.13, 0.08), true)


func _draw_blockable_entrance(entrance: Dictionary) -> void:
	var entrance_rect: Rect2 = entrance.get("entrance_rect", Rect2())
	draw_rect(entrance_rect, Color(0.78, 0.62, 0.18, 0.08), true)
	draw_rect(entrance_rect, Color(0.92, 0.82, 0.32, 0.28), false, 2.0)
	draw_line(entrance_rect.position, entrance_rect.end, Color(0.92, 0.78, 0.26, 0.2), 2.0)
	draw_line(Vector2(entrance_rect.end.x, entrance_rect.position.y), Vector2(entrance_rect.position.x, entrance_rect.end.y), Color(0.92, 0.78, 0.26, 0.2), 2.0)


func find_nearest_walkable_position(world_position: Vector2, radius: float) -> Vector2:
	_ensure_navigation_cache()
	if _is_position_open_for_unit(world_position, radius):
		return world_position

	for ring in range(1, 8):
		var offset := GRID_SIZE * float(ring)
		for direction in [
			Vector2(offset, 0.0),
			Vector2(-offset, 0.0),
			Vector2(0.0, offset),
			Vector2(0.0, -offset),
			Vector2(offset, offset),
			Vector2(offset, -offset),
			Vector2(-offset, offset),
			Vector2(-offset, -offset),
		]:
			var candidate: Vector2 = world_position + direction
			if _is_position_open_for_unit(candidate, radius):
				return candidate

	return get_safe_zone_center()


func _find_grid_path(start_position: Vector2, target_position: Vector2, radius: float, simulated_structure: Dictionary = {}) -> Array[Vector2]:
	var start_cell: Vector2i = _find_nearest_open_cell(_world_to_cell(start_position), radius, simulated_structure)
	var target_cell: Vector2i = _find_nearest_open_cell(_world_to_cell(target_position), radius, simulated_structure)
	if start_cell == Vector2i(-1, -1) or target_cell == Vector2i(-1, -1):
		return []

	if start_cell == target_cell:
		return [_cell_to_world(target_cell)]

	var open_set: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start_cell: 0.0}
	var f_score: Dictionary = {start_cell: _cell_heuristic(start_cell, target_cell)}

	while not open_set.is_empty():
		var current_cell: Vector2i = _pop_lowest_score_cell(open_set, f_score)
		if current_cell == target_cell:
			return _reconstruct_path(came_from, current_cell, target_position, radius)

		for neighbor in _get_neighbor_cells(current_cell):
			if not _is_cell_open(neighbor, radius, simulated_structure):
				continue

			var tentative_score: float = float(g_score.get(current_cell, INF)) + 1.0
			if tentative_score >= float(g_score.get(neighbor, INF)):
				continue

			came_from[neighbor] = current_cell
			g_score[neighbor] = tentative_score
			f_score[neighbor] = tentative_score + _cell_heuristic(neighbor, target_cell)
			if not open_set.has(neighbor):
				open_set.append(neighbor)

	return []


func _ensure_navigation_cache() -> void:
	if wall_rects.is_empty() or path_nodes_world.is_empty() or blockable_entrances_world.is_empty() or portal_positions.is_empty():
		_rebuild_layout_cache()
	if static_blocked_cells.is_empty():
		_build_static_blocked_cells()
	if not navigation_dirty:
		return

	dynamic_blocked_cells.clear()
	if structures_root != null:
		for structure in structures_root.get_children():
			if not (structure is Node2D):
				continue
			var structure_def = structure.get("building_def")
			if structure_def == null or not bool(structure_def.blocks_path):
				continue
			var blocked_cells: Array[Vector2i] = _get_blocked_cells_for_structure(structure.global_position, structure_def.footprint_size)
			for blocked_cell in blocked_cells:
				dynamic_blocked_cells[blocked_cell] = true

	navigation_dirty = false


func _reconstruct_path(came_from: Dictionary, current_cell: Vector2i, target_position: Vector2, radius: float) -> Array[Vector2]:
	var cell_path: Array[Vector2i] = [current_cell]
	var walker: Vector2i = current_cell
	while came_from.has(walker):
		walker = came_from[walker]
		cell_path.push_front(walker)

	var world_path: Array[Vector2] = []
	for path_cell in cell_path:
		world_path.append(_cell_to_world(path_cell))

	if not world_path.is_empty():
		world_path[world_path.size() - 1] = find_nearest_walkable_position(target_position, radius)

	return world_path


func _pop_lowest_score_cell(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best_index: int = 0
	var best_score: float = float(f_score.get(open_set[0], INF))
	for index in range(1, open_set.size()):
		var candidate_score: float = float(f_score.get(open_set[index], INF))
		if candidate_score < best_score:
			best_score = candidate_score
			best_index = index
	var best_cell: Vector2i = open_set[best_index]
	open_set.remove_at(best_index)
	return best_cell


func _get_neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]


func _find_nearest_open_cell(start_cell: Vector2i, radius: float, simulated_structure: Dictionary = {}) -> Vector2i:
	if _is_cell_open(start_cell, radius, simulated_structure):
		return start_cell

	for ring in range(1, 8):
		for offset_x in range(-ring, ring + 1):
			for offset_y in range(-ring, ring + 1):
				if abs(offset_x) != ring and abs(offset_y) != ring:
					continue
				var candidate: Vector2i = start_cell + Vector2i(offset_x, offset_y)
				if _is_cell_open(candidate, radius, simulated_structure):
					return candidate

	return Vector2i(-1, -1)


func _is_cell_open(cell: Vector2i, radius: float, simulated_structure: Dictionary = {}) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_CELLS.x or cell.y >= MAP_CELLS.y:
		return false
	return _is_position_open_for_unit(_cell_to_world(cell), radius, simulated_structure)


func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_position.x / GRID_SIZE)),
		int(floor(world_position.y / GRID_SIZE))
	)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * GRID_SIZE,
		(float(cell.y) + 0.5) * GRID_SIZE
	)


func _cell_origin_to_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x) * GRID_SIZE, float(cell.y) * GRID_SIZE)


func _cell_rect_to_world(rect: Rect2i) -> Rect2:
	return Rect2(_cell_origin_to_world(rect.position), Vector2(float(rect.size.x) * GRID_SIZE, float(rect.size.y) * GRID_SIZE))


func _cell_rect_center_to_world(rect: Rect2i) -> Vector2:
	return _cell_rect_to_world(rect).get_center()


func _cell_heuristic(a: Vector2i, b: Vector2i) -> float:
	return absf(float(a.x - b.x)) + absf(float(a.y - b.y))


func _is_position_open_for_unit(world_position: Vector2, radius: float, simulated_structure: Dictionary = {}) -> bool:
	if not is_position_walkable(world_position, radius):
		return false

	var world_cell: Vector2i = _world_to_cell(world_position)
	if static_blocked_cells.has(world_cell) or dynamic_blocked_cells.has(world_cell):
		return false

	if not simulated_structure.is_empty():
		var blocked_cells = simulated_structure.get("blocked_cells", [])
		if blocked_cells.has(world_cell):
			return false

	return true


func _build_static_blocked_cells() -> void:
	static_blocked_cells.clear()
	for x in range(MAP_CELLS.x):
		for y in range(MAP_CELLS.y):
			var cell := Vector2i(x, y)
			if not is_position_walkable(_cell_to_world(cell), UNIT_RADIUS):
				static_blocked_cells[cell] = true


func _get_blocked_cells_for_structure(world_position: Vector2, footprint_size: Vector2i) -> Array[Vector2i]:
	var blocked_cells: Array[Vector2i] = []
	var tile_width: int = maxi(footprint_size.x, 1)
	var tile_height: int = maxi(footprint_size.y, 1)
	var center_cell: Vector2i = _world_to_cell(world_position)
	var start_x: int = center_cell.x - int(floor(float(tile_width - 1) * 0.5))
	var start_y: int = center_cell.y - int(floor(float(tile_height - 1) * 0.5))
	for offset_x in range(tile_width):
		for offset_y in range(tile_height):
			blocked_cells.append(Vector2i(start_x + offset_x, start_y + offset_y))
	return blocked_cells


func _get_structure_radius_from_def(structure_def) -> float:
	if structure_def == null:
		return GRID_SIZE * 0.5
	var footprint: Vector2i = structure_def.footprint_size
	var footprint_tiles: int = maxi(footprint.x, footprint.y)
	return maxf(float(footprint_tiles) * GRID_SIZE * 0.5, GRID_SIZE * 0.5)


func _on_structure_tree_changed(_node: Node) -> void:
	mark_navigation_dirty()


func _circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest_x := clampf(center.x, rect.position.x, rect.end.x)
	var closest_y := clampf(center.y, rect.position.y, rect.end.y)
	return center.distance_to(Vector2(closest_x, closest_y)) < radius


func _distance_to_segment(point: Vector2, start_position: Vector2, end_position: Vector2) -> float:
	var segment := end_position - start_position
	var length_squared := segment.length_squared()

	if length_squared <= 0.0:
		return point.distance_to(start_position)

	var weight := clampf((point - start_position).dot(segment) / length_squared, 0.0, 1.0)
	var projection := start_position + segment * weight
	return point.distance_to(projection)


func _rebuild_layout_cache() -> void:
	wall_rects.clear()
	for wall_cell_rect in WALL_CELL_RECTS:
		wall_rects.append(_cell_rect_to_world(wall_cell_rect))

	path_nodes_world.clear()
	for node_id in PATH_NODE_CELLS.keys():
		path_nodes_world[node_id] = _cell_to_world(PATH_NODE_CELLS[node_id])

	blockable_entrances_world.clear()
	entrance_floor_cells.clear()
	for entrance_def in BLOCKABLE_ENTRANCE_DEFS:
		var entrance_rect: Rect2i = entrance_def["cell_rect"]
		for entrance_x in range(entrance_rect.position.x, entrance_rect.end.x):
			for entrance_y in range(entrance_rect.position.y, entrance_rect.end.y):
				entrance_floor_cells[Vector2i(entrance_x, entrance_y)] = true
		blockable_entrances_world.append({
			"id": entrance_def["id"],
			"entrance_rect": _cell_rect_to_world(entrance_rect),
			"cell_rect": entrance_rect,
			"seal_origin": _cell_origin_to_world(entrance_def["seal_cell"]),
			"required_blocker_footprint": entrance_def["required_blocker_footprint"],
			"outside_test_cell": entrance_def["outside_test_cell"],
			"inside_test_cell": entrance_def["inside_test_cell"],
			"allows_full_block": entrance_def["allows_full_block"],
		})

	portal_positions = {
		&"left_center": _cell_rect_center_to_world(Rect2i(PORTAL_CELLS[&"left_center"], PORTAL_PAD_SIZE)),
		&"top_center": _cell_rect_center_to_world(Rect2i(PORTAL_CELLS[&"top_center"], PORTAL_PAD_SIZE)),
		&"bottom_center": _cell_rect_center_to_world(Rect2i(PORTAL_CELLS[&"bottom_center"], PORTAL_PAD_SIZE)),
		&"right_center": _cell_rect_center_to_world(Rect2i(PORTAL_CELLS[&"right_center"], PORTAL_PAD_SIZE)),
	}

	static_blocked_cells.clear()
	navigation_dirty = true
	route_cache.clear()


func _sync_scene_markers() -> void:
	territory_anchor.position = _cell_rect_center_to_world(TERRITORY_PAD)
	left_center_portal.position = portal_positions[&"left_center"]
	top_center_portal.position = portal_positions[&"top_center"]
	bottom_center_portal.position = portal_positions[&"bottom_center"]
	right_center_portal.position = portal_positions[&"right_center"]


func _validate_entrance_layout() -> void:
	_build_static_blocked_cells()

	for entrance in blockable_entrances_world:
		var entrance_id: String = String(entrance.get("id", &"unknown"))
		var entrance_rect: Rect2i = entrance.get("cell_rect", Rect2i())
		for entrance_x in range(entrance_rect.position.x, entrance_rect.end.x):
			for entrance_y in range(entrance_rect.position.y, entrance_rect.end.y):
				var entrance_cell := Vector2i(entrance_x, entrance_y)
				if static_blocked_cells.has(entrance_cell):
					push_warning("Map error: entrance '%s' cell %s is statically blocked." % [entrance_id, str(entrance_cell)])

	var safe_zone_target: Vector2 = get_safe_zone_center()
	for portal_id in portal_positions.keys():
		var portal_position: Vector2 = portal_positions[portal_id]
		if not has_navigation_path(portal_position, safe_zone_target, UNIT_RADIUS):
			push_warning("Map error: entrance layout sealed by static blockers before barricades. Portal '%s' has no route to survivor area." % String(portal_id))
