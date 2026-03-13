extends Node2D

const WORLD_SIZE := Vector2(1600.0, 900.0)
const GRID_SIZE := 64.0

@export var fortress_position := Vector2(800.0, 450.0)
@export var west_spawn_position := Vector2(96.0, 450.0)
@export var build_radius := 280.0


func _draw() -> void:
	var grid_color := Color(0.21, 0.25, 0.21, 0.45)
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.07, 0.09, 0.08), true)
	draw_rect(Rect2(Vector2(0, 0), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.45)), Color(0.1, 0.14, 0.11, 0.35), true)
	draw_rect(Rect2(Vector2(0, WORLD_SIZE.y * 0.45), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.55)), Color(0.05, 0.08, 0.06, 0.2), true)

	for x in range(0, int(WORLD_SIZE.x) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), grid_color, 1.0)

	for y in range(0, int(WORLD_SIZE.y) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), grid_color, 1.0)

	draw_line(west_spawn_position, fortress_position, Color(0.64, 0.21, 0.18, 0.8), 14.0)
	draw_line(west_spawn_position + Vector2(0, -22), fortress_position + Vector2(0, -22), Color(0.31, 0.12, 0.12, 0.4), 4.0)
	draw_line(west_spawn_position + Vector2(0, 22), fortress_position + Vector2(0, 22), Color(0.31, 0.12, 0.12, 0.4), 4.0)
	draw_circle(fortress_position, build_radius, Color(0.25, 0.45, 0.88, 0.08))
	draw_arc(fortress_position, build_radius, 0.0, TAU, 72, Color(0.42, 0.66, 0.95, 0.22), 2.0)
	draw_circle(west_spawn_position, 26.0, Color(0.83, 0.26, 0.23, 0.85))
	draw_circle(west_spawn_position, 12.0, Color(0.25, 0.07, 0.06, 0.9))
