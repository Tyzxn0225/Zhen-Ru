extends PanelContainer
## 可拖动、滚轮缩放的大地图面板。布局与尺寸请在检查器中调整。
## 拖动/缩放范围由当前场景根节点下的 MINI MAP (Sprite2D) 决定。


@onready var _viewport_container: SubViewportContainer = %SubViewportContainer
@onready var _sub_viewport: SubViewport = %SubViewport
@onready var _camera: Camera2D = %Camera2D
@onready var _close_button: Button = %CloseButton

## 留空则自动查找当前场景根下的 "MINI MAP" Sprite2D
@export var map_bounds_sprite: NodePath

## 打开面板时相机的初始世界坐标（Vector2.ZERO 则使用玩家当前位置，仅作起始视角）
@export var default_center: Vector2 = Vector2.ZERO
@export var default_zoom: float = 0.35
@export var min_zoom: float = 0.12
@export var max_zoom: float = 1.2
@export var zoom_step: float = 0.08
@export var drag_button: MouseButton = MOUSE_BUTTON_LEFT

const _DRAG_THRESHOLD := 6.0

var _is_dragging: bool = false
var _drag_last: Vector2 = Vector2.ZERO
var _drag_start: Vector2 = Vector2.ZERO
var _map_bounds: Rect2 = Rect2()


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)
	_viewport_container.gui_input.connect(_on_viewport_gui_input)
	_viewport_container.resized.connect(_on_viewport_resized)
	call_deferred("_sync_viewport_size")


func open() -> void:
	_refresh_map_bounds()
	_set_initial_camera_position()
	visible = true
	_ensure_clamped_after_layout.call_deferred()


func close() -> void:
	visible = false
	_is_dragging = false


func _set_initial_camera_position() -> void:
	if default_center != Vector2.ZERO:
		_camera.position = default_center
	elif Refs.player and is_instance_valid(Refs.player):
		_camera.position = Refs.player.global_position


## 面板刚显示时 SubViewportContainer 尚未完成布局，需等尺寸有效后再约束相机。
func _ensure_clamped_after_layout() -> void:
	if not visible:
		return
	_sync_viewport_size()
	if _viewport_container.size.x <= 0 or _viewport_container.size.y <= 0:
		_ensure_clamped_after_layout.call_deferred()
		return
	var zoom_value := clampf(default_zoom, _get_effective_min_zoom(), max_zoom)
	_camera.zoom = Vector2(zoom_value, zoom_value)
	_clamp_camera()


func _on_viewport_resized() -> void:
	_sync_viewport_size()
	_clamp_camera()


func _sync_viewport_size() -> void:
	if _viewport_container == null or _sub_viewport == null:
		return
	var size := _viewport_container.size.floor()
	if size.x > 0 and size.y > 0:
		_sub_viewport.size = Vector2i(size)


func _refresh_map_bounds() -> void:
	if not map_bounds_sprite.is_empty():
		var sprite := get_node_or_null(map_bounds_sprite) as Sprite2D
		if sprite:
			_map_bounds = WorldMapBounds.sprite_world_rect(sprite)
			return
	var scene := get_tree().current_scene
	_map_bounds = WorldMapBounds.resolve_bounds(scene)


func _get_effective_min_zoom() -> float:
	return WorldMapBounds.get_effective_min_zoom(_sub_viewport.size, _map_bounds, min_zoom)


func _clamp_camera() -> void:
	WorldMapBounds.clamp_camera(
		_camera,
		_sub_viewport.size,
		_map_bounds,
		min_zoom,
		max_zoom,
		true
	)


func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == drag_button:
			if event.pressed:
				_is_dragging = true
				_drag_last = event.position
				_drag_start = event.position
				get_viewport().set_input_as_handled()
			else:
				if _is_dragging and _drag_start.distance_to(event.position) < _DRAG_THRESHOLD:
					_handle_map_click(event.position)
				_is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(1.0 + zoom_step)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(1.0 / (1.0 + zoom_step))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_dragging:
		var delta: Vector2 = event.position - _drag_last
		_drag_last = event.position
		_camera.position -= delta / _camera.zoom
		_clamp_camera()
		get_viewport().set_input_as_handled()


func _apply_zoom(factor: float) -> void:
	var new_zoom := _camera.zoom * factor
	new_zoom = new_zoom.clamp(
		Vector2(_get_effective_min_zoom(), _get_effective_min_zoom()),
		Vector2(max_zoom, max_zoom)
	)
	_camera.zoom = new_zoom
	_clamp_camera()


func _handle_map_click(local_pos: Vector2) -> void:
	var world_pos := _local_to_world(local_pos)
	EventBus.map_travel_requested.emit(world_pos)


func _local_to_world(local_pos: Vector2) -> Vector2:
	var container_size := _viewport_container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		return Vector2.ZERO
	var vp_pos := local_pos * Vector2(_sub_viewport.size) / container_size
	return _camera.get_canvas_transform().affine_inverse() * vp_pos
