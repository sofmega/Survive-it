extends Node2D

var marker_color: Color = Color(0.92, 0.95, 0.32, 0.9)
var marker_time: float = 0.0
var marker_radius: float = 18.0
var marker_mode: StringName = &"move"


func _process(delta: float) -> void:
	if marker_time <= 0.0:
		return

	marker_time = maxf(marker_time - delta, 0.0)
	queue_redraw()
	if marker_time <= 0.0:
		visible = false


func show_marker(world_position: Vector2, next_color: Color, next_mode: StringName = &"move") -> void:
	global_position = world_position
	marker_color = next_color
	marker_time = 0.42
	marker_mode = next_mode
	visible = true
	queue_redraw()


func _draw() -> void:
	if marker_time <= 0.0:
		return

	var progress: float = 1.0 - (marker_time / 0.42)
	var radius: float = marker_radius + progress * 20.0
	var alpha: float = 0.85 - progress * 0.6
	var color: Color = Color(marker_color.r, marker_color.g, marker_color.b, alpha)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 3.0)
	match marker_mode:
		&"build":
			draw_rect(Rect2(Vector2(-10, -10), Vector2(20, 20)), color, false, 2.0)
			draw_line(Vector2(-10, 0), Vector2(10, 0), color, 2.0)
			draw_line(Vector2(0, -10), Vector2(0, 10), color, 2.0)
		&"cancel":
			draw_line(Vector2(-9, -9), Vector2(9, 9), color, 3.0)
			draw_line(Vector2(-9, 9), Vector2(9, -9), color, 3.0)
		_:
			draw_line(Vector2(-8, 0), Vector2(8, 0), color, 2.0)
			draw_line(Vector2(0, -8), Vector2(0, 8), color, 2.0)
