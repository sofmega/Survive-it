extends Node2D

var building_def = null
var enemies_root: Node2D = null
var combat_system: Node = null
var fortress: Node2D = null
var structures_root: Node2D = null
var hero: Node2D = null
var attack_cooldown_remaining: float = 0.0
var current_health: float = 0.0
var damage_flash_time: float = 0.0
var heal_flash_time: float = 0.0
var attack_flash_time: float = 0.0


func setup(next_building_def, next_enemies_root: Node2D, next_combat_system: Node, next_fortress: Node2D, next_structures_root: Node2D, next_hero: Node2D) -> void:
	building_def = next_building_def
	enemies_root = next_enemies_root
	combat_system = next_combat_system
	fortress = next_fortress
	structures_root = next_structures_root
	hero = next_hero
	current_health = building_def.max_health
	queue_redraw()


func _process(delta: float) -> void:
	if building_def == null or current_health <= 0.0:
		return

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	heal_flash_time = maxf(heal_flash_time - delta, 0.0)
	attack_flash_time = maxf(attack_flash_time - delta, 0.0)

	if attack_cooldown_remaining > 0.0:
		return

	match String(building_def.role):
		"damage":
			var enemy: Node2D = _get_nearest_enemy(building_def.attack_range)
			if enemy != null:
				combat_system.apply_damage(self, enemy, _get_attack_damage())
				attack_cooldown_remaining = building_def.attack_cooldown
				attack_flash_time = 0.12
		"slow":
			var slowed_any := false
			for enemy in enemies_root.get_children():
				if global_position.distance_to(enemy.global_position) <= building_def.aura_radius and enemy.has_method("apply_slow"):
					enemy.apply_slow(building_def.utility_power, 1.2)
					slowed_any = true
			if slowed_any:
				attack_cooldown_remaining = building_def.attack_cooldown
				attack_flash_time = 0.12
		"repair":
			var repaired_any := false
			if fortress != null and global_position.distance_to(fortress.global_position) <= building_def.aura_radius:
				fortress.receive_heal(building_def.utility_power)
				repaired_any = true

			for structure in structures_root.get_children():
				if structure == self:
					continue
				if global_position.distance_to(structure.global_position) <= building_def.aura_radius and structure.has_method("receive_heal"):
					structure.receive_heal(building_def.utility_power)
					repaired_any = true

			if repaired_any:
				attack_cooldown_remaining = building_def.attack_cooldown
				attack_flash_time = 0.12
		"boost":
			var boosted_any: bool = false
			for structure in structures_root.get_children():
				if structure == self:
					continue
				if not structure.has_method("get_building_role"):
					continue
				if structure.get_building_role() == &"damage" and global_position.distance_to(structure.global_position) <= building_def.aura_radius:
					boosted_any = true
					break
			if boosted_any:
				attack_cooldown_remaining = building_def.attack_cooldown
				attack_flash_time = 0.12


func _get_nearest_enemy(max_range: float) -> Node2D:
	var nearest_enemy: Node2D = null
	var best_distance: float = max_range

	for enemy in enemies_root.get_children():
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest_enemy = enemy

	return nearest_enemy


func _get_attack_damage() -> float:
	var damage: float = building_def.attack_damage * fortress.get_tower_damage_multiplier()
	damage *= _get_boost_multiplier()
	if hero != null and hero.has_method("get_tower_damage_multiplier"):
		damage *= hero.get_tower_damage_multiplier(global_position)
	return damage


func _get_boost_multiplier() -> float:
	var multiplier: float = 1.0
	if structures_root == null or building_def == null:
		return multiplier

	for structure in structures_root.get_children():
		if structure == self:
			continue
		if not structure.has_method("get_building_role"):
			continue
		if structure.get_building_role() != &"boost":
			continue
		if global_position.distance_to(structure.global_position) <= structure.get_support_radius():
			multiplier *= 1.0 + structure.get_support_power()

	return multiplier


func get_building_role() -> StringName:
	if building_def == null:
		return &"unknown"
	return building_def.role


func get_support_radius() -> float:
	if building_def == null:
		return 0.0
	return building_def.aura_radius


func get_support_power() -> float:
	if building_def == null:
		return 0.0
	return building_def.utility_power


func receive_damage(amount: float, _source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	damage_flash_time = 0.16
	queue_redraw()

	if current_health <= 0.0:
		queue_free()


func receive_heal(amount: float) -> void:
	if amount <= 0.0 or building_def == null or current_health <= 0.0:
		return

	current_health = minf(current_health + amount, building_def.max_health)
	heal_flash_time = 0.16
	queue_redraw()


func _draw() -> void:
	var health_ratio: float = 0.0
	if building_def != null and building_def.max_health > 0.0:
		health_ratio = current_health / building_def.max_health

	var tint: Color = Color(0.48, 0.41, 0.22)
	var role: String = "damage"
	if building_def != null:
		tint = building_def.tint
		role = String(building_def.role)
	if damage_flash_time > 0.0:
		tint = tint.lightened(0.28)
	elif heal_flash_time > 0.0:
		tint = tint.lightened(0.18)

	draw_rect(Rect2(Vector2(-20, -20), Vector2(40, 40)), tint.darkened(0.25), true)
	draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), tint, true)
	if attack_flash_time > 0.0:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.64, 0.8), 3.0)
	match role:
		"damage":
			draw_circle(Vector2(0, -4), 6.0, Color(0.95, 0.92, 0.82))
			draw_line(Vector2(0, -4), Vector2(14, -18), Color(0.95, 0.95, 0.95), 3.0)
		"slow":
			draw_circle(Vector2.ZERO, 10.0, Color(0.74, 0.9, 1.0))
			draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.74, 0.9, 1.0, 0.75), 2.0)
		"repair":
			draw_rect(Rect2(Vector2(-5, -13), Vector2(10, 26)), Color(0.9, 0.96, 0.82), true)
			draw_rect(Rect2(Vector2(-13, -5), Vector2(26, 10)), Color(0.9, 0.96, 0.82), true)
		"boost":
			draw_circle(Vector2.ZERO, 9.0, Color(0.98, 0.78, 0.25))
			draw_polygon(PackedVector2Array([Vector2(0, -18), Vector2(7, -4), Vector2(18, -4), Vector2(9, 4), Vector2(13, 18), Vector2(0, 9), Vector2(-13, 18), Vector2(-9, 4), Vector2(-18, -4), Vector2(-7, -4)]), PackedColorArray([Color(0.98, 0.93, 0.68)]))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36, 6)), Color(0.12, 0.12, 0.12), true)
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36 * health_ratio, 6)), Color(0.38, 0.9, 0.47), true)
