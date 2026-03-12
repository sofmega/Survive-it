extends Node

signal phase_changed(new_phase: StringName)
signal timer_changed(time_remaining: float)
signal run_lost(reason: String)
signal run_won

const SETUP: StringName = &"setup"
const BUILD_PHASE: StringName = &"build_phase"
const COMBAT_PHASE: StringName = &"combat_phase"
const REWARD_PHASE: StringName = &"reward_phase"
const GAME_OVER: StringName = &"game_over"
const VICTORY: StringName = &"victory"

var current_phase: StringName = SETUP
var phase_time_remaining: float = 0.0

var wave_director: Node = null


func setup(next_wave_director: Node) -> void:
	wave_director = next_wave_director

	if wave_director != null:
		wave_director.wave_finished.connect(_on_wave_finished)

	enter_build_phase(wave_director.get_prep_duration())


func _process(delta: float) -> void:
	if current_phase in [GAME_OVER, VICTORY]:
		return

	if current_phase in [BUILD_PHASE, REWARD_PHASE]:
		phase_time_remaining = maxf(phase_time_remaining - delta, 0.0)
		timer_changed.emit(phase_time_remaining)

		if phase_time_remaining <= 0.0:
			if current_phase == BUILD_PHASE:
				start_combat_phase()
			elif current_phase == REWARD_PHASE:
				if wave_director.has_more_waves():
					enter_build_phase(wave_director.get_prep_duration())
				else:
					enter_victory()


func enter_build_phase(duration: float) -> void:
	current_phase = BUILD_PHASE
	phase_time_remaining = duration
	phase_changed.emit(current_phase)
	timer_changed.emit(phase_time_remaining)


func start_combat_phase() -> void:
	current_phase = COMBAT_PHASE
	phase_time_remaining = 0.0
	phase_changed.emit(current_phase)
	timer_changed.emit(phase_time_remaining)

	if wave_director != null:
		wave_director.start_next_wave()


func enter_reward_phase(duration: float) -> void:
	current_phase = REWARD_PHASE
	phase_time_remaining = duration
	phase_changed.emit(current_phase)
	timer_changed.emit(phase_time_remaining)


func enter_game_over(reason: String) -> void:
	if current_phase == GAME_OVER:
		return

	current_phase = GAME_OVER
	phase_time_remaining = 0.0
	phase_changed.emit(current_phase)
	timer_changed.emit(phase_time_remaining)
	run_lost.emit(reason)


func enter_victory() -> void:
	if current_phase == VICTORY:
		return

	current_phase = VICTORY
	phase_time_remaining = 0.0
	phase_changed.emit(current_phase)
	timer_changed.emit(phase_time_remaining)
	run_won.emit()


func can_build() -> bool:
	return current_phase == BUILD_PHASE


func get_phase_label() -> String:
	return String(current_phase).replace("_", " ").capitalize()


func get_time_remaining() -> float:
	return phase_time_remaining


func _on_wave_finished(_wave_number: int, reward_duration: float) -> void:
	enter_reward_phase(reward_duration)

