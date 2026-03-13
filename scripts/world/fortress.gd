extends Node2D

signal damaged(current_health: float, max_health: float)
signal destroyed

@export var tier_def: Resource

var current_health: float = 0.0
var max_health: float = 0.0
var damage_flash_time: float = 0.0
var heal_flash_time: float = 0.0
var upgrade_flash_time: float = 0.0


func _process(delta: float) -> void:
	damage_flash_time = maxf(damage_flash_time - delta, 0.0)
	heal_flash_time = maxf(heal_flash_time - delta, 0.0)
	upgrade_flash_time = maxf(upgrade_flash_time - delta, 0.0)
	if damage_flash_time > 0.0 or heal_flash_time > 0.0 or upgrade_flash_time > 0.0:
		queue_redraw()


func _ready() -> void:
	if tier_def != null:
		_apply_tier_def(tier_def, true)
	damaged.emit(current_health, max_health)
	queue_redraw()


func receive_damage(amount: float, _source: Node) -> void:
	if current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	damage_flash_time = 0.18
	damaged.emit(current_health, max_health)
	queue_redraw()

	if current_health <= 0.0:
		destroyed.emit()


func receive_heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = minf(current_health + amount, max_health)
	heal_flash_time = 0.2
	damaged.emit(current_health, max_health)
	queue_redraw()


func set_tier_def(next_tier_def: Resource, preserve_ratio: bool = true) -> void:
	tier_def = next_tier_def
	_apply_tier_def(next_tier_def, preserve_ratio)
	upgrade_flash_time = 0.55
	damaged.emit(current_health, max_health)
	queue_redraw()


func get_tier_index() -> int:
	if tier_def == null:
		return 0

	return tier_def.tier_index


func get_upgrade_cost() -> int:
	if tier_def == null:
		return 0

	return tier_def.upgrade_cost


func get_repair_cost() -> int:
	if tier_def == null:
		return 0

	return tier_def.repair_cost


func get_repair_amount() -> float:
	if tier_def == null:
		return 0.0

	return tier_def.repair_amount


func get_tower_damage_multiplier() -> float:
	if tier_def == null:
		return 1.0

	return 1.0 + tier_def.tower_damage_bonus


func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0

	return current_health / max_health


func _draw() -> void:
	var tier := get_tier_index()
	var ring_color := Color(0.84, 0.66, 0.24) if tier <= 1 else Color(0.42, 0.78, 0.92)
	var core_color := Color(0.17, 0.24, 0.34) if tier <= 1 else Color(0.12, 0.2, 0.26)
	var health_color := Color(0.33, 0.86, 0.45)
	var health_ratio: float = get_health_ratio()
	if damage_flash_time > 0.0:
		ring_color = ring_color.lightened(0.25)
		core_color = core_color.lightened(0.18)
	elif heal_flash_time > 0.0:
		health_color = Color(0.62, 0.96, 0.58)

	draw_circle(Vector2.ZERO, 48.0, Color(0.08, 0.08, 0.08, 0.35))
	if upgrade_flash_time > 0.0:
		draw_arc(Vector2.ZERO, 56.0, 0.0, TAU, 32, Color(0.98, 0.88, 0.42, 0.9), 4.0)
	draw_circle(Vector2.ZERO, 44.0, ring_color)
	draw_circle(Vector2.ZERO, 34.0, core_color)
	draw_rect(Rect2(Vector2(-12, -16), Vector2(24, 44)), Color(0.86, 0.84, 0.74), true)
	draw_rect(Rect2(Vector2(-26, 2), Vector2(52, 16)), Color(0.22, 0.24, 0.26), true)
	draw_rect(Rect2(Vector2(-8, -34), Vector2(16, 18)), ring_color.darkened(0.15), true)
	draw_circle(Vector2(0, -38), 8.0, ring_color.lightened(0.15))
	if tier >= 2:
		draw_rect(Rect2(Vector2(-34, -8), Vector2(12, 26)), Color(0.7, 0.78, 0.84), true)
		draw_rect(Rect2(Vector2(22, -8), Vector2(12, 26)), Color(0.7, 0.78, 0.84), true)
		draw_circle(Vector2(-28, -12), 7.0, ring_color)
		draw_circle(Vector2(28, -12), 7.0, ring_color)
	draw_rect(Rect2(Vector2(-48, -64), Vector2(96, 10)), Color(0.1, 0.1, 0.1), true)
	draw_rect(Rect2(Vector2(-48, -64), Vector2(96 * health_ratio, 10)), health_color, true)


func _apply_tier_def(next_tier_def: Resource, preserve_ratio: bool) -> void:
	var previous_ratio := 1.0
	if max_health > 0.0:
		previous_ratio = current_health / max_health

	max_health = next_tier_def.max_health
	if preserve_ratio:
		current_health = maxf(max_health * previous_ratio, 1.0)
	else:
		current_health = max_health
