extends Node2D

@export var hero_def: Resource

var is_controlled: bool = true
var current_health: float = 0.0
var attack_cooldown_remaining: float = 0.0
var combat_system: Node = null
var enemies_root: Node2D = null


func setup(next_combat_system: Node, next_enemies_root: Node2D) -> void:
	if hero_def == null:
		return

	combat_system = next_combat_system
	enemies_root = next_enemies_root
	current_health = hero_def.max_health
	queue_redraw()


func set_controlled(next_controlled: bool) -> void:
	is_controlled = next_controlled
	queue_redraw()


func _process(delta: float) -> void:
	if hero_def == null or enemies_root == null or combat_system == null:
		return

	if is_controlled:
		var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		position += input_vector * hero_def.move_speed * delta
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


func _draw() -> void:
	var body_color := Color(0.22, 0.78, 0.48)
	var selection_color := Color(0.92, 0.95, 0.32) if is_controlled else Color(0.22, 0.25, 0.18)
	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_circle(Vector2.ZERO, 9.0, Color(0.08, 0.15, 0.12))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, selection_color, 2.0)
