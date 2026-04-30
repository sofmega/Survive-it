extends Camera2D

@export var edge_scroll_zone: float = 32.0
@export var edge_pan_speed: float = 900.0
@export var keyboard_pan_speed: float = 900.0
@export var pan_damping: float = 10.0
@export var zoom_step: float = 0.12
@export var min_zoom: float = 0.72
@export var max_zoom: float = 1.32
@export var zoom_smooth: float = 9.0

var map_view: Node = null
var target_position: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	make_current()
	target_position = global_position
	target_zoom = zoom.x
	set_process_input(true)
	set_process(true)


func setup(initial_focus: Node2D, next_map_view: Node) -> void:
	map_view = next_map_view
	if initial_focus != null:
		global_position = initial_focus.global_position
	target_position = global_position


func _process(delta: float) -> void:
	_viewport_size_update()
	_update_zoom(delta)
	_update_camera_target(delta)
	global_position = global_position.lerp(_clamp_position(target_position), delta * pan_damping)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clampf(target_zoom - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clampf(target_zoom + zoom_step, min_zoom, max_zoom)


func seek_world_position(world_position: Vector2) -> void:
	target_position = _clamp_position(world_position)
	global_position = target_position


func _viewport_size_update() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport_size = viewport.get_visible_rect().size
	else:
		viewport_size = Vector2.ZERO


func _update_zoom(delta: float) -> void:
	var current_zoom: float = clampf(zoom.x, min_zoom, max_zoom)
	target_zoom = clampf(target_zoom, min_zoom, max_zoom)
	var smooth_zoom: float = lerpf(current_zoom, target_zoom, delta * zoom_smooth)
	zoom = Vector2.ONE * smooth_zoom


func _update_camera_target(delta: float) -> void:
	var movement := _get_edge_direction() * edge_pan_speed + _get_keyboard_direction() * keyboard_pan_speed
	if movement == Vector2.ZERO:
		return

	target_position += movement.normalized() * maxf(edge_pan_speed, keyboard_pan_speed) * delta
	target_position = _clamp_position(target_position)


func _get_edge_direction() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO

	var mouse_position: Vector2 = viewport.get_mouse_position()
	var visible_size: Vector2 = viewport.get_visible_rect().size
	var direction := Vector2.ZERO

	if mouse_position.x <= edge_scroll_zone:
		direction.x = -1.0
	elif mouse_position.x >= visible_size.x - edge_scroll_zone:
		direction.x = 1.0

	if mouse_position.y <= edge_scroll_zone:
		direction.y = -1.0
	elif mouse_position.y >= visible_size.y - edge_scroll_zone:
		direction.y = 1.0

	return direction


func _get_keyboard_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)


func _clamp_position(position: Vector2) -> Vector2:
	if viewport_size == Vector2.ZERO:
		return position

	var world_size := Vector2(1600.0, 900.0)
	if map_view != null and map_view.has_method("get_world_size"):
		world_size = map_view.get_world_size()

	var half_view := viewport_size * 0.5 * zoom.x
	var clamped := position

	if half_view.x * 2.0 >= world_size.x:
		clamped.x = world_size.x * 0.5
	else:
		clamped.x = clampf(position.x, half_view.x, world_size.x - half_view.x)

	if half_view.y * 2.0 >= world_size.y:
		clamped.y = world_size.y * 0.5
	else:
		clamped.y = clampf(position.y, half_view.y, world_size.y - half_view.y)

	return clamped
