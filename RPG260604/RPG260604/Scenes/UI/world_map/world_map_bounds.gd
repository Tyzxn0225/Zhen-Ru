class_name WorldMapBounds
extends RefCounted
## 大地图 / 小地图共用的 MINI MAP (Sprite2D) 边界计算与相机约束。


static func resolve_bounds(scene: Node, sprite_path: NodePath = NodePath("")) -> Rect2:
	var sprite := get_bounds_sprite(scene, sprite_path)
	if sprite == null:
		return Rect2()
	return sprite_world_rect(sprite)


static func get_bounds_sprite(scene: Node, sprite_path: NodePath = NodePath("")) -> Sprite2D:
	if not sprite_path.is_empty() and scene != null:
		var node := scene.get_node_or_null(sprite_path) as Sprite2D
		if node:
			return node
	if scene == null:
		return null
	return scene.get_node_or_null("MINI MAP") as Sprite2D


static func sprite_world_rect(sprite: Sprite2D) -> Rect2:
	var local_rect := sprite.get_rect()
	var xf := sprite.global_transform
	var corners: Array[Vector2] = [
		xf * local_rect.position,
		xf * local_rect.end,
		xf * Vector2(local_rect.end.x, local_rect.position.y),
		xf * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var min_x := corners[0].x
	var min_y := corners[0].y
	var max_x := corners[0].x
	var max_y := corners[0].y
	for corner in corners:
		min_x = minf(min_x, corner.x)
		min_y = minf(min_y, corner.y)
		max_x = maxf(max_x, corner.x)
		max_y = maxf(max_y, corner.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


static func get_effective_min_zoom(viewport_size: Vector2i, map_bounds: Rect2, min_zoom: float) -> float:
	if map_bounds.size == Vector2.ZERO or viewport_size.x <= 0:
		return min_zoom
	var vp_size := Vector2(viewport_size)
	var fit_zoom := maxf(
		vp_size.x / map_bounds.size.x,
		vp_size.y / map_bounds.size.y
	)
	return maxf(min_zoom, fit_zoom)


static func clamp_camera(
	camera: Camera2D,
	viewport_size: Vector2i,
	map_bounds: Rect2,
	min_zoom: float,
	max_zoom: float,
	clamp_zoom: bool = true
) -> void:
	if camera == null or map_bounds.size == Vector2.ZERO or viewport_size.x <= 0:
		return

	if clamp_zoom:
		var zoom_value := clampf(
			camera.zoom.x,
			get_effective_min_zoom(viewport_size, map_bounds, min_zoom),
			max_zoom
		)
		camera.zoom = Vector2(zoom_value, zoom_value)

	clamp_camera_position(camera, viewport_size, map_bounds)


static func clamp_camera_position(camera: Camera2D, viewport_size: Vector2i, map_bounds: Rect2) -> void:
	if camera == null or map_bounds.size == Vector2.ZERO or viewport_size.x <= 0:
		return

	var vp_world_size := Vector2(viewport_size) / camera.zoom
	var half := vp_world_size * 0.5

	var min_pos := map_bounds.position + half
	var max_pos := map_bounds.end - half

	if min_pos.x > max_pos.x:
		camera.position.x = map_bounds.get_center().x
	else:
		camera.position.x = clampf(camera.position.x, min_pos.x, max_pos.x)

	if min_pos.y > max_pos.y:
		camera.position.y = map_bounds.get_center().y
	else:
		camera.position.y = clampf(camera.position.y, min_pos.y, max_pos.y)
