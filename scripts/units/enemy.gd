extends Node2D

signal died(enemy: Node, killer: Node)

var enemy_def = null
var fortress: Node2D = null
var combat_system: Node = null
var current_health: float = 0.0
var attack_cooldown_remaining: float = 0.0


func setup(next_enemy_def, next_fortress: Node2D, next_combat_system: Node) -> void:
	enemy_def = next_enemy_def
	fortress = next_fortress
	combat_system = next_combat_system
	current_health = enemy_def.max_health
	queue_redraw()


func _process(delta: float) -> void:
	if fortress == null or current_health <= 0.0:
		return

	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	var direction := fortress.global_position - global_position
	var distance := direction.length()

	if distance > enemy_def.attack_range:
		global_position += direction.normalized() * enemy_def.move_speed * delta
	else:
		if attack_cooldown_remaining <= 0.0:
			combat_system.apply_damage(self, fortress, enemy_def.contact_damage)
			attack_cooldown_remaining = enemy_def.attack_cooldown


func receive_damage(amount: float, source: Node) -> void:
	current_health = maxf(current_health - amount, 0.0)
	queue_redraw()

	if current_health <= 0.0:
		died.emit(self, source)
		queue_free()


func get_gold_reward() -> int:
	if enemy_def == null:
		return 0

	return enemy_def.gold_reward


func _draw() -> void:
	var health_ratio: float = 0.0
	if enemy_def != null and enemy_def.max_health > 0.0:
		health_ratio = current_health / enemy_def.max_health
	draw_circle(Vector2.ZERO, 16.0, Color(0.83, 0.29, 0.27))
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36, 6)), Color(0.12, 0.12, 0.12), true)
	draw_rect(Rect2(Vector2(-18, -28), Vector2(36 * health_ratio, 6)), Color(0.9, 0.3, 0.27), true)
