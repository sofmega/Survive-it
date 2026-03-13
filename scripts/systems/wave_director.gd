extends Node

signal wave_started(wave_number: int)
signal wave_finished(wave_number: int, reward_duration: float)
signal wave_progress_changed(active_enemies: int)
signal elite_spawned(alert_text: String)

const WAVES = [
	preload("res://data/waves/wave_01_basic.tres"),
	preload("res://data/waves/wave_02_pressure.tres"),
	preload("res://data/waves/wave_03_siege.tres"),
]

var spawn_director: Node = null
var economy_system: Node = null

var current_wave_index: int = -1
var current_wave = null
var active_enemies: int = 0
var spawning_finished: bool = false


func setup(next_spawn_director: Node, next_economy_system: Node) -> void:
	spawn_director = next_spawn_director
	economy_system = next_economy_system
	spawn_director.enemy_spawned.connect(_on_enemy_spawned)
	spawn_director.wave_spawn_completed.connect(_on_wave_spawn_completed)


func has_more_waves() -> bool:
	return current_wave_index + 1 < WAVES.size()


func get_prep_duration() -> float:
	if has_more_waves():
		return WAVES[current_wave_index + 1].prep_time_before_wave

	return 0.0


func start_next_wave() -> void:
	if not has_more_waves():
		return

	current_wave_index += 1
	current_wave = WAVES[current_wave_index]
	active_enemies = 0
	spawning_finished = false
	wave_progress_changed.emit(active_enemies)
	wave_started.emit(current_wave.wave_number)
	spawn_director.start_wave(current_wave)


func _on_enemy_spawned(enemy: Node) -> void:
	active_enemies += 1
	wave_progress_changed.emit(active_enemies)

	var spawned_def = enemy.get("enemy_def")
	if spawned_def != null and spawned_def.is_elite:
		var alert_text: String = spawned_def.alert_text
		if alert_text.is_empty():
			alert_text = "%s has entered the battlefield" % spawned_def.display_name
		elite_spawned.emit(alert_text)

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Node, _killer: Node) -> void:
	active_enemies = maxi(active_enemies - 1, 0)
	wave_progress_changed.emit(active_enemies)

	if enemy.has_method("get_gold_reward"):
		economy_system.add_gold(enemy.get_gold_reward())

	_check_wave_completion()


func _on_wave_spawn_completed() -> void:
	spawning_finished = true
	_check_wave_completion()


func _check_wave_completion() -> void:
	if spawning_finished and active_enemies == 0 and current_wave != null:
		economy_system.add_gold(current_wave.clear_gold_reward)
		wave_finished.emit(current_wave.wave_number, current_wave.post_wave_delay)


func get_current_wave_number() -> int:
	if current_wave == null:
		return 0

	return current_wave.wave_number


func get_next_wave_number() -> int:
	if has_more_waves():
		return WAVES[current_wave_index + 1].wave_number

	return 0


func get_next_wave_preview_text() -> String:
	if has_more_waves():
		var next_wave = WAVES[current_wave_index + 1]
		return "%s: %s" % [next_wave.display_name, next_wave.description]

	return "No further waves scheduled"
