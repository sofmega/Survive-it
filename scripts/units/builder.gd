extends Node2D

var is_controlled: bool = false
var move_speed: float = 180.0
var selected_building_def = preload("res://data/buildings/arrow_tower.tres")


func set_controlled(next_controlled: bool) -> void:
	is_controlled = next_controlled
	queue_redraw()


func get_selected_building_name() -> String:
	if selected_building_def == null:
		return "None"

	return selected_building_def.display_name


func _process(delta: float) -> void:
	if not is_controlled:
		return

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += input_vector * move_speed * delta
	position.x = clamp(position.x, 64.0, 1536.0)
	position.y = clamp(position.y, 64.0, 836.0)
	queue_redraw()


func _draw() -> void:
	var body_color := Color(0.31, 0.69, 0.93)
	var selection_color := Color(0.92, 0.95, 0.32) if is_controlled else Color(0.18, 0.21, 0.29)
	draw_rect(Rect2(Vector2(-14, -14), Vector2(28, 28)), body_color, true)
	draw_rect(Rect2(Vector2(-18, -18), Vector2(36, 36)), selection_color, false, 2.0)
