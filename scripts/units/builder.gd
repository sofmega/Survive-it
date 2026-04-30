extends Node2D

signal destroyed(unit: Node)

var is_selected: bool = false
var move_speed: float = 180.0
var max_health: float = 90.0
var current_health: float = 90.0
var selected_building_def = preload("res://data/buildings/arrow_tower.tres")
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false
var map_view: Node = null
var path_points: Array[Vector2] = []
var stalled_time: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var repath_cooldown_remaining: float = 0.0
var last_navigation_version: int = -1


func setup(next_map_view: Node) -> void:
	map_view = next_map_view
	current_health = max_health
	last_position = global_position
	last_navigation_version = _get_navigation_version()


func set_selected(next_selected: bool) -> void:
	is_selected = next_selected
	queue_redraw()


func set_move_target(target_position: Vector2) -> void:
	move_target = target_position
	has_move_target = false
	path_points = _request_navigation_path(target_position)
	if path_points.is_empty():
		push_warning("Builder command rejected because no navigation path was found.")
		return
	has_move_target = true
	stalled_time = 0.0
	repath_cooldown_remaining = 0.2
	_refresh_path_visual()


func clear_move_target() -> void:
	has_move_target = false
	path_points.clear()
	stalled_time = 0.0
	_refresh_path_visual()


func has_active_move_target() -> bool:
	return has_move_target


func get_move_target() -> Vector2:
	return move_target


func get_selected_building_name() -> String:
	if selected_building_def == null:
		return "None"

	return selected_building_def.display_name


func receive_damage(amount: float, _source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	if current_health <= 0.0:
		destroyed.emit(self)
		queue_free()


func _process(delta: float) -> void:
	if has_move_target:
		_follow_path(delta)
		repath_cooldown_remaining = maxf(repath_cooldown_remaining - delta, 0.0)
		var moved_distance: float = global_position.distance_to(last_position)
		if moved_distance <= 1.0:
			stalled_time += delta
		else:
			stalled_time = 0.0
	last_position = global_position


func _follow_path(delta: float) -> void:
	if path_points.is_empty():
		has_move_target = false
		return

	if _should_repath():
		path_points = _request_navigation_path(move_target)
		stalled_time = 0.0
		repath_cooldown_remaining = 0.2
		if path_points.is_empty():
			has_move_target = false
			push_warning("Builder movement stopped because the route became unreachable.")
			_refresh_path_visual()
			return
		_refresh_path_visual()

	var next_point := path_points[0]
	var direction := next_point - global_position
	var step := move_speed * delta
	if direction.length() <= 1.0:
		path_points.remove_at(0)
		_refresh_path_visual()
		if path_points.is_empty():
			has_move_target = false
		return
	var desired_position := next_point
	if direction.length() > step:
		desired_position = global_position + direction.normalized() * step

	if map_view != null and map_view.has_method("resolve_movement"):
		global_position = map_view.resolve_movement(global_position, desired_position, 18.0)
	else:
		global_position = desired_position

	if global_position.distance_to(next_point) <= 10.0:
		path_points.remove_at(0)
		_refresh_path_visual()

	if path_points.is_empty():
		has_move_target = false
		_refresh_path_visual()


func _draw() -> void:
	var body_color := Color(0.31, 0.69, 0.93)
	var apron_color := Color(0.17, 0.24, 0.33)
	var selection_color := Color(0.92, 0.95, 0.32) if is_selected else Color(0.18, 0.21, 0.29)
	var health_ratio := current_health / max_health
	draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), body_color, true)
	draw_rect(Rect2(Vector2(-8, 2), Vector2(16, 16)), apron_color, true)
	draw_circle(Vector2(0, -10), 8.0, Color(0.9, 0.86, 0.78))
	draw_line(Vector2(8, -2), Vector2(22, 12), Color(0.78, 0.78, 0.82), 3.0)
	draw_rect(Rect2(Vector2(18, 8), Vector2(10, 8)), Color(0.43, 0.29, 0.15), true)
	if _should_draw_debug_path() and path_points.size() > 0:
		var debug_points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for path_point in path_points:
			debug_points.append(to_local(path_point))
		draw_polyline(debug_points, Color(0.52, 0.86, 1.0, 0.9), 2.0)
	draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 40)), selection_color, false, 2.0)
	draw_rect(Rect2(Vector2(-20, -28), Vector2(40, 6)), Color(0.08, 0.08, 0.08), true)
	draw_rect(Rect2(Vector2(-20, -28), Vector2(40 * health_ratio, 6)), Color(0.34, 0.88, 0.45), true)


func _request_navigation_path(target_position: Vector2) -> Array[Vector2]:
	if map_view != null and map_view.has_method("get_navigation_path"):
		last_navigation_version = _get_navigation_version()
		return map_view.get_navigation_path(global_position, target_position, 18.0)

	var direct_path: Array[Vector2] = []
	direct_path.append(target_position)
	return direct_path


func _should_repath() -> bool:
	if repath_cooldown_remaining > 0.0:
		return false
	if stalled_time >= 0.35:
		return true
	return _get_navigation_version() != last_navigation_version


func _get_navigation_version() -> int:
	if map_view != null and map_view.has_method("get_navigation_version"):
		return map_view.get_navigation_version()
	return -1


func _should_draw_debug_path() -> bool:
	if map_view != null and map_view.has_method("should_draw_navigation_debug"):
		return map_view.should_draw_navigation_debug()
	return false


func _refresh_path_visual() -> void:
	if _should_draw_debug_path():
		queue_redraw()
