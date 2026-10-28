extends TextureButton
class_name NewPiece

# ========== 全局组限制系统 ==========
static var has_group_with_two_pieces: bool = false  # 标记是否已存在包含2个碎片的组
# =======================================

var offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var original_scale: float = 1.0

# 碎片信息
var piece_id: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var target_position_original: Vector2 = Vector2.ZERO
var grid_cols: int = 3
var grid_rows: int = 3

# 标记是否正在被拖拽（用于松开检测）
var _is_this_dragging: bool = false

# ========== 吸附系统相关变量 ==========
var adjacent_pieces: Dictionary = {
	"top": null,
	"bottom": null,
	"left": null,
	"right": null
}
var is_attached: bool = false  # 是否已吸附到其他碎片
var attached_group = null  # 所属的吸附组
var _original_parent: Node = null
# =======================================

# 音效相关
var game_scene: Node = null
var _last_play_time: float = 0  # 防止频繁播放

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	self_modulate = Color(0.9, 0.9, 0.9)
	scale = Vector2(0.2, 0.2)
	original_scale = 0.2
	_original_parent = get_parent()

# 设置GameScene引用（由GameScene调用）
func set_game_scene(scene: Node) -> void:
	game_scene = scene

# 播放碎片点击音效
@onready var audio_player = get_tree().root.get_node_or_null("/root/GameScene/AudioPlayer")
@onready var press2_sound = load("res://Microgame/Games/shared/assets/audio/press2.wav")
func _play_press2_sound():
	# 防止在游戏结束后播放音效
	if game_scene and game_scene.is_game_over:
		return
	
	# 防止频繁播放（100毫秒内只播放一次）
	var current_time = Time.get_ticks_msec()
	if current_time - _last_play_time < 100:
		return
	_last_play_time = current_time
	
# 播放音效
	if audio_player and press2_sound:
		audio_player.stream = press2_sound
		audio_player.play()
	else:
		# 备用方案：通过GameScene播放音效
		if game_scene and game_scene.has_method("play_piece_sound"):
			game_scene.play_piece_sound()
		else:
			var found_scene = get_tree().root.get_node_or_null("/root/GameScene")
			if found_scene and found_scene.has_method("play_piece_sound"):
				found_scene.play_piece_sound()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 播放碎片点击音效
			_play_press2_sound()
			
			# 鼠标按下 - 开始拖拽
			if not is_dragging:
				_start_drag(event.global_position)
				get_viewport().set_input_as_handled()
		else:
			# 鼠标松开 - 停止拖拽并检查吸附
			if _is_this_dragging:
				_stop_drag()
				get_viewport().set_input_as_handled()

func _start_drag(mouse_global_pos: Vector2) -> void:
	is_dragging = true
	_is_this_dragging = true
	offset = global_position - mouse_global_pos
	print("碎片 ", piece_id, " 开始拖拽")
	
	# 如果属于吸附组，让组开始拖拽
	if attached_group and is_attached:
		attached_group.start_dragging(self)

func _stop_drag() -> void:
	is_dragging = false
	_is_this_dragging = false
	offset = Vector2.ZERO
	scale = Vector2(original_scale, original_scale)
	
	# 如果是组的一部分，通知组结束拖拽
	if attached_group and is_attached:
		attached_group.stop_dragging()
	else:
		# 单个碎片拖拽结束，检查吸附
		check_adjacent_attachment()

func _process(_delta: float) -> void:
	# 拖拽中 - 只更新位置，不检查吸附
	if is_dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		var new_position = mouse_pos + offset
		
		# 如果属于吸附组，移动整个组
		if attached_group and is_attached:
			attached_group.move_group(new_position - global_position)
		else:
			global_position = new_position
		
		_boundary_check()

func _boundary_check() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var min_x = 0
	var min_y = 0
	var max_x = viewport_size.x - size.x * scale.x
	var max_y = viewport_size.y - size.y * scale.y
	
	var new_pos = global_position
	var needs_sync = false
	
	if new_pos.x <= min_x:
		new_pos.x = min_x
		needs_sync = true
	if new_pos.x >= max_x:
		new_pos.x = max_x
		needs_sync = true
	if new_pos.y <= min_y:
		new_pos.y = min_y
		needs_sync = true
	if new_pos.y >= max_y:
		new_pos.y = max_y
		needs_sync = true
	
	if new_pos != global_position:
		global_position = new_pos
		# 如果是组的一部分，同步组位置
		if attached_group and is_attached and needs_sync:
			attached_group.sync_group_position()

