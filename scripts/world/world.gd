extends Node2D

@onready var hero: Node2D = $Hero
@onready var wave_manager: Node = $WaveManager


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var grid_color := Color(0.18, 0.22, 0.2, 0.55)
	var width := 1600
	var height := 900
	var step := 64

	draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), Color(0.09, 0.12, 0.1), true)

	for x in range(0, width + step, step):
		draw_line(Vector2(x, 0), Vector2(x, height), grid_color, 1.0)

	for y in range(0, height + step, step):
		draw_line(Vector2(0, y), Vector2(width, y), grid_color, 1.0)


func get_status_text() -> String:
	var hero_text := "Hero at (%.0f, %.0f)" % [hero.position.x, hero.position.y]
	var wave_text := ""

	if wave_manager.has_method("get_wave_status"):
		wave_text = wave_manager.get_wave_status()

	return "%s | %s" % [hero_text, wave_text]

