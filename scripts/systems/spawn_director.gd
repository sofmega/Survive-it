extends Node

signal enemy_spawned(enemy: Node)
signal wave_spawn_completed

var enemies_root: Node2D = null
var structures_root: Node2D = null
var combat_system: Node = null
var hero: Node2D = null
var builder: Node2D = null
var map_view: Node = null

var active_entries: Array[Dictionary] = []
var elapsed: float = 0.0
var spawning: bool = false


func _ready() -> void:
	set_process(true)


func setup(next_enemies_root: Node2D, next_structures_root: Node2D, next_combat_system: Node, next_hero: Node2D, next_builder: Node2D, next_map_view: Node) -> void:
	enemies_root = next_enemies_root
	structures_root = next_structures_root
	combat_system = next_combat_system
	hero = next_hero
	builder = next_builder
	map_view = next_map_view

	if enemies_root == null:
		push_warning("SpawnDirector setup missing World/Enemies container.")
	if map_view == null:
		push_warning("SpawnDirector setup missing MapView reference.")


func start_wave(wave_plan: Dictionary) -> void:
	active_entries.clear()
	elapsed = 0.0
	spawning = true

	if wave_plan.is_empty():
		push_warning("SpawnDirector received an empty wave plan.")

	for entry in wave_plan.get("spawn_entries", []):
		active_entries.append({
			"entry": entry,
			"spawned": 0,
			"next_spawn_time": float(entry.get("start_time", 0.0)),
		})

	if active_entries.is_empty():
		push_warning("SpawnDirector wave plan contains no spawn entries.")


func stop_spawning() -> void:
	spawning = false
	active_entries.clear()


func _process(delta: float) -> void:
	if not spawning:
		return

	elapsed += delta
	var completed_entries := 0

	for entry_state in active_entries:
		var entry: Dictionary = entry_state["entry"]
		var spawned: int = entry_state["spawned"]
		var count: int = int(entry.get("count", 0))
		var interval: float = float(entry.get("interval", 1.0))

		while spawned < count and elapsed >= float(entry_state["next_spawn_time"]):
			_spawn_enemy(entry)
			spawned += 1
			entry_state["spawned"] = spawned
			entry_state["next_spawn_time"] = float(entry_state["next_spawn_time"]) + interval

		if spawned >= count:
			completed_entries += 1

	if completed_entries == active_entries.size():
		spawning = false
		wave_spawn_completed.emit()


func _spawn_enemy(entry: Dictionary) -> void:
	var enemy_def = entry.get("enemy_def")
	if enemy_def == null or enemy_def.scene == null:
		push_warning("SpawnDirector skipped spawn because enemy definition or scene was missing.")
		return

	if enemies_root == null:
		push_warning("SpawnDirector cannot spawn because World/Enemies is missing.")
		return

	var enemy: Node2D = enemy_def.scene.instantiate()
	if not (enemy is Node2D):
		push_warning("SpawnDirector skipped spawn because enemy scene root is not Node2D.")
		return
	var portal_id: StringName = entry.get("spawn_point_id", &"left_center")
	var spawn_position: Vector2 = Vector2(220.0, 700.0)
	var search_route: Array[Vector2] = []

	if map_view != null:
		var portal_positions: Dictionary = {}
		if map_view.has_method("get_spawn_portal_positions"):
			portal_positions = map_view.get_spawn_portal_positions()
		if not portal_positions.is_empty() and not portal_positions.has(portal_id):
			push_warning("SpawnDirector received unknown portal id '%s'. Using MapView fallback." % String(portal_id))
		if map_view.has_method("get_spawn_position"):
			spawn_position = map_view.get_spawn_position(portal_id)
		if map_view.has_method("get_search_route_for_portal"):
			search_route = map_view.get_search_route_for_portal(portal_id)
	else:
		push_warning("SpawnDirector is missing MapView during enemy spawn. Using fallback spawn position.")

	enemy.global_position = spawn_position

	if enemy.has_method("setup"):
		enemy.setup(enemy_def, structures_root, combat_system, hero, builder, map_view, search_route, entry)
	else:
		push_warning("Spawned enemy scene is missing setup().")
	if hero == null and builder == null:
		push_warning("SpawnDirector spawned enemy without hero/builder targets.")

	enemies_root.add_child(enemy)
	enemy_spawned.emit(enemy)
