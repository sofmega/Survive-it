extends Node2D

signal damaged(current_health: float, max_health: float)
signal destroyed

@export var tier_def: Resource

var current_health: float = 0.0
var max_health: float = 0.0


func _ready() -> void:
	if tier_def != null:
		max_health = tier_def.max_health
		current_health = max_health

	damaged.emit(current_health, max_health)
	queue_redraw()


func receive_damage(amount: float, _source: Node) -> void:
	if current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(current_health, max_health)
	queue_redraw()

	if current_health <= 0.0:
		destroyed.emit()


func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0

	return current_health / max_health


func _draw() -> void:
	var ring_color := Color(0.84, 0.66, 0.24)
	var core_color := Color(0.17, 0.24, 0.34)
	var health_color := Color(0.33, 0.86, 0.45)
	var health_ratio := get_health_ratio()

	draw_circle(Vector2.ZERO, 44.0, ring_color)
	draw_circle(Vector2.ZERO, 32.0, core_color)
	draw_rect(Rect2(Vector2(-48, -64), Vector2(96, 10)), Color(0.1, 0.1, 0.1), true)
	draw_rect(Rect2(Vector2(-48, -64), Vector2(96 * health_ratio, 10)), health_color, true)
