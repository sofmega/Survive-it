extends Node2D

signal destroyed(unit: Node)

@export var hero_def: Resource

var is_selected: bool = false
var current_health: float = 0.0
var attack_cooldown_remaining: float = 0.0
var combat_system: Node = null
var enemies_root: Node2D = null
var map_view: Node = null
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false
var path_points: Array[Vector2] = []
var stalled_time: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var repath_cooldown_remaining: float = 0.0
var last_navigation_version: int = -1
var path_debug_dirty: bool = false


func setup(next_combat_system: Node, next_enemies_root: Node2D, next_map_view: Node) -> void:
	if hero_def == null:
		return

	combat_system = next_combat_system
	enemies_root = next_enemies_root
	map_view = next_map_view
	current_health = hero_def.max_health
	last_position = global_position
	last_navigation_version = _get_navigation_version()
	queue_redraw()


func set_selected(next_selected: bool) -> void:
	is_selected = next_selected
	queue_redraw()


func set_move_target(target_position: Vector2) -> void:
	move_target = target_position
	has_move_target = false
	path_points = _request_navigation_path(target_position)
	if path_points.is_empty():
		push_warning("Hero command rejected because no navigation path was found.")
		return
	has_move_target = true
	stalled_time = 0.0
	repath_cooldown_remaining = 0.2
	_refresh_path_visual()


func clear_move_target() -> void:
	has_move_target = false
	path_points.clear()
	stalled_time = 0.0
	_refresh_path_visual()


func has_active_move_target() -> bool:
	return has_move_target


func get_move_target() -> Vector2:
	return move_target


func receive_damage(amount: float, _source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()
	if current_health <= 0.0:
		destroyed.emit(self)
		queue_free()


func _process(delta: float) -> void:
	if hero_def == null or enemies_root == null or combat_system == null:
		return

	_follow_path(delta)
	repath_cooldown_remaining = maxf(repath_cooldown_remaining - delta, 0.0)
	var moved_distance: float = global_position.distance_to(last_position)
	if has_move_target and moved_distance <= 1.0:
		stalled_time += delta
	elif moved_distance > 1.0:
		stalled_time = 0.0
	last_position = global_position

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	if attack_cooldown_remaining <= 0.0:
		var enemy := _get_nearest_enemy(hero_def.attack_range)
		if enemy != null:
			combat_system.apply_damage(self, enemy, hero_def.attack_damage)
			attack_cooldown_remaining = hero_def.attack_cooldown


func _follow_path(delta: float) -> void:
	if not has_move_target:
		return

	if path_points.is_empty():
		has_move_target = false
		return

	if _should_repath():
		path_points = _request_navigation_path(move_target)
		stalled_time = 0.0
		repath_cooldown_remaining = 0.2
		if path_points.is_empty():
			has_move_target = false
			push_warning("Hero movement stopped because the route became unreachable.")
			_refresh_path_visual()
			return
		_refresh_path_visual()

	var next_point := path_points[0]
	var direction := next_point - global_position
	var step: float = hero_def.move_speed * delta
	if direction.length() <= 1.0:
		path_points.remove_at(0)
		_refresh_path_visual()
		if path_points.is_empty():
			has_move_target = false
		return
	var desired_position := next_point
	if direction.length() > step:
		desired_position = global_position + direction.normalized() * step

	if map_view != null and map_view.has_method("resolve_movement"):
		global_position = map_view.resolve_movement(global_position, desired_position, 20.0)
	else:
		global_position = desired_position

	if global_position.distance_to(next_point) <= 10.0:
		path_points.remove_at(0)
		_refresh_path_visual()

	if path_points.is_empty():
		has_move_target = false
		_refresh_path_visual()


func _get_nearest_enemy(max_range: float) -> Node2D:
	var nearest_enemy: Node2D = null
	var best_distance := max_range

	for enemy in enemies_root.get_children():
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest_enemy = enemy

	return nearest_enemy


func get_tower_damage_multiplier(world_position: Vector2) -> float:
	if hero_def == null:
		return 1.0

	if global_position.distance_to(world_position) <= hero_def.support_radius:
		return 1.0 + hero_def.tower_damage_bonus

	return 1.0


func _draw() -> void:
	var body_color := Color(0.2, 0.76, 0.47)
	var cape_color := Color(0.07, 0.18, 0.12)
	var selection_color := Color(0.92, 0.95, 0.32) if is_selected else Color(0.22, 0.25, 0.18)
	var health_ratio := 0.0
	if hero_def != null and hero_def.max_health > 0.0:
		health_ratio = current_health / hero_def.max_health
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 28, selection_color, 2.0)
	draw_polygon(PackedVector2Array([Vector2(-10, 14), Vector2(0, -18), Vector2(10, 14)]), PackedColorArray([body_color]))
	draw_rect(Rect2(Vector2(-6, 8), Vector2(12, 16)), cape_color, true)
	draw_circle(Vector2(0, -8), 9.0, Color(0.9, 0.87, 0.78))
	draw_line(Vector2(8, -2), Vector2(22, -14), Color(0.95, 0.95, 0.95), 3.0)
	draw_circle(Vector2(22, -14), 3.5, Color(0.82, 0.88, 0.95))
	if _should_draw_debug_path() and path_points.size() > 0:
		var debug_points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		for path_point in path_points:
			debug_points.append(to_local(path_point))
		draw_polyline(debug_points, Color(0.46, 0.96, 0.68, 0.9), 2.0)
	draw_rect(Rect2(Vector2(-24, -36), Vector2(48, 6)), Color(0.08, 0.08, 0.08), true)
	draw_rect(Rect2(Vector2(-24, -36), Vector2(48 * health_ratio, 6)), Color(0.34, 0.88, 0.45), true)


func _request_navigation_path(target_position: Vector2) -> Array[Vector2]:
	if map_view != null and map_view.has_method("get_navigation_path"):
		last_navigation_version = _get_navigation_version()
		return map_view.get_navigation_path(global_position, target_position, 20.0)

	var direct_path: Array[Vector2] = []
	direct_path.append(target_position)
	return direct_path


func _should_repath() -> bool:
	if repath_cooldown_remaining > 0.0:
		return false
	if stalled_time >= 0.35:
		return true
	return _get_navigation_version() != last_navigation_version


func _get_navigation_version() -> int:
	if map_view != null and map_view.has_method("get_navigation_version"):
		return map_view.get_navigation_version()
	return -1


func _should_draw_debug_path() -> bool:
	if map_view != null and map_view.has_method("should_draw_navigation_debug"):
		return map_view.should_draw_navigation_debug()
	return false


func _refresh_path_visual() -> void:
	if _should_draw_debug_path():
		queue_redraw()
