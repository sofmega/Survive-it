extends Node

signal enemy_spawned(enemy: Node)
signal wave_spawn_completed

var enemies_root: Node2D = null
var fortress: Node2D = null
var combat_system: Node = null
var spawn_points: Dictionary = {}

var active_entries: Array[Dictionary] = []
var elapsed: float = 0.0
var spawning: bool = false


func setup(next_enemies_root: Node2D, next_fortress: Node2D, next_combat_system: Node, next_spawn_points: Dictionary) -> void:
	enemies_root = next_enemies_root
	fortress = next_fortress
	combat_system = next_combat_system
	spawn_points = next_spawn_points


func start_wave(wave_def) -> void:
	active_entries.clear()
	elapsed = 0.0
	spawning = true

	for entry in wave_def.spawn_entries:
		active_entries.append({
			"entry": entry,
			"spawned": 0,
			"next_spawn_time": entry.start_time,
		})


func _process(delta: float) -> void:
	if not spawning:
		return

	elapsed += delta
	var completed_entries := 0

	for entry_state in active_entries:
		var entry = entry_state["entry"]
		var spawned: int = entry_state["spawned"]

		while spawned < entry.count and elapsed >= float(entry_state["next_spawn_time"]):
			_spawn_enemy(entry)
			spawned += 1
			entry_state["spawned"] = spawned
			entry_state["next_spawn_time"] = float(entry_state["next_spawn_time"]) + entry.interval

		if spawned >= entry.count:
			completed_entries += 1

	if completed_entries == active_entries.size():
		spawning = false
		wave_spawn_completed.emit()


func _spawn_enemy(entry) -> void:
	if entry.enemy == null or entry.enemy.scene == null:
		return

	var enemy: Node2D = entry.enemy.scene.instantiate()
	enemy.global_position = spawn_points.get(entry.spawn_point_id, Vector2(96, 450))

	if enemy.has_method("setup"):
		enemy.setup(entry.enemy, fortress, combat_system)

	enemies_root.add_child(enemy)
	enemy_spawned.emit(enemy)