func set_grid_info(col: int, row: int, total_cols: int, total_rows: int):
	piece_id = Vector2(col, row)
	grid_cols = total_cols
	grid_rows = total_rows

func set_piece_texture(texture_resource: Texture2D) -> void:
	texture_normal = texture_resource
	texture_pressed = texture_resource
	texture_hover = texture_resource

func reset_to_position(new_position: Vector2) -> void:
	global_position = new_position
	_boundary_check()
	scale = Vector2(original_scale, original_scale)
	is_dragging = false
	offset = Vector2.ZERO
	_is_this_dragging = false
	
	# 重置时清除吸附状态
	detach_all()

func snap_to_target(target_pos: Vector2) -> void:
	global_position = target_pos
	_boundary_check()
	scale = Vector2(original_scale, original_scale)
	is_dragging = false
	offset = Vector2.ZERO

# ========== 吸附系统核心方法 ==========

# 设置相邻碎片关系（由主场景调用）
func set_adjacent(direction: String, piece) -> void:
	adjacent_pieces[direction] = piece

# 检查与相邻碎片的吸附（只在停止移动时调用）
func check_adjacent_attachment() -> void:
	# 如果碎片已经属于完成组，不再吸附
	if attached_group and not attached_group.can_be_moved:
		return
	
	# 延迟执行，确保位置已完全稳定
	await get_tree().create_timer(0.05).timeout
		
	for direction in ["top", "bottom", "left", "right"]:
		var adjacent = adjacent_pieces[direction]
		if adjacent and adjacent != null:
			# 检查两个碎片是否在不同组（或者无组）
			var in_different_groups = true
			if attached_group and adjacent.attached_group:
				in_different_groups = attached_group != adjacent.attached_group
			
			if in_different_groups:
				var distance = get_distance_to_adjacent(adjacent, direction)
				if distance < 10:  # 吸附距离阈值：10像素
					print("检测到吸附: 碎片 ", piece_id, " 距离 ", adjacent.piece_id, " 方向:", direction, " 距离:", distance)
					attach_to(adjacent, direction)
					return  # 一次只吸附一个碎片

# 计算与相邻碎片的实际距离
func get_distance_to_adjacent(adjacent, direction: String) -> float:
	var my_pos = global_position
	var target_pos = adjacent.global_position
	var my_size = size * scale.x
	var target_size = adjacent.size * adjacent.scale.x
	
	match direction:
		"top":
			return abs(my_pos.y - (target_pos.y + target_size.y))
		"bottom":
			return abs((my_pos.y + my_size.y) - target_pos.y)
		"left":
			return abs(my_pos.x - (target_pos.x + target_size.x))
		"right":
			return abs((my_pos.x + my_size.x) - target_pos.x)
	return INF

