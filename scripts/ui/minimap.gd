extends Control

signal focus_request(world_position: Vector2)

var fortress_node: Node2D
var hero_node: Node2D
var builder_node: Node2D
var enemies_root: Node2D
var structures_root: Node2D
var map_node: Node

@export var grid_lines: int = 3
@export var structure_color: Color = Color(0.95, 0.76, 0.28, 0.96)
@export var hero_color: Color = Color(0.26, 0.86, 0.67, 0.98)
@export var builder_color: Color = Color(0.25, 0.6, 1.0, 0.92)
@export var enemy_color: Color = Color(0.92, 0.28, 0.18, 0.92)
@export var lane_color: Color = Color(0.92, 0.47, 0.18, 0.35)
@export var fortress_color: Color = Color(0.5, 0.8, 1.0, 1.0)

func _ready() -> void:
	focus_mode = FOCUS_ALL
	set_process(true)

func setup(
	next_fortress: Node2D,
	next_hero: Node2D,
	next_builder: Node2D,
	next_enemies_root: Node2D,
	next_structures_root: Node2D,
	next_map_node: Node
) -> void:
	fortress_node = next_fortress
	hero_node = next_hero
	builder_node = next_builder
	enemies_root = next_enemies_root
	structures_root = next_structures_root
	map_node = next_map_node
	queue_redraw()
	focus_mode = FOCUS_ALL
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("focus_request", _minimap_to_world(event.position))

func _draw() -> void:
	var size: Vector2 = get_size()
	if size.x <= 0 or size.y <= 0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.08, 0.90), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.7, 0.78, 0.15), false, 2.0)

	var step_x := size.x / float(grid_lines + 1)
	var step_y := size.y / float(grid_lines + 1)
	for i in range(1, grid_lines + 1):
		draw_line(Vector2(step_x * i, 0.0), Vector2(step_x * i, size.y), Color(0.75, 0.85, 0.9, 0.2), 1.0)
		draw_line(Vector2(0.0, step_y * i), Vector2(size.x, step_y * i), Color(0.75, 0.85, 0.9, 0.2), 1.0)

	if map_node != null:
		_draw_walls()
		if map_node.has_method("get_spawn_portal_positions") and fortress_node != null:
			for portal_position in map_node.get_spawn_portal_positions().values():
				var start_point := _world_to_minimap(portal_position)
				var end_point := _world_to_minimap(fortress_node.global_position)
				draw_line(start_point, end_point, lane_color, 2.0)
				draw_circle(start_point, 5.0, enemy_color)

	_draw_build_zone(size)
	_draw_units_and_structures()

func _draw_build_zone(size: Vector2) -> void:
	if fortress_node == null:
		return
	var base_position := _world_to_minimap(fortress_node.global_position)
	var radius: float = 148.0
	if map_node != null:
		var node_radius_value: Variant = map_node.get("build_radius")
		if typeof(node_radius_value) == TYPE_FLOAT or typeof(node_radius_value) == TYPE_INT:
			radius = float(node_radius_value)
	var world_size := _get_world_size()
	var scale: float = min(size.x / world_size.x, size.y / world_size.y)
	var minimap_radius: float = radius * scale
	draw_circle(base_position, minimap_radius, Color(0.32, 0.55, 0.85, 0.18))
	draw_circle(base_position, minimap_radius * 0.6, Color(0.32, 0.55, 0.85, 0.20))
	draw_circle(base_position, minimap_radius * 0.25, Color(0.32, 0.55, 0.85, 0.35))
	draw_circle(base_position, minimap_radius * 0.1, fortress_color, true)

func _draw_units_and_structures() -> void:
	if hero_node != null:
		draw_circle(_world_to_minimap(hero_node.global_position), 4.5, hero_color)
	if builder_node != null:
		draw_circle(_world_to_minimap(builder_node.global_position), 4.5, builder_color)
	if structures_root != null:
		for structure in structures_root.get_children():
			if structure is Node2D:
				draw_circle(_world_to_minimap(structure.global_position), 3.5, structure_color)
	if enemies_root != null:
		for enemy in enemies_root.get_children():
			if enemy is Node2D:
				draw_circle(_world_to_minimap(enemy.global_position), 3.2, enemy_color)

func _world_to_minimap(world_position: Vector2) -> Vector2:
	var size: Vector2 = get_size()
	if size.x <= 0 or size.y <= 0:
		return Vector2.ZERO
	var world_size := _get_world_size()
	var normalized := Vector2(
		clamp(world_position.x / world_size.x, 0.0, 1.0),
		clamp(world_position.y / world_size.y, 0.0, 1.0)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)

func _minimap_to_world(local_position: Vector2) -> Vector2:
	var size: Vector2 = get_size()
	if size.x <= 0 or size.y <= 0:
		return Vector2.ZERO
	var world_size := _get_world_size()
	return Vector2(
		clamp(local_position.x / size.x, 0.0, 1.0) * world_size.x,
		clamp(local_position.y / size.y, 0.0, 1.0) * world_size.y
	)


func _get_world_size() -> Vector2:
	if map_node != null and map_node.has_method("get_world_size"):
		return map_node.get_world_size()
	return Vector2(1600.0, 900.0)


func _draw_walls() -> void:
	if map_node == null or not map_node.has_method("get_wall_rects"):
		return
	for wall_rect in map_node.get_wall_rects():
		var rect_position := _world_to_minimap(wall_rect.position)
		var rect_end := _world_to_minimap(wall_rect.end)
		draw_rect(Rect2(rect_position, rect_end - rect_position), Color(0.22, 0.26, 0.28, 0.95), true)
