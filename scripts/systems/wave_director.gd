extends Node

signal wave_started(wave_number: int)
signal wave_finished(wave_number: int, reward_duration: float)
signal wave_progress_changed(active_enemies: int)
signal elite_spawned(alert_text: String)

const RUN_BALANCE = preload("res://data/balance/default_run_balance.tres")
const RUNNER_DEF = preload("res://data/enemies/runner_enemy.tres")
const BRUTE_DEF = preload("res://data/enemies/brute_enemy.tres")
const SIEGE_DEF = preload("res://data/enemies/siege_enemy.tres")
const CAPTAIN_DEF = preload("res://data/enemies/elite_siege_enemy.tres")

var spawn_director: Node = null
var economy_system: Node = null

var current_wave_number: int = 0
var current_wave_plan: Dictionary = {}
var active_enemies: int = 0
var spawning_finished: bool = false


func setup(next_spawn_director: Node, next_economy_system: Node) -> void:
	spawn_director = next_spawn_director
	economy_system = next_economy_system
	spawn_director.enemy_spawned.connect(_on_enemy_spawned)
	spawn_director.wave_spawn_completed.connect(_on_wave_spawn_completed)


func has_more_waves() -> bool:
	return current_wave_number < RUN_BALANCE.max_waves


func get_prep_duration() -> float:
	if not has_more_waves():
		return 0.0

	var next_wave_number: int = current_wave_number + 1
	return maxf(
		RUN_BALANCE.min_prep_duration,
		RUN_BALANCE.starting_prep_duration - float(next_wave_number - 1) * RUN_BALANCE.prep_duration_decay_per_wave
	)


func start_next_wave() -> void:
	if not has_more_waves():
		return

	current_wave_number += 1
	current_wave_plan = _build_wave_plan(current_wave_number)
	active_enemies = 0
	spawning_finished = false
	wave_progress_changed.emit(active_enemies)
	wave_started.emit(current_wave_number)
	spawn_director.start_wave(current_wave_plan)


func stop_wave_flow() -> void:
	current_wave_plan = {}
	spawning_finished = true
	if spawn_director != null and spawn_director.has_method("stop_spawning"):
		spawn_director.stop_spawning()


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
	if spawning_finished and active_enemies == 0 and not current_wave_plan.is_empty():
		var clear_reward := int(current_wave_plan.get("clear_gold_reward", 0))
		var reward_duration := float(current_wave_plan.get("post_wave_delay", RUN_BALANCE.post_wave_delay))
		current_wave_plan = {}
		economy_system.add_gold(clear_reward)
		wave_finished.emit(current_wave_number, reward_duration)


func get_current_wave_number() -> int:
	return current_wave_number


func get_next_wave_number() -> int:
	if not has_more_waves():
		return 0
	return current_wave_number + 1


func get_total_waves() -> int:
	return RUN_BALANCE.max_waves


func get_starting_gold() -> int:
	return RUN_BALANCE.starting_gold


func get_next_wave_preview_text() -> String:
	if not has_more_waves():
		return "No further waves scheduled"

	var next_wave_plan: Dictionary = _build_wave_plan(current_wave_number + 1)
	return String(next_wave_plan.get("description", "Unknown pressure"))


