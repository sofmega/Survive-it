extends Node2D

signal died(enemy: Node, killer: Node)

var enemy_def = null
var structures_root: Node2D = null
var combat_system: Node = null
var hero: Node2D = null
var builder: Node2D = null
var map_view: Node = null
var search_route: Array[Vector2] = []

var current_health: float = 0.0
var max_health: float = 0.0
var move_speed: float = 0.0
var contact_damage: float = 0.0
var attack_range: float = 0.0
var attack_cooldown: float = 0.0
var special_attack_damage: float = 0.0
var special_attack_radius: float = 0.0
var special_attack_cooldown: float = 0.0
var gold_reward: int = 0
var preferred_target: StringName = &"survivors"
var attack_cooldown_remaining: float = 0.0
var special_attack_cooldown_remaining: float = 0.0
var slow_multiplier: float = 1.0
var slow_time_remaining: float = 0.0
var damage_flash_time: float = 0.0
var pulse_flash_time: float = 0.0
var current_target: Node2D = null
var last_known_target_position: Vector2 = Vector2.ZERO
var path_points: Array[Vector2] = []
var search_index: int = 0
var detection_radius: float = 300.0


func setup(next_enemy_def, next_structures_root: Node2D, next_combat_system: Node, next_hero: Node2D, next_builder: Node2D, next_map_view: Node, next_search_route: Array[Vector2], spawn_entry: Dictionary = {}) -> void:
	enemy_def = next_enemy_def
	structures_root = next_structures_root
	combat_system = next_combat_system
	hero = next_hero
	builder = next_builder
	map_view = next_map_view
	search_route = next_search_route.duplicate()

	var stats: Dictionary = spawn_entry.get("stats", {})
	max_health = enemy_def.max_health * float(stats.get("health_multiplier", 1.0))
	move_speed = enemy_def.move_speed * float(stats.get("speed_multiplier", 1.0))
	contact_damage = enemy_def.contact_damage * float(stats.get("damage_multiplier", 1.0))
	attack_range = enemy_def.attack_range
	attack_cooldown = enemy_def.attack_cooldown
	special_attack_damage = enemy_def.special_attack_damage * float(stats.get("damage_multiplier", 1.0))
	special_attack_radius = enemy_def.special_attack_radius
	special_attack_cooldown = enemy_def.special_attack_cooldown
	gold_reward = enemy_def.gold_reward + int(stats.get("reward_bonus", 0))
	preferred_target = enemy_def.preferred_target
	current_health = max_health

	if attack_range > 0.0:
		detection_radius = maxf(320.0, attack_range * 7.5)

	queue_redraw()


func _process(delta: float) -> void:
	if current_health <= 0.0 or enemy_def == null:
		return

	slow_time_remaining = maxf(slow_time_remaining - delta, 0.0)
	if slow_time_remaining <= 0.0:
		slow_multiplier = 1.0

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	special_attack_cooldown_remaining = maxf(special_attack_cooldown_remaining - delta, 0.0)
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)

	if not _is_target_alive(current_target):
		current_target = null

	if current_target == null:
		current_target = _choose_target()

	if current_target == null:
		_search(delta)
	else:
		_engage_target(delta, current_target)


