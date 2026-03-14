extends Node2D

var tracked_unit: Node2D = null
var move_target: Vector2 = Vector2.ZERO
var show_move_target: bool = false
var pulse_time: float = 0.0


func _process(delta: float) -> void:
	pulse_time += delta
	if tracked_unit != null:
		global_position = tracked_unit.global_position
	queue_redraw()


func update_tracking(unit: Node2D, next_show_move_target: bool, next_move_target: Vector2) -> void:
	tracked_unit = unit
	show_move_target = next_show_move_target
	move_target = next_move_target
	visible = tracked_unit != null
	queue_redraw()


func _draw() -> void:
	if tracked_unit == null:
		return

	var pulse: float = 2.0 + sin(pulse_time * 4.2) * 1.5
	var outer_radius: float = 28.0 + pulse
	var inner_radius: float = 22.0 + pulse * 0.4
	var glow_color := Color(0.42, 0.86, 1.0, 0.72)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 36, glow_color, 3.0)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 28, Color(0.3, 0.85, 1.0, 0.6), 2.0)
	draw_circle(Vector2.ZERO, 4.0, Color(0.95, 0.95, 0.95, 0.55))
	draw_circle(Vector2.ZERO, 12.0, Color(0.12, 0.22, 0.35, 0.35))

	if show_move_target:
		var target_local: Vector2 = to_local(move_target)
		var target_color := Color(0.94, 0.97, 0.42, 0.65)
		draw_dashed_line(Vector2.ZERO, target_local, target_color, 3.0, 10.0)
		draw_arc(target_local, 16.0, 0.0, TAU, 28, target_color, 2.0)
		draw_circle(target_local, 8.0, Color(0.95, 0.32, 0.32, 0.26), true)
		draw_arc(target_local, 20.0, 0.0, TAU, 24, target_color, 2.0)

		if target_local.length() > 8.0:
			var direction := target_local.normalized()
			var arrow_tip := target_local
			var arrow_left := arrow_tip - direction.rotated(PI / 6) * 18.0
			var arrow_right := arrow_tip - direction.rotated(-PI / 6) * 18.0
			draw_line(arrow_tip, arrow_left, target_color, 2.5)
			draw_line(arrow_tip, arrow_right, target_color, 2.5)
