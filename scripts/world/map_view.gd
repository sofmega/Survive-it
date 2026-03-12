extends Node2D

const WORLD_SIZE := Vector2(1600.0, 900.0)
const GRID_SIZE := 64.0

@export var fortress_position := Vector2(800.0, 450.0)
@export var west_spawn_position := Vector2(96.0, 450.0)
@export var build_radius := 280.0


func _draw() -> void:
	var grid_color := Color(0.18, 0.22, 0.2, 0.55)
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.09, 0.12, 0.1), true)

	for x in range(0, int(WORLD_SIZE.x) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), grid_color, 1.0)

	for y in range(0, int(WORLD_SIZE.y) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), grid_color, 1.0)

	draw_line(west_spawn_position, fortress_position, Color(0.58, 0.18, 0.18, 0.7), 10.0)
	draw_circle(fortress_position, build_radius, Color(0.25, 0.45, 0.88, 0.08))
	draw_circle(west_spawn_position, 22.0, Color(0.83, 0.26, 0.23))