func receive_damage(amount: float, source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	damage_flash_time = 0.14
	queue_redraw()

	if source is Node2D:
		current_target = source
		last_known_target_position = source.global_position

	if current_health <= 0.0:
		died.emit(self, source)
		queue_free()


func get_gold_reward() -> int:
	return gold_reward


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = clampf(multiplier, 0.2, 1.0)
	slow_time_remaining = maxf(slow_time_remaining, duration)


func _choose_target() -> Node2D:
	var nearest_survivor := _get_nearest_survival_target()
	if nearest_survivor != null:
		last_known_target_position = nearest_survivor.global_position
		var blocking_target := _get_blocking_structure(nearest_survivor)
		if blocking_target != null:
			return blocking_target

		var nearby_structure := _get_nearest_structure(140.0)
		if preferred_target == &"structures" and nearby_structure != null:
			return nearby_structure

		return nearest_survivor

	var structure_target := _get_nearest_structure(detection_radius)
	if structure_target != null:
		last_known_target_position = structure_target.global_position
		return structure_target

	return null


func _get_nearest_survival_target() -> Node2D:
	var nearest_target: Node2D = null
	var best_distance := INF
	for candidate in [hero, builder]:
		if not _is_target_alive(candidate):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest_target = candidate
	return nearest_target


func _get_nearest_structure(max_range: float) -> Node2D:
	if structures_root == null:
		return null

	var nearest_target: Node2D = null
	var best_distance := max_range
	for structure in structures_root.get_children():
		if not _is_target_alive(structure):
			continue
		var distance := global_position.distance_to(structure.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest_target = structure
	return nearest_target


func _get_blocking_structure(final_target: Node2D) -> Node2D:
	if structures_root == null or map_view == null:
		return null

	for structure in structures_root.get_children():
		if not (structure is Node2D):
			continue
		if structure == final_target:
			continue
		if map_view.is_structure_blocking_path(structure, global_position, final_target.global_position):
			return structure

	return null


func _search(delta: float) -> void:
	if last_known_target_position != Vector2.ZERO and global_position.distance_to(last_known_target_position) > 28.0:
		_move_toward_position(delta, last_known_target_position)
		return

	if search_route.is_empty():
		if map_view != null and map_view.has_method("get_safe_zone_center"):
			_move_toward_position(delta, map_view.get_safe_zone_center())
		return

	var search_target := search_route[search_index]
	_move_toward_position(delta, search_target)
	if global_position.distance_to(search_target) <= 22.0:
		search_index = (search_index + 1) % search_route.size()


func _engage_target(delta: float, target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	last_known_target_position = target.global_position
	var distance: float = global_position.distance_to(target.global_position)

	if distance > attack_range:
		_move_toward_position(delta, target.global_position)
		return

	if special_attack_damage > 0.0 and special_attack_radius > 0.0 and special_attack_cooldown_remaining <= 0.0:
		_perform_special_attack()
		special_attack_cooldown_remaining = special_attack_cooldown
		attack_cooldown_remaining = maxf(attack_cooldown_remaining, 0.5)
	elif attack_cooldown_remaining <= 0.0:
		combat_system.apply_damage(self, target, contact_damage)
		attack_cooldown_remaining = attack_cooldown


func _move_toward_position(delta: float, target_position: Vector2) -> void:
	if map_view != null and map_view.has_method("get_navigation_path"):
		if path_points.is_empty() or path_points[path_points.size() - 1].distance_to(target_position) > 20.0:
			path_points = map_view.get_navigation_path(global_position, target_position, enemy_def.radius)

	if path_points.is_empty():
		path_points.append(target_position)

	var next_point := path_points[0]
	var direction := next_point - global_position
	var distance := direction.length()
	var desired_position := next_point
	if distance > move_speed * slow_multiplier * delta:
		desired_position = global_position + direction.normalized() * move_speed * slow_multiplier * delta

	if map_view != null and map_view.has_method("resolve_movement"):
		global_position = map_view.resolve_movement(global_position, desired_position, enemy_def.radius)
	else:
		global_position = desired_position

	if global_position.distance_to(next_point) <= 12.0:
		path_points.remove_at(0)


func _perform_special_attack() -> void:
	if combat_system == null:
		return

	var hit_any: bool = false
	for target in _get_damage_targets():
		if global_position.distance_to(target.global_position) <= special_attack_radius:
			combat_system.apply_damage(self, target, special_attack_damage)
			hit_any = true

	if hit_any:
		pulse_flash_time = 0.35
		queue_redraw()


func _get_damage_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	for candidate in [hero, builder]:
		if _is_target_alive(candidate):
			targets.append(candidate)
	if structures_root != null:
		for structure in structures_root.get_children():
			if _is_target_alive(structure):
				targets.append(structure)
	return targets


func _is_target_alive(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var candidate_health: Variant = target.get("current_health")
	if candidate_health != null:
		return float(candidate_health) > 0.0
	return true


func _draw() -> void:
	var health_ratio: float = 0.0
	if max_health > 0.0:
		health_ratio = current_health / max_health
	var radius: float = 16.0
	var tint: Color = Color(0.83, 0.29, 0.27)
	var accent: Color = Color(0.22, 0.08, 0.06)
	if enemy_def != null:
		radius = enemy_def.radius
		tint = enemy_def.tint
		if enemy_def.preferred_target == &"structures":
			accent = Color(0.2, 0.1, 0.02)
		if enemy_def.is_elite:
			accent = Color(0.28, 0.07, 0.07)
	if damage_flash_time > 0.0:
		tint = tint.lightened(0.35)
	if pulse_flash_time > 0.0:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 28, Color(1.0, 0.74, 0.22, 0.85), 4.0)
	draw_circle(Vector2.ZERO, radius, tint)
	draw_circle(Vector2.ZERO, radius * 0.55, accent)
	draw_line(Vector2(-radius * 0.5, -radius * 0.2), Vector2(radius * 0.5, radius * 0.2), Color(0.95, 0.88, 0.7), 2.0)
	if enemy_def != null and enemy_def.is_elite:
		draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 24, Color(0.98, 0.8, 0.22), 2.0)
		draw_circle(Vector2(-radius * 0.4, -radius * 0.55), 4.0, Color(0.98, 0.8, 0.22))
		draw_circle(Vector2(radius * 0.4, -radius * 0.55), 4.0, Color(0.98, 0.8, 0.22))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36, 6)), Color(0.12, 0.12, 0.12), true)
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36 * health_ratio, 6)), Color(0.9, 0.3, 0.27), true)
