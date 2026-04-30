extends Node2D

const WORLD_SIZE := Vector2(3840.0, 2160.0)
const GRID_SIZE := 64.0
const UNIT_RADIUS := 22.0

const WALL_RECTS := [
	Rect2(Vector2(0.0, 0.0), Vector2(3840.0, 140.0)),
	Rect2(Vector2(0.0, 2020.0), Vector2(3840.0, 140.0)),
	Rect2(Vector2(0.0, 0.0), Vector2(140.0, 2160.0)),
	Rect2(Vector2(3700.0, 0.0), Vector2(140.0, 2160.0)),
	Rect2(Vector2(1700.0, 140.0), Vector2(120.0, 700.0)),
	Rect2(Vector2(2020.0, 140.0), Vector2(120.0, 700.0)),
	Rect2(Vector2(1700.0, 1320.0), Vector2(120.0, 700.0)),
	Rect2(Vector2(2020.0, 1320.0), Vector2(120.0, 700.0)),
	Rect2(Vector2(140.0, 960.0), Vector2(1420.0, 120.0)),
	Rect2(Vector2(2280.0, 960.0), Vector2(1420.0, 120.0)),
	Rect2(Vector2(140.0, 1160.0), Vector2(1420.0, 120.0)),
	Rect2(Vector2(2280.0, 1160.0), Vector2(1420.0, 120.0)),
	Rect2(Vector2(520.0, 360.0), Vector2(820.0, 120.0)),
	Rect2(Vector2(520.0, 360.0), Vector2(120.0, 460.0)),
	Rect2(Vector2(1220.0, 360.0), Vector2(120.0, 460.0)),
	Rect2(Vector2(760.0, 660.0), Vector2(460.0, 120.0)),
	Rect2(Vector2(760.0, 660.0), Vector2(120.0, 300.0)),
	Rect2(Vector2(2520.0, 360.0), Vector2(780.0, 120.0)),
	Rect2(Vector2(2520.0, 360.0), Vector2(120.0, 460.0)),
	Rect2(Vector2(3180.0, 360.0), Vector2(120.0, 460.0)),
	Rect2(Vector2(2520.0, 700.0), Vector2(520.0, 120.0)),
	Rect2(Vector2(2920.0, 700.0), Vector2(120.0, 260.0)),
	Rect2(Vector2(520.0, 1500.0), Vector2(860.0, 120.0)),
	Rect2(Vector2(520.0, 1500.0), Vector2(120.0, 420.0)),
	Rect2(Vector2(1260.0, 1500.0), Vector2(120.0, 420.0)),
	Rect2(Vector2(820.0, 1320.0), Vector2(700.0, 120.0)),
	Rect2(Vector2(820.0, 1320.0), Vector2(120.0, 360.0)),
	Rect2(Vector2(2460.0, 1500.0), Vector2(860.0, 120.0)),
	Rect2(Vector2(2460.0, 1500.0), Vector2(120.0, 420.0)),
	Rect2(Vector2(3200.0, 1500.0), Vector2(120.0, 420.0)),
	Rect2(Vector2(2460.0, 1320.0), Vector2(620.0, 120.0)),
	Rect2(Vector2(2460.0, 1320.0), Vector2(120.0, 360.0)),
]

const PATH_NODES := {
	&"center": Vector2(1920.0, 1080.0),
	&"west_gate": Vector2(980.0, 1080.0),
	&"east_gate": Vector2(2860.0, 1080.0),
	&"north_gate": Vector2(1920.0, 760.0),
	&"south_gate": Vector2(1920.0, 1400.0),
	&"north_west_room": Vector2(920.0, 560.0),
	&"north_east_room": Vector2(2920.0, 560.0),
	&"south_west_room": Vector2(920.0, 1660.0),
	&"south_east_room": Vector2(2920.0, 1660.0),
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

@export var build_radius := 420.0

var ambient_time: float = 0.0

@onready var territory_anchor: Marker2D = $TerritoryAnchor
@onready var left_center_portal: Marker2D = $SpawnPoints/LeftCenterPortal
@onready var top_center_portal: Marker2D = $SpawnPoints/TopCenterPortal
@onready var bottom_center_portal: Marker2D = $SpawnPoints/BottomCenterPortal
@onready var right_center_portal: Marker2D = $SpawnPoints/RightCenterPortal


func _process(delta: float) -> void:
	ambient_time += delta
	queue_redraw()


func get_world_size() -> Vector2:
	return WORLD_SIZE


func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, WORLD_SIZE)


