extends Control

signal focus_request(world_position: Vector2)

const MAP_SCRIPT := preload("res://scripts/world/map_view.gd")
const WORLD_SIZE: Vector2 = MAP_SCRIPT.WORLD_SIZE

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
		var spawn_pos_value: Variant = map_node.get("west_spawn_position")
		if spawn_pos_value is Vector2 and fortress_node != null:
			var spawn_pos: Vector2 = spawn_pos_value
			var start_point := _world_to_minimap(spawn_pos)
			var end_point := _world_to_minimap(fortress_node.global_position)
			draw_line(start_point, end_point, lane_color, 3.0)

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
	var scale: float = min(size.x / WORLD_SIZE.x, size.y / WORLD_SIZE.y)
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
	var normalized := Vector2(
		clamp(world_position.x / WORLD_SIZE.x, 0.0, 1.0),
		clamp(world_position.y / WORLD_SIZE.y, 0.0, 1.0)
	)
	return Vector2(normalized.x * size.x, normalized.y * size.y)

func _minimap_to_world(local_position: Vector2) -> Vector2:
	var size: Vector2 = get_size()
	if size.x <= 0 or size.y <= 0:
		return Vector2.ZERO
	return Vector2(
		clamp(local_position.x / size.x, 0.0, 1.0) * WORLD_SIZE.x,
		clamp(local_position.y / size.y, 0.0, 1.0) * WORLD_SIZE.y
	)
