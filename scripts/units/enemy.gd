extends Node2D

signal died(enemy: Node, killer: Node)

var enemy_def = null
var fortress: Node2D = null
var structures_root: Node2D = null
var combat_system: Node = null
var current_health: float = 0.0
var attack_cooldown_remaining: float = 0.0
var special_attack_cooldown_remaining: float = 0.0
var slow_multiplier: float = 1.0
var slow_time_remaining: float = 0.0
var damage_flash_time: float = 0.0
var pulse_flash_time: float = 0.0


func setup(next_enemy_def, next_fortress: Node2D, next_structures_root: Node2D, next_combat_system: Node) -> void:
	enemy_def = next_enemy_def
	fortress = next_fortress
	structures_root = next_structures_root
	combat_system = next_combat_system
	current_health = enemy_def.max_health
	special_attack_cooldown_remaining = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if fortress == null or current_health <= 0.0 or enemy_def == null:
		return

	slow_time_remaining = maxf(slow_time_remaining - delta, 0.0)
	if slow_time_remaining <= 0.0:
		slow_multiplier = 1.0

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	special_attack_cooldown_remaining = maxf(special_attack_cooldown_remaining - delta, 0.0)
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)
	var target: Node2D = _get_current_target()
	if target == null:
		target = fortress

	var direction: Vector2 = target.global_position - global_position
	var distance: float = direction.length()

	if distance > enemy_def.attack_range:
		global_position += direction.normalized() * enemy_def.move_speed * slow_multiplier * delta
	else:
		if enemy_def.special_attack_damage > 0.0 and enemy_def.special_attack_radius > 0.0 and special_attack_cooldown_remaining <= 0.0:
			_perform_special_attack()
			special_attack_cooldown_remaining = enemy_def.special_attack_cooldown
			attack_cooldown_remaining = maxf(attack_cooldown_remaining, 0.5)
		elif attack_cooldown_remaining <= 0.0:
			combat_system.apply_damage(self, target, enemy_def.contact_damage)
			attack_cooldown_remaining = enemy_def.attack_cooldown


func receive_damage(amount: float, source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	damage_flash_time = 0.14
	queue_redraw()

	if current_health <= 0.0:
		died.emit(self, source)
		queue_free()


func get_gold_reward() -> int:
	if enemy_def == null:
		return 0

	return enemy_def.gold_reward


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = clampf(multiplier, 0.2, 1.0)
	slow_time_remaining = maxf(slow_time_remaining, duration)


func _perform_special_attack() -> void:
	if fortress == null or combat_system == null or enemy_def == null:
		return

	var hit_any: bool = false
	if global_position.distance_to(fortress.global_position) <= enemy_def.special_attack_radius:
		combat_system.apply_damage(self, fortress, enemy_def.special_attack_damage)
		hit_any = true

	if structures_root != null:
		for structure in structures_root.get_children():
			if not structure.has_method("receive_damage"):
				continue
			if global_position.distance_to(structure.global_position) <= enemy_def.special_attack_radius:
				combat_system.apply_damage(self, structure, enemy_def.special_attack_damage)
				hit_any = true

	if hit_any:
		pulse_flash_time = 0.35
		queue_redraw()


func _get_current_target() -> Node2D:
	if enemy_def.preferred_target != &"structures" or structures_root == null:
		return fortress

	var nearest_structure: Node2D = null
	var best_distance: float = INF

	for structure in structures_root.get_children():
		if not structure.has_method("receive_damage"):
			continue

		var distance: float = global_position.distance_to(structure.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest_structure = structure

	if nearest_structure != null:
		return nearest_structure

	return fortress


func _draw() -> void:
	var health_ratio: float = 0.0
	if enemy_def != null and enemy_def.max_health > 0.0:
		health_ratio = current_health / enemy_def.max_health
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
	if enemy_def != null and enemy_def.preferred_target == &"structures":
		draw_rect(Rect2(Vector2(-radius * 0.5, -radius - 6), Vector2(radius, 6)), Color(0.98, 0.72, 0.18), true)
	if enemy_def != null and enemy_def.is_elite:
		draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 24, Color(0.98, 0.8, 0.22), 2.0)
		draw_circle(Vector2(-radius * 0.4, -radius * 0.55), 4.0, Color(0.98, 0.8, 0.22))
		draw_circle(Vector2(radius * 0.4, -radius * 0.55), 4.0, Color(0.98, 0.8, 0.22))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36, 6)), Color(0.12, 0.12, 0.12), true)
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36 * health_ratio, 6)), Color(0.9, 0.3, 0.27), true)
