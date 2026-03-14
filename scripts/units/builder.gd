extends Node2D

var is_selected: bool = false
var move_speed: float = 180.0
var selected_building_def = preload("res://data/buildings/arrow_tower.tres")
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false


func set_selected(next_selected: bool) -> void:
	is_selected = next_selected
	queue_redraw()


func set_move_target(target_position: Vector2) -> void:
	move_target = target_position
	has_move_target = true


func clear_move_target() -> void:
	has_move_target = false


func has_active_move_target() -> bool:
	return has_move_target


func get_move_target() -> Vector2:
	return move_target


func get_selected_building_name() -> String:
	if selected_building_def == null:
		return "None"

	return selected_building_def.display_name


func _process(delta: float) -> void:
	if has_move_target:
		var direction := move_target - global_position
		if direction.length() <= move_speed * delta:
			global_position = move_target
			has_move_target = false
		else:
			global_position += direction.normalized() * move_speed * delta

		position.x = clamp(position.x, 64.0, 1536.0)
		position.y = clamp(position.y, 64.0, 836.0)

	queue_redraw()


func _draw() -> void:
	var body_color := Color(0.31, 0.69, 0.93)
	var apron_color := Color(0.17, 0.24, 0.33)
	var selection_color := Color(0.92, 0.95, 0.32) if is_selected else Color(0.18, 0.21, 0.29)
	draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), body_color, true)
	draw_rect(Rect2(Vector2(-8, 2), Vector2(16, 16)), apron_color, true)
	draw_circle(Vector2(0, -10), 8.0, Color(0.9, 0.86, 0.78))
	draw_line(Vector2(8, -2), Vector2(22, 12), Color(0.78, 0.78, 0.82), 3.0)
	draw_rect(Rect2(Vector2(18, 8), Vector2(10, 8)), Color(0.43, 0.29, 0.15), true)
	draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 40)), selection_color, false, 2.0)
