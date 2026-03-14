extends Node2D

@export var hero_def: Resource

var is_selected: bool = false
var current_health: float = 0.0
var attack_cooldown_remaining: float = 0.0
var combat_system: Node = null
var enemies_root: Node2D = null
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false


func setup(next_combat_system: Node, next_enemies_root: Node2D) -> void:
	if hero_def == null:
		return

	combat_system = next_combat_system
	enemies_root = next_enemies_root
	current_health = hero_def.max_health
	queue_redraw()


func set_selected(next_selected: bool) -> void:
	is_selected = next_selected
	queue_redraw()


func set_move_target(target_position: Vector2) -> void:
	move_target = target_position
	has_move_target = true


func clear_move_target() -> void:
	has_move_target = false


func has_active_move_target() -> bool:
	return has_move_target


func get_move_target() -> Vector2:
	return move_target


func _process(delta: float) -> void:
	if hero_def == null or enemies_root == null or combat_system == null:
		return

	if has_move_target:
		var direction := move_target - global_position
		if direction.length() <= hero_def.move_speed * delta:
			global_position = move_target
			has_move_target = false
		else:
			global_position += direction.normalized() * hero_def.move_speed * delta

		position.x = clamp(position.x, 64.0, 1536.0)
		position.y = clamp(position.y, 64.0, 836.0)

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

	if attack_cooldown_remaining <= 0.0:
		var enemy := _get_nearest_enemy(hero_def.attack_range)
		if enemy != null:
			combat_system.apply_damage(self, enemy, hero_def.attack_damage)
			attack_cooldown_remaining = hero_def.attack_cooldown

	queue_redraw()


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
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 28, selection_color, 2.0)
	draw_polygon(PackedVector2Array([Vector2(-10, 14), Vector2(0, -18), Vector2(10, 14)]), PackedColorArray([body_color]))
	draw_rect(Rect2(Vector2(-6, 8), Vector2(12, 16)), cape_color, true)
	draw_circle(Vector2(0, -8), 9.0, Color(0.9, 0.87, 0.78))
	draw_line(Vector2(8, -2), Vector2(22, -14), Color(0.95, 0.95, 0.95), 3.0)
	draw_circle(Vector2(22, -14), 3.5, Color(0.82, 0.88, 0.95))
