extends SubViewport
## 小地图 SubViewport：跟随玩家，并约束在场景 MINI MAP 边界内。

@export var player: Node2D
@export var camera_2d: Camera2D
@export var clamp_to_map_bounds: bool = true

var _map_bounds: Rect2 = Rect2()


func _ready() -> void:
	world_2d = get_tree().root.world_2d
	get_tree().root.set_canvas_cull_mask_bit(1, false)
	size_changed.connect(_on_viewport_size_changed)
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_refresh_bounds_and_clamp")


func _on_scene_changed() -> void:
	_refresh_bounds_and_clamp()


func _process(_delta: float) -> void:
	if camera_2d == null:
		return
	var target := _get_follow_target()
	if target == null:
		return
	camera_2d.position = target.position
	if clamp_to_map_bounds:
		_clamp_camera(false)


func _on_viewport_size_changed() -> void:
	_clamp_camera(true)


func _refresh_bounds_and_clamp() -> void:
	_refresh_map_bounds()
	_clamp_camera(true)


func _refresh_map_bounds() -> void:
	var scene := get_tree().current_scene
	_map_bounds = WorldMapBounds.resolve_bounds(scene)


func _clamp_camera(clamp_zoom: bool) -> void:
	if not clamp_to_map_bounds or camera_2d == null:
		return
	if _map_bounds.size == Vector2.ZERO:
		_refresh_map_bounds()
	if _map_bounds.size == Vector2.ZERO:
		return
	var configured_zoom := camera_2d.zoom.x
	WorldMapBounds.clamp_camera(
		camera_2d,
		size,
		_map_bounds,
		configured_zoom,
		configured_zoom,
		clamp_zoom
	)


func _get_follow_target() -> Node2D:
	if is_instance_valid(player):
		return player
	if Refs.player and is_instance_valid(Refs.player):
		return Refs.player
	return get_tree().get_first_node_in_group("player") as Node2D
