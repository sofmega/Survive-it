extends Camera2D

const MAP_VIEW := preload("res://scripts/world/map_view.gd")
const WORLD_SIZE: Vector2 = MAP_VIEW.WORLD_SIZE

@export var edge_scroll_zone: float = 32.0
@export var edge_pan_speed: float = 600.0
@export var keyboard_pan_speed: float = 320.0
@export var pan_damping: float = 6.0
@export var manual_offset_limit: float = 900.0
@export var minimap_focus_hold: float = 2.2
@export var zoom_speed: float = 0.12
@export var min_zoom: float = 0.72
@export var max_zoom: float = 1.32
@export var zoom_smooth: float = 9.0

var fortress_ref: Node2D = null
var manual_offset: Vector2 = Vector2.ZERO
var manual_hold_timer: float = 0.0
var target_zoom: float = 1.0
var viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	target_zoom = zoom.x
	set_process_input(true)
	set_process(true)

func setup(next_fortress: Node2D) -> void:
	fortress_ref = next_fortress
	if fortress_ref != null:
		global_position = fortress_ref.global_position

func _process(delta: float) -> void:
	if fortress_ref == null:
		return

	_viewport_size_update()
	_update_zoom(delta)
	_update_manual_offset(delta)

	var desired_position: Vector2 = fortress_ref.global_position + manual_offset
	global_position = global_position.lerp(_clamp_position(desired_position), delta * pan_damping)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)

func seek_world_position(world_position: Vector2) -> void:
	if fortress_ref == null:
		return
	manual_offset = (world_position - fortress_ref.global_position).limit_length(manual_offset_limit)
	manual_hold_timer = minimap_focus_hold

func _viewport_size_update() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport_size = viewport.get_visible_rect().size
	else:
		viewport_size = Vector2.ZERO

func _update_zoom(delta: float) -> void:
	var current_zoom: float = zoom.x
	current_zoom = clamp(current_zoom, min_zoom, max_zoom)
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	var smooth_zoom: float = lerp(current_zoom, target_zoom, delta * zoom_smooth)
	zoom = Vector2.ONE * smooth_zoom

func _update_manual_offset(delta: float) -> void:
	var edge_direction: Vector2 = _get_edge_direction()
	var key_direction: Vector2 = _get_keyboard_direction()
	var movement := edge_direction + key_direction
	if movement != Vector2.ZERO:
		manual_offset += movement.normalized() * edge_pan_speed * delta
		manual_hold_timer = 0.6
	elif manual_hold_timer > 0.0:
		manual_hold_timer = max(manual_hold_timer - delta, 0.0)
	else:
		manual_offset = manual_offset.move_toward(Vector2.ZERO, keyboard_pan_speed * delta)

	manual_offset = manual_offset.limit_length(manual_offset_limit)

func _get_edge_direction() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var view_size: Vector2 = viewport.get_visible_rect().size
	var direction := Vector2.ZERO
	if mouse_pos.x <= edge_scroll_zone:
		direction.x = -1
	elif mouse_pos.x >= view_size.x - edge_scroll_zone:
		direction.x = 1
	if mouse_pos.y <= edge_scroll_zone:
		direction.y = -1
	elif mouse_pos.y >= view_size.y - edge_scroll_zone:
		direction.y = 1
	return direction

func _get_keyboard_direction() -> Vector2:
	var axis := Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
	return axis

func _clamp_position(position: Vector2) -> Vector2:
	if viewport_size == Vector2.ZERO:
		return position
	var half_view := viewport_size * 0.5 * zoom.x
	var clamped := position
	if half_view.x * 2 >= WORLD_SIZE.x:
		clamped.x = WORLD_SIZE.x * 0.5
	else:
		clamped.x = clamp(position.x, half_view.x, WORLD_SIZE.x - half_view.x)
	if half_view.y * 2 >= WORLD_SIZE.y:
		clamped.y = WORLD_SIZE.y * 0.5
	else:
		clamped.y = clamp(position.y, half_view.y, WORLD_SIZE.y - half_view.y)
	return clamped
