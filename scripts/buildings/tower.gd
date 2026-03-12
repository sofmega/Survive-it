extends Node2D

var building_def = null
var enemies_root: Node2D = null
var combat_system: Node = null
var attack_cooldown_remaining: float = 0.0


func setup(next_building_def, next_enemies_root: Node2D, next_combat_system: Node) -> void:
	building_def = next_building_def
	enemies_root = next_enemies_root
	combat_system = next_combat_system
	queue_redraw()


func _process(delta: float) -> void:
	if building_def == null:
		return

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

	if attack_cooldown_remaining <= 0.0:
		var enemy := _get_nearest_enemy(building_def.attack_range)
		if enemy != null:
			combat_system.apply_damage(self, enemy, building_def.attack_damage)
			attack_cooldown_remaining = building_def.attack_cooldown


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
	draw_rect(Rect2(Vector2(-18, -18), Vector2(36, 36)), Color(0.48, 0.41, 0.22), true)
	draw_circle(Vector2.ZERO, 6.0, Color(0.82, 0.77, 0.56))
