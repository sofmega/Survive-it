extends Node2D

const WORLD_SIZE := Vector2(1600.0, 900.0)
const GRID_SIZE := 64.0

@export var fortress_position := Vector2(800.0, 450.0)
@export var west_spawn_position := Vector2(96.0, 450.0)
@export var build_radius := 280.0
var ambient_time: float = 0.0


func _process(delta: float) -> void:
	ambient_time += delta
	queue_redraw()


func _draw() -> void:
	var grid_color: Color = Color(0.21, 0.25, 0.21, 0.3)
	var lane_core: Color = Color(0.52, 0.24, 0.19, 0.88)
	var lane_edge: Color = Color(0.22, 0.11, 0.1, 0.7)
	var ambient_glow_alpha: float = 0.05 + (sin(ambient_time * 0.7) + 1.0) * 0.03
	var plaza_glow_alpha: float = 0.08 + (sin(ambient_time * 1.2) + 1.0) * 0.04
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.06, 0.08, 0.08), true)
	draw_rect(Rect2(Vector2(0, 0), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.38)), Color(0.08, 0.12, 0.11, 0.42), true)
	draw_rect(Rect2(Vector2(0, WORLD_SIZE.y * 0.38), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.32)), Color(0.1, 0.13, 0.1, 0.3), true)
	draw_rect(Rect2(Vector2(0, WORLD_SIZE.y * 0.7), Vector2(WORLD_SIZE.x, WORLD_SIZE.y * 0.3)), Color(0.05, 0.07, 0.07, 0.4), true)
	draw_circle(Vector2(250.0, 210.0), 170.0, Color(0.16, 0.25, 0.2, ambient_glow_alpha))
	draw_circle(Vector2(1280.0, 690.0), 220.0, Color(0.12, 0.19, 0.23, ambient_glow_alpha * 0.9))

	for x in range(0, int(WORLD_SIZE.x) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), grid_color, 1.0)

	for y in range(0, int(WORLD_SIZE.y) + int(GRID_SIZE), int(GRID_SIZE)):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), grid_color, 1.0)

	for x in range(int(fortress_position.x - build_radius), int(fortress_position.x + build_radius + GRID_SIZE), int(GRID_SIZE)):
		for y in range(int(fortress_position.y - build_radius), int(fortress_position.y + build_radius + GRID_SIZE), int(GRID_SIZE)):
			var tile_center: Vector2 = Vector2(float(x), float(y))
			if tile_center.distance_to(fortress_position) <= build_radius - 16.0 and absf(tile_center.y - west_spawn_position.y) >= 72.0:
				draw_rect(Rect2(tile_center - Vector2(28.0, 28.0), Vector2(56.0, 56.0)), Color(0.18, 0.34, 0.42, 0.08), true)

	draw_circle(fortress_position, build_radius + 56.0, Color(0.12, 0.18, 0.24, 0.14))
	draw_circle(fortress_position, build_radius, Color(0.25, 0.45, 0.88, 0.08))
	draw_arc(fortress_position, build_radius, 0.0, TAU, 72, Color(0.42, 0.66, 0.95, 0.22), 2.0)
	draw_circle(fortress_position, 132.0, Color(0.28, 0.22, 0.15, plaza_glow_alpha))
	draw_circle(fortress_position, 112.0, Color(0.18, 0.2, 0.21, 0.65))
	draw_circle(fortress_position, 88.0, Color(0.11, 0.14, 0.15, 0.75))
	draw_arc(fortress_position, 96.0, 0.0, TAU, 48, Color(0.74, 0.68, 0.48, 0.55), 3.0)
	draw_arc(fortress_position, 146.0, 0.0, TAU, 60, Color(0.9, 0.8, 0.46, 0.18), 2.0)
	draw_line(west_spawn_position, fortress_position, lane_core, 22.0)
	draw_line(west_spawn_position + Vector2(0, -28), fortress_position + Vector2(0, -28), lane_edge, 6.0)
	draw_line(west_spawn_position + Vector2(0, 28), fortress_position + Vector2(0, 28), lane_edge, 6.0)
	draw_rect(Rect2(Vector2(0.0, west_spawn_position.y - 42.0), Vector2(WORLD_SIZE.x, 84.0)), Color(0.3, 0.13, 0.11, 0.16), true)
	for x in range(160, 1500, 170):
		draw_rect(Rect2(Vector2(float(x), 420.0), Vector2(40.0, 60.0)), Color(0.16, 0.18, 0.17, 0.22), true)
		draw_rect(Rect2(Vector2(float(x) + 8.0, 430.0), Vector2(24.0, 40.0)), Color(0.08, 0.1, 0.1, 0.28), true)
	draw_circle(west_spawn_position, 26.0, Color(0.83, 0.26, 0.23, 0.85))
	draw_circle(west_spawn_position, 12.0, Color(0.25, 0.07, 0.06, 0.9))
	draw_arc(west_spawn_position, 40.0, 0.0, TAU, 28, Color(0.92, 0.56, 0.38, 0.4), 3.0)
