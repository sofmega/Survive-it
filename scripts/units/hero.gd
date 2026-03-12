extends Node2D

const SPEED := 260.0

var velocity := Vector2.ZERO


func _process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	position += velocity * delta
	position.x = clamp(position.x, 32.0, 1568.0)
	position.y = clamp(position.y, 32.0, 868.0)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color(0.3, 0.8, 0.45))
	draw_circle(Vector2(0, 0), 8.0, Color(0.08, 0.16, 0.1))
	draw_line(Vector2.ZERO, Vector2(24, 0), Color(0.95, 0.95, 0.95), 2.0)