func _build_wave_plan(wave_number: int) -> Dictionary:
	var portal_ids: Array[StringName] = _get_portal_ids_for_wave(wave_number)
	var total_units: int = RUN_BALANCE.base_enemy_count + int(floor(float(wave_number - 1) * RUN_BALANCE.enemy_count_growth_per_wave))
	if wave_number % 10 == 0:
		total_units += RUN_BALANCE.extra_enemy_burst_every_ten

	var brute_count := 0
	if wave_number >= RUN_BALANCE.brute_start_wave:
		brute_count = 1 + int(floor(float(wave_number - RUN_BALANCE.brute_start_wave) / 4.0))

	var siege_count := 0
	if wave_number >= RUN_BALANCE.siege_start_wave:
		siege_count = 1 + int(floor(float(wave_number - RUN_BALANCE.siege_start_wave) / 6.0))

	var captain_count: int = 1 if wave_number % RUN_BALANCE.captain_wave_interval == 0 else 0
	var runner_count: int = max(total_units - brute_count - siege_count, 4)

	var health_multiplier := 1.0 + float(wave_number - 1) * RUN_BALANCE.enemy_health_scale_per_wave
	var damage_multiplier := 1.0 + float(wave_number - 1) * RUN_BALANCE.enemy_damage_scale_per_wave
	var speed_multiplier := minf(
		1.0 + float(wave_number - 1) * RUN_BALANCE.enemy_speed_scale_per_wave,
		RUN_BALANCE.max_enemy_speed_multiplier
	)
	var reward_bonus: int = int(floor(float(wave_number - 1) * 0.35))

	var spawn_entries: Array[Dictionary] = []
	_append_spawn_entries(
		spawn_entries,
		RUNNER_DEF,
		runner_count,
		portal_ids,
		0.0,
		maxf(0.22, 0.9 - float(wave_number) * 0.005),
		{
			"health_multiplier": health_multiplier,
			"damage_multiplier": damage_multiplier,
			"speed_multiplier": speed_multiplier,
			"reward_bonus": reward_bonus,
		}
	)

	if brute_count > 0:
		_append_spawn_entries(
			spawn_entries,
			BRUTE_DEF,
			brute_count,
			portal_ids,
			3.0,
			maxf(0.7, 1.8 - float(wave_number) * 0.006),
			{
				"health_multiplier": health_multiplier * 1.2,
				"damage_multiplier": damage_multiplier * 1.1,
				"speed_multiplier": minf(speed_multiplier * 0.92, RUN_BALANCE.max_enemy_speed_multiplier),
				"reward_bonus": reward_bonus + 2,
			}
		)

	if siege_count > 0:
		_append_spawn_entries(
			spawn_entries,
			SIEGE_DEF,
			siege_count,
			portal_ids,
			6.0,
			maxf(1.0, 2.6 - float(wave_number) * 0.005),
			{
				"health_multiplier": health_multiplier * 1.15,
				"damage_multiplier": damage_multiplier * 1.25,
				"speed_multiplier": minf(speed_multiplier * 0.84, RUN_BALANCE.max_enemy_speed_multiplier),
				"reward_bonus": reward_bonus + 4,
			}
		)

	if captain_count > 0:
		_append_spawn_entries(
			spawn_entries,
			CAPTAIN_DEF,
			captain_count,
			portal_ids,
			10.0,
			0.1,
			{
				"health_multiplier": health_multiplier * 1.45,
				"damage_multiplier": damage_multiplier * 1.35,
				"speed_multiplier": minf(speed_multiplier * 0.9, RUN_BALANCE.max_enemy_speed_multiplier),
				"reward_bonus": reward_bonus + 10,
			}
		)

	var description_parts: Array[String] = []
	description_parts.append("%d portals active" % portal_ids.size())
	description_parts.append("%d runners" % runner_count)
	if brute_count > 0:
		description_parts.append("%d brutes" % brute_count)
	if siege_count > 0:
		description_parts.append("%d siege beasts" % siege_count)
	if captain_count > 0:
		description_parts.append("captain portal surge")
	elif wave_number % RUN_BALANCE.elite_wave_interval == 0:
		description_parts.append("reinforced pressure")

	var clear_reward: int = RUN_BALANCE.clear_reward_base + int(floor(float(wave_number - 1) * RUN_BALANCE.clear_reward_growth_per_wave))
	if wave_number % RUN_BALANCE.elite_wave_interval == 0:
		clear_reward += RUN_BALANCE.bonus_reward_every_five

	return {
		"wave_number": wave_number,
		"display_name": "Wave %d" % wave_number,
		"description": ", ".join(description_parts),
		"post_wave_delay": RUN_BALANCE.post_wave_delay,
		"clear_gold_reward": clear_reward,
		"spawn_entries": spawn_entries,
	}


func _append_spawn_entries(
	spawn_entries: Array[Dictionary],
	enemy_def: Resource,
	total_count: int,
	portal_ids: Array[StringName],
	start_time: float,
	interval: float,
	stats: Dictionary
) -> void:
	if total_count <= 0 or portal_ids.is_empty():
		return

	var remaining := total_count
	for index in range(portal_ids.size()):
		var portals_left := portal_ids.size() - index
		var count_for_portal := int(ceil(float(remaining) / float(portals_left)))
		remaining -= count_for_portal
		spawn_entries.append({
			"enemy_def": enemy_def,
			"count": count_for_portal,
			"spawn_point_id": portal_ids[index],
			"start_time": start_time + float(index) * 0.7,
			"interval": interval,
			"stats": stats,
		})


func _get_portal_ids_for_wave(wave_number: int) -> Array[StringName]:
	var portal_ids: Array[StringName] = [&"left_center"]

	if wave_number >= RUN_BALANCE.second_portal_wave:
		portal_ids.append(&"top_center")
	if wave_number >= RUN_BALANCE.third_portal_wave:
		portal_ids.append(&"bottom_center")
	if wave_number >= RUN_BALANCE.fourth_portal_wave:
		portal_ids.append(&"right_center")

	return portal_ids
