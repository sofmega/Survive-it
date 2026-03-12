extends Node

const WAVE_INTERVAL := 12.0

var elapsed := 0.0
var current_wave := 1


func _process(delta: float) -> void:
	elapsed += delta

	if elapsed >= WAVE_INTERVAL:
		elapsed = 0.0
		current_wave += 1


func get_wave_status() -> String:
	var remaining := max(WAVE_INTERVAL - elapsed, 0.0)
	return "Wave %d | next in %.1fs" % [current_wave, remaining]