# 吸附到相邻碎片
func attach_to(adjacent, direction: String) -> void:
	print("碎片 ", piece_id, " 吸附到 ", adjacent.piece_id, " 方向:", direction)
	
	# 如果已经在同一个组，不需要重复吸附
	if attached_group and adjacent.attached_group == attached_group:
		return
	
	# ========== 组限制逻辑 ==========
	# 如果已经存在包含2个碎片的组
	if has_group_with_two_pieces:
		# 情况1：两个碎片都没有组 -> 不允许创建新组
		if not attached_group and not adjacent.attached_group:
			print("已有包含2个碎片的组存在，不允许创建新组")
			return
		
		# 情况2：当前碎片无组，相邻碎片有组 -> 允许加入现有组
		if not attached_group and adjacent.attached_group:
			print("允许加入现有组")
			# 继续执行，让碎片加入现有组
		
		# 情况3：当前碎片有组，相邻碎片无组 -> 允许加入现有组
		if attached_group and not adjacent.attached_group:
			print("允许加入现有组")
			# 继续执行，让碎片加入现有组
		
		# 情况4：两个碎片都有组，且是不同的组 -> 不允许合并（避免创建新的大组）
		if attached_group and adjacent.attached_group and attached_group != adjacent.attached_group:
			print("已有包含2个碎片的组存在，不允许合并组")
			return
	# ========================================
	
	# 获取或创建组
	var target_group = attached_group if attached_group else null
	var other_group = adjacent.attached_group if adjacent.attached_group else null
	
	if target_group and other_group:
		# 两个组合并
		print("合并组: 组A大小=", target_group.pieces.size(), " 组B大小=", other_group.pieces.size())
		# 将较小的组合并到较大的组
		if target_group.pieces.size() >= other_group.pieces.size():
			target_group.merge_group(other_group)
		else:
			other_group.merge_group(target_group)
	elif target_group:
		# 当前碎片有组，相邻碎片无组
		print("添加碎片到现有组")
		target_group.add_piece(adjacent, self, direction)
		
		# 检查组是否达到2个碎片
		if target_group.pieces.size() >= 2 and not has_group_with_two_pieces:
			has_group_with_two_pieces = true
			print("检测到组已包含2个碎片，后续不能再创建新组")
		
	elif other_group:
		# 相邻碎片有组，当前碎片无组
		print("添加碎片到现有组（反向）")
		other_group.add_piece(self, adjacent, _get_opposite_direction(direction))
		
		# 检查组是否达到2个碎片
		if other_group.pieces.size() >= 2 and not has_group_with_two_pieces:
			has_group_with_two_pieces = true
			print("检测到组已包含2个碎片，后续不能再创建新组")
		
	else:
		# 两个碎片都无组，创建新组
		# 检查是否可以创建新组
		if has_group_with_two_pieces:
			print("已有包含2个碎片的组存在，不允许创建新组")
			return
		
		print("创建新组")
		var new_group = PuzzleGroup.new()
		get_parent().add_child(new_group)
		new_group.add_piece(self, null, "")
		new_group.add_piece(adjacent, self, direction)
		
		# 新创建的组包含2个碎片
		has_group_with_two_pieces = true
		print("创建了新组，已包含2个碎片，后续不能再创建新组")

# 获取相反方向
func _get_opposite_direction(direction: String) -> String:
	match direction:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
	return direction

# 解吸附(用于重置游戏)
func detach_all() -> void:
	if attached_group:
		attached_group.remove_piece(self)
	attached_group = null
	is_attached = false

# 重置组系统静态变量
static func reset_group_system():
	has_group_with_two_pieces = false
	print("组系统已重置")

# 获取碎片实际大小
func get_actual_size() -> Vector2:
	return size * scale.x

# 更新位置（由组调用）
func set_group_position(new_pos: Vector2) -> void:
	global_position = new_pos

# =========================================