func get_wall_rects() -> Array[Rect2]:
	var walls: Array[Rect2] = []
	for wall_rect in WALL_RECTS:
		walls.append(wall_rect)
	return walls


func get_spawn_portal_positions() -> Dictionary:
	return {
		&"left_center": left_center_portal.global_position,
		&"top_center": top_center_portal.global_position,
		&"bottom_center": bottom_center_portal.global_position,
		&"right_center": right_center_portal.global_position,
	}


func get_spawn_position(portal_id: StringName) -> Vector2:
	return get_spawn_portal_positions().get(portal_id, left_center_portal.global_position)


func get_search_route_for_portal(portal_id: StringName) -> Array[Vector2]:
	var route: Array[Vector2] = []
	match portal_id:
		&"left_center":
			route.append(PATH_NODES[&"west_gate"])
			route.append(PATH_NODES[&"north_west_room"])
		&"top_center":
			route.append(PATH_NODES[&"north_gate"])
			route.append(PATH_NODES[&"north_east_room"])
		&"bottom_center":
			route.append(PATH_NODES[&"south_gate"])
			route.append(PATH_NODES[&"south_west_room"])
		&"right_center":
			route.append(PATH_NODES[&"east_gate"])
			route.append(PATH_NODES[&"south_east_room"])
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

	for wall_rect in WALL_RECTS:
		if _circle_intersects_rect(world_position, radius, wall_rect):
			return false

	return true


func resolve_movement(current_position: Vector2, desired_position: Vector2, radius: float = UNIT_RADIUS) -> Vector2:
	var clamped_position := Vector2(
		clampf(desired_position.x, radius, WORLD_SIZE.x - radius),
		clampf(desired_position.y, radius, WORLD_SIZE.y - radius)
	)

	if is_position_walkable(clamped_position, radius):
		return clamped_position

	var x_only := Vector2(clamped_position.x, current_position.y)
	if is_position_walkable(x_only, radius):
		return x_only

	var y_only := Vector2(current_position.x, clamped_position.y)
	if is_position_walkable(y_only, radius):
		return y_only

	return current_position


func get_navigation_path(start_position: Vector2, target_position: Vector2, radius: float = UNIT_RADIUS) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var final_target := target_position

	if not is_position_walkable(final_target, radius):
		final_target = _find_nearest_walkable_position(target_position, radius)

	if not _segment_hits_wall(start_position, final_target, radius):
		path.append(final_target)
		return path

	var start_id := _get_nearest_path_node(start_position)
	var target_id := _get_nearest_path_node(final_target)
	var route_ids := _find_route(start_id, target_id)

	for route_id in route_ids:
		path.append(PATH_NODES[route_id])

	path.append(final_target)
	return path


func is_structure_blocking_path(structure: Node2D, from_position: Vector2, to_position: Vector2) -> bool:
	if structure == null:
		return false
	if not structure.has_method("blocks_enemy_path"):
		return false
	if not structure.blocks_enemy_path():
		return false

	var distance := _distance_to_segment(structure.global_position, from_position, to_position)
	if distance > 34.0:
		return false

	return structure.global_position.distance_to(from_position) < to_position.distance_to(from_position)


