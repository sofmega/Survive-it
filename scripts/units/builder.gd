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


func setup(next_map_view: Node) -> void:
	map_view = next_map_view
	current_health = max_health


func set_selected(next_selected: bool) -> void:
	is_selected = next_selected
	queue_redraw()


func set_move_target(target_position: Vector2) -> void:
	move_target = target_position
	has_move_target = true
	if map_view != null and map_view.has_method("get_navigation_path"):
		path_points = map_view.get_navigation_path(global_position, target_position, 18.0)
	else:
		path_points.clear()
		path_points.append(target_position)


func clear_move_target() -> void:
	has_move_target = false
	path_points.clear()


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

	queue_redraw()


func _follow_path(delta: float) -> void:
	if path_points.is_empty():
		has_move_target = false
		return

	var next_point := path_points[0]
	var direction := next_point - global_position
	var step := move_speed * delta
	var desired_position := next_point
	if direction.length() > step:
		desired_position = global_position + direction.normalized() * step

	if map_view != null and map_view.has_method("resolve_movement"):
		global_position = map_view.resolve_movement(global_position, desired_position, 18.0)
	else:
		global_position = desired_position

	if global_position.distance_to(next_point) <= 10.0:
		path_points.remove_at(0)

	if path_points.is_empty():
		has_move_target = false


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
	draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 40)), selection_color, false, 2.0)
	draw_rect(Rect2(Vector2(-20, -28), Vector2(40, 6)), Color(0.08, 0.08, 0.08), true)
	draw_rect(Rect2(Vector2(-20, -28), Vector2(40 * health_ratio, 6)), Color(0.34, 0.88, 0.45), true)
