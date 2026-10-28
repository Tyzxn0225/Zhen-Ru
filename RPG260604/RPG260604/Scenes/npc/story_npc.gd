# StoryNPC — 剧情演出专用 NPC 子类
# 继承 NPC, 在对话/剧情中实现精确路径移动
# 提供两组方法: 即发即忘 (do 安全) / 阻塞版 (DM 可 await)

extends NPC
class_name StoryNPC


signal story_move_finished


func _ready() -> void:
	super._ready()


#region ── 公开: 即发即忘 ( 适合 dialogue 的 do 关键字调用, 不阻塞对话 ) ────────

# 单点移动
func move_to(target: Vector2, speed_override: float = -1.0) -> void:
	_begin_story_move()
	_chain_move_to(target, speed_override)


func _chain_move_to(target: Vector2, speed_override: float = -1.0) -> void:
	await _tween_to(target, speed_override)
	if _in_story_movement:
		_on_story_move_complete()


# 沿 Path2D 曲线路径移动
func follow_path(path: Path2D, speed_override: float = -1.0) -> void:
	_begin_story_move()
	_chain_follow_path(path, speed_override)


func _chain_follow_path(path: Path2D, speed_override: float) -> void:
	var spd := speed_override if speed_override > 0 else move_speed * 2.0

	var pf := PathFollow2D.new()
	pf.loop = false
	pf.rotates = false
	path.add_child(pf)

	var curve_length: float = path.curve.get_baked_length()
	var duration: float = curve_length / spd

	var last_pos := global_position

	_story_tween = create_tween()
	_story_tween.tween_method(
		func(progress: float):
			if not _in_story_movement:
				return
			pf.progress = progress * curve_length
			var pos := pf.global_position
			var dir := last_pos.direction_to(pos)
			if dir.length() > 0.01:
				update_direction(dir)
				play_animation("run" if spd > 100 else "move")
			last_pos = pos
			global_position = pos,
		0.0, 1.0, duration
	)
	await _story_tween.finished
	pf.queue_free()
	if _in_story_movement:
		_on_story_move_complete()


# 多点航点移动
func move_waypoints(waypoints: Array, speed_override: float = -1.0) -> void:
	_begin_story_move()
	_chain_waypoints(waypoints, speed_override)


func _chain_waypoints(waypoints: Array, speed_override: float) -> void:
	for wp in waypoints:
		await _tween_to(wp, speed_override)
		if not _in_story_movement:
			return
	if _in_story_movement:
		_on_story_move_complete()

#endregion


#region ── 公开: 阻塞版 ( DM 的 do 会 await 这些方法, 等移动完成再继续对话 ) ───

# 等待当前剧情移动完成 ( 不发起新移动 )
func wait_for_move():
	if _story_tween and _story_tween.is_valid():
		await _story_tween.finished
	while _in_story_movement:
		await get_tree().process_frame


# 单点移动 ( DM 等待 )
func move_blocking(target: Vector2, speed_override: float = -1.0):
	_begin_story_move()
	await _tween_to(target, speed_override)
	if _in_story_movement:
		_on_story_move_complete()


# 多点航点移动 ( DM 等待 )
func move_waypoints_blocking(waypoints: Array, speed_override: float = -1.0):
	_begin_story_move()
	for wp in waypoints:
		await _tween_to(wp, speed_override)
		if not _in_story_movement:
			return
	if _in_story_movement:
		_on_story_move_complete()

#endregion


#region ── 控制 & 内部实现 ──────────────────────────────────────────────────────

# 中途强制停止剧情移动
func stop_story_move() -> void:
	if not _in_story_movement:
		return
	if _story_tween and _story_tween.is_valid():
		_story_tween.kill()
	_in_story_movement = false
	play_animation("idle")
	_movement_paused = false


func _begin_story_move() -> void:
	_in_story_movement = true
	_movement_paused = true


# 用 tween 移动到目标点, 自动播放 move/idle 动画
func _tween_to(target: Vector2, speed_override: float = -1.0) -> void:
	var spd := speed_override if speed_override > 0 else move_speed * 2.0
	var dir := global_position.direction_to(target)
	var distance := global_position.distance_to(target)

	update_direction(dir)

	if distance < 1.0:
		play_animation("idle")
		return

	var duration := distance / spd
	play_animation("run" if spd > 100 else "move")

	_story_tween = create_tween()
	_story_tween.tween_property(self, "global_position", target, duration)
	await _story_tween.finished


# 移动完成: 释放标志位, 对话中自动面向玩家
func _on_story_move_complete() -> void:
	_in_story_movement = false
	if not _is_interacting:
		_movement_paused = false
	elif Refs.player:
		face_target(Refs.player)
	play_animation("idle")
	story_move_finished.emit()

#endregion