func _draw() -> void:
	var floor_tint := Color(0.06, 0.08, 0.08)
	var lower_tint := Color(0.08, 0.11, 0.1, 0.42)
	var ambient_glow_alpha: float = 0.05 + (sin(ambient_time * 0.7) + 1.0) * 0.03
	var safe_zone_alpha: float = 0.09 + (sin(ambient_time * 1.15) + 1.0) * 0.04
	var territory_center := get_safe_zone_center()

	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), floor_tint, true)
	draw_rect(Rect2(Vector2(0.0, WORLD_SIZE.y * 0.5), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.5)), lower_tint, true)

	for x in range(0, int(WORLD_SIZE.x) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color(0.18, 0.24, 0.22, 0.18), 1.0)

	for y in range(0, int(WORLD_SIZE.y) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color(0.18, 0.24, 0.22, 0.18), 1.0)

	for wall_rect in WALL_RECTS:
		draw_rect(wall_rect, Color(0.12, 0.15, 0.15), true)
		draw_rect(wall_rect.grow(-10.0), Color(0.08, 0.1, 0.1), true)

	for anchor_id in PATH_CONNECTIONS.keys():
		for neighbor_id in PATH_CONNECTIONS[anchor_id]:
			if StringName(anchor_id) > StringName(neighbor_id):
				continue
			draw_line(PATH_NODES[anchor_id], PATH_NODES[neighbor_id], Color(0.48, 0.26, 0.18, 0.35), 18.0)

	draw_circle(territory_center, build_radius + 36.0, Color(0.14, 0.18, 0.24, 0.18))
	draw_circle(territory_center, build_radius, Color(0.24, 0.39, 0.74, 0.08))
	draw_arc(territory_center, build_radius, 0.0, TAU, 72, Color(0.38, 0.6, 0.9, 0.18), 2.0)

	draw_circle(territory_center, 68.0, Color(0.72, 0.76, 0.86, 0.88))
	draw_circle(territory_center, 38.0, Color(0.19, 0.24, 0.32, 0.96))
	draw_arc(territory_center, 92.0, 0.0, TAU, 30, Color(0.75, 0.83, 0.98, 0.32), 3.0)

	for portal_position in get_spawn_portal_positions().values():
		_draw_portal(portal_position)

	for pocket in [
		PATH_NODES[&"north_west_room"],
		PATH_NODES[&"north_east_room"],
		PATH_NODES[&"south_west_room"],
		PATH_NODES[&"south_east_room"],
		territory_center,
	]:
		draw_circle(pocket, 180.0, Color(0.16, 0.23, 0.2, ambient_glow_alpha))

	draw_circle(territory_center, 260.0, Color(0.18, 0.27, 0.22, safe_zone_alpha))
	draw_circle(territory_center, 150.0, Color(0.22, 0.36, 0.29, safe_zone_alpha * 1.2))
	draw_arc(territory_center, 220.0, 0.0, TAU, 48, Color(0.52, 0.88, 0.62, 0.22), 3.0)


func _draw_portal(portal_position: Vector2) -> void:
	draw_circle(portal_position, 38.0, Color(0.18, 0.04, 0.05, 0.88))
	draw_arc(portal_position, 54.0, 0.0, TAU, 40, Color(0.96, 0.42, 0.2, 0.92), 6.0)
	draw_arc(portal_position, 38.0, 0.0, TAU, 40, Color(0.98, 0.72, 0.22, 0.85), 3.0)
	draw_circle(portal_position, 22.0, Color(0.94, 0.18, 0.18, 0.55))
	draw_rect(Rect2(portal_position + Vector2(-52.0, -12.0), Vector2(16.0, 24.0)), Color(0.28, 0.13, 0.08), true)
	draw_rect(Rect2(portal_position + Vector2(36.0, -12.0), Vector2(16.0, 24.0)), Color(0.28, 0.13, 0.08), true)


func _find_nearest_walkable_position(world_position: Vector2, radius: float) -> Vector2:
	if is_position_walkable(world_position, radius):
		return world_position

	for step in range(1, 8):
		var offset := GRID_SIZE * float(step)
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
			if is_position_walkable(candidate, radius):
				return candidate

	return get_safe_zone_center()


func _get_nearest_path_node(world_position: Vector2) -> StringName:
	var nearest_id: StringName = &"center"
	var best_distance: float = INF

	for node_id in PATH_NODES.keys():
		var distance := world_position.distance_to(PATH_NODES[node_id])
		if distance < best_distance:
			best_distance = distance
			nearest_id = node_id

	return nearest_id


func _find_route(start_id: StringName, target_id: StringName) -> Array[StringName]:
	if start_id == target_id:
		return [target_id]

	var frontier: Array[StringName] = [start_id]
	var came_from: Dictionary = {start_id: StringName()}

	while not frontier.is_empty():
		var current_id: StringName = frontier.pop_front()
		if current_id == target_id:
			break

		var neighbor_ids: Array = PATH_CONNECTIONS.get(current_id, [])
		for neighbor_id_value in neighbor_ids:
			var neighbor_id: StringName = neighbor_id_value
			if came_from.has(neighbor_id):
				continue

			came_from[neighbor_id] = current_id
			frontier.append(neighbor_id)

	if not came_from.has(target_id):
		return [target_id]

	var route: Array[StringName] = [target_id]
	var next_id: StringName = target_id

	while next_id != start_id:
		var previous_id: Variant = came_from[next_id]
		next_id = previous_id

		if next_id == StringName():
			break

		route.push_front(next_id)

	return route


func _segment_hits_wall(start_position: Vector2, end_position: Vector2, radius: float) -> bool:
	var distance := start_position.distance_to(end_position)
	if distance <= 1.0:
		return false

	var steps := maxi(int(ceil(distance / 48.0)), 1)

	for step in range(steps + 1):
		var sample_position := start_position.lerp(end_position, float(step) / float(steps))
		if not is_position_walkable(sample_position, radius):
			return true

	return false


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