# ========== 吸附组类 ==========
class PuzzleGroup extends Node2D:
	signal group_moved
	signal piece_added
	signal group_completed

	var pieces: Array = []
	var piece_offsets: Dictionary = {}
	var can_be_moved: bool = true
	var is_dragging_group: bool = false
	var current_drag_piece = null
	
	func _ready():
		pass
	
	# 开始拖拽组
	func start_dragging(drag_piece) -> void:
		if not can_be_moved:
			return
		is_dragging_group = true
		current_drag_piece = drag_piece
		print("组开始拖拽，包含碎片数: ", pieces.size())
	
	# 结束拖拽组
	func stop_dragging() -> void:
		is_dragging_group = false
		current_drag_piece = null
		
		# 拖拽结束后，检查组内所有碎片的吸附
		print("组拖拽结束，检查所有碎片的吸附...")
		await get_tree().create_timer(0.05).timeout
		
		# 检查所有碎片的吸附
		for piece in pieces:
			piece.check_adjacent_attachment()
	
	# 合并另一个组
	func merge_group(other_group) -> void:
		print("合并组，当前组大小: ", pieces.size(), " 其他组大小: ", other_group.pieces.size())
		
		# 保存当前组位置
		var current_group_pos = global_position
		
		# 将其他组的所有碎片添加到当前组
		for piece in other_group.pieces:
			# 计算新碎片相对于当前组的位置
			var new_offset = piece.global_position - current_group_pos
			piece_offsets[piece] = new_offset
			piece.attached_group = self
			piece.is_attached = true
			pieces.append(piece)
		
		# 删除旧组
		other_group.queue_free()
		
		# 重新对齐位置
		reposition_pieces()
		emit_signal("piece_added")
		
		# 合并后检查是否达到2个碎片
		if pieces.size() >= 2 and not NewPiece.has_group_with_two_pieces:
			NewPiece.has_group_with_two_pieces = true
			print("合并后组包含", pieces.size(), "个碎片，后续不能再创建新组")
		
		# 检查是否完成
		var total_pieces = _get_total_pieces_count()
		if pieces.size() == total_pieces:
			can_be_moved = false
			emit_signal("group_completed")
			print("拼图完成！所有碎片已吸附")
			# 注意：这里不直接跳转，由GameScene的信号处理来跳转
	
	# 添加碎片到组中
	func add_piece(piece, relative_to = null, direction: String = "") -> void:
		if piece in pieces:
			return
			
		print("添加碎片到组: ", piece.piece_id)
		
		# 如果碎片已在其他组中，先将其从原组移除
		if piece.attached_group:
			piece.attached_group.remove_piece(piece)
		
		# 计算新碎片相对于组的位置
		var new_offset: Vector2
		if pieces.is_empty():
			# 第一个碎片，组位置设在碎片位置
			global_position = piece.global_position
			new_offset = Vector2.ZERO
		else:
			# 根据相对碎片和方向计算偏移
			var relative_offset = piece_offsets[relative_to]
			var relative_size = relative_to.get_actual_size()
			var piece_size = piece.get_actual_size()
			
			match direction:
				"top":
					new_offset = relative_offset + Vector2(0, -piece_size.y)
				"bottom":
					new_offset = relative_offset + Vector2(0, relative_size.y)
				"left":
					new_offset = relative_offset + Vector2(-piece_size.x, 0)
				"right":
					new_offset = relative_offset + Vector2(relative_size.x, 0)
				_:
					new_offset = piece.global_position - global_position
		
		# 将碎片添加到组
		pieces.append(piece)
		piece_offsets[piece] = new_offset
		piece.attached_group = self
		piece.is_attached = true
		
		# 重新对齐所有碎片位置
		reposition_pieces()
		
		emit_signal("piece_added")
		
		# 检查组是否完成
		var total_pieces = _get_total_pieces_count()
		if pieces.size() == total_pieces:
			can_be_moved = false
			emit_signal("group_completed")
			print("拼图完成！所有碎片已吸附")
	
	# 获取总碎片数量
	func _get_total_pieces_count() -> int:
		var parent = get_parent()
		if parent:
			var count = 0
			for child in parent.get_children():
				# 检查是否是碎片节点
				if child.has_method("set_grid_info") or "piece_id" in child:
					count += 1
			return count
		return pieces.size()
	
	# 从组中移除碎片
	func remove_piece(piece) -> void:
		var idx = pieces.find(piece)
		if idx == -1:
			return
		
		print("从组移除碎片: ", piece.piece_id)
		
		pieces.remove_at(idx)
		piece_offsets.erase(piece)
		piece.attached_group = null
		piece.is_attached = false
		
		if pieces.is_empty():
			queue_free()
		else:
			reposition_pieces()
	
	# 重新定位所有碎片位置
	func reposition_pieces() -> void:
		for piece in pieces:
			piece.set_group_position(global_position + piece_offsets[piece])
	
	# 移动整个组
	func move_group(delta: Vector2) -> void:
		if not can_be_moved:
			return
		if not is_dragging_group:
			return
		
		global_position += delta
		reposition_pieces()
		emit_signal("group_moved")
	
	# 同步组位置（用于边界检查）
	func sync_group_position() -> void:
		if not pieces.is_empty():
			var first_piece = pieces[0]
			var new_group_pos = first_piece.global_position - piece_offsets[first_piece]
			global_position = new_group_pos
			reposition_pieces()
	
	func can_move() -> bool:
		return can_be_moved
# =========================================
