extends Node2D

var is_valid_preview: bool = false:
	set(value):
		is_valid_preview = value
		queue_redraw()


func _draw() -> void:
	var preview_color: Color = Color(0.24, 0.85, 0.42, 0.35) if is_valid_preview else Color(0.9, 0.24, 0.24, 0.35)
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64, 64)), preview_color, true)
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64, 64)), Color(0.95, 0.95, 0.95, 0.8), false, 2.0)
	var accent: Color = Color(0.52, 0.96, 0.66, 0.9) if is_valid_preview else Color(0.96, 0.42, 0.42, 0.9)
	draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 28, accent, 2.0)
	draw_line(Vector2(-12, 0), Vector2(12, 0), accent, 2.0)
	draw_line(Vector2(0, -12), Vector2(0, 12), accent, 2.0)
