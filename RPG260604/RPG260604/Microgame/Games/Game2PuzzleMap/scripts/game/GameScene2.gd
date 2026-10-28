extends Node2D

@onready var puzzle_container = $PuzzleContainer
@onready var game_timer = $GameTimer
@onready var timer_label = $UILayer/TimerLabel
@onready var back_button = $UILayer/BackButton
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var win_audio_player: AudioStreamPlayer = $WinAudioPlayer
@onready var lose_audio_player: AudioStreamPlayer = $LoseAudioPlayer
@onready var press_audio_player: AudioStreamPlayer = $PressAudioPlayer
@onready var image_preview: TextureRect = $ImagePreview  # 新增：图片预览节点

# 音效资源
var press1_sound: AudioStream  # 按钮音效
var press2_sound: AudioStream  # 碎片音效
var win_sound: AudioStream
var lose_sound: AudioStream

var grid_size: Vector2
var piece_size: Vector2
var pieces: Array = []           # 存储所有碎片
var pieces_dict: Dictionary = {} # 按网格坐标存储碎片的字典
var is_game_over: bool = false
var loaded_image: Image = null
var piece_scene: PackedScene

var _total_time_limit: float = 60.0
var _time_left: float = 60.0
var _victory_triggered: bool = false  # 防止重复触发胜利

func _ready():
	# 加载音效文件
	press1_sound = load("res://Microgame/Games/shared/assets/audio/press1.wav")
	press2_sound = load("res://Microgame/Games/shared/assets/audio/press2.wav")
	win_sound = load("res://Microgame/Games/shared/assets/audio/win.wav")
	lose_sound = load("res://Microgame/Games/shared/assets/audio/lose.wav")
	
	# 配置音频播放器
	#if press_audio_player:
		#press_audio_player.volume_db = 0  # 可以调整音量（负数减小，正数增大）
	
	# 连接按钮信号
	back_button.pressed.connect(_on_back_pressed)
	back_button.pressed.connect(_play_button_sound)  # 返回按钮音效
	
	piece_scene = preload("res://Microgame/Games/shared/scenes/NewPiece.tscn")
	_setup_game()

# 播放按钮音效（press1）
func _play_button_sound():
	if press_audio_player and press1_sound:
		press_audio_player.stream = press1_sound
		press_audio_player.play()

# 播放碎片音效（press2）- 供NewPiece调用
func play_piece_sound():
	if audio_player and press2_sound and not is_game_over:
		audio_player.stream = press2_sound
		audio_player.play()

func _setup_game():
	# 重置组系统
	NewPiece.reset_group_system()
	
	grid_size = MicroGameManage.get_instance().get_grid_size()
	var time_limit = MicroGameManage.get_instance().get_time_limit()
	
	print("开始游戏 - 网格: ", grid_size)
	
	# 如果时间限制为 -1，表示无时间限制
	if time_limit > 0:
		_total_time_limit = time_limit
		_time_left = time_limit
		game_timer.wait_time = 1.0
		game_timer.timeout.connect(_on_timer_tick)
		game_timer.start()
		update_timer_display()
	else:
		# 无时间限制，隐藏计时器
		timer_label.visible = false
		print("无时间限制模式")
	
	# 添加拼图完成检查定时器
	var check_timer = Timer.new()
	check_timer.wait_time = 0.5
	check_timer.autostart = true
	check_timer.timeout.connect(_check_complete_by_groups)
	add_child(check_timer)
	
	_load_random_image()

func update_timer_display():
	var minutes = int(_time_left) / 60
	var seconds = int(_time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_timer_tick():
	if is_game_over:
		return
	
	_time_left -= 1
	update_timer_display()
	
	if _time_left <= 0:
		_time_left = 0
		update_timer_display()
		is_game_over = true
		game_timer.stop()
		
		# 播放失败音效
		if lose_audio_player and lose_sound:
			lose_audio_player.stream = lose_sound
			lose_audio_player.play()
			# 等待音效播放完再跳转（可选）
			await lose_audio_player.finished
		
		print("游戏失败 - 时间到")
		_show_game_over()

func _load_random_image():
	var images = MicroGameManage.get_instance().get_available_images()
	if images.is_empty():
		print("错误：没有找到图片！使用程序生成测试图片")
		_generate_test_image()
		return
	
	var random_image_path = images[randi() % images.size()]
	print("加载图片: ", random_image_path)
	# 使用 load() 而非 Image.load() —— 后者在导出 .pck 中可能无法读取 res:// 路径
	var texture: Texture2D = load(random_image_path)
	if texture:
		loaded_image = texture.get_image()
		print("图片加载成功，尺寸: ", loaded_image.get_width(), "x", loaded_image.get_height())
		
		# 显示预览图片5秒
		await _show_image_preview()
		
		_generate_pieces()
	else:
		print("图片加载失败，使用测试图片")
		_generate_test_image()

# 显示图片预览（5秒）
func _show_image_preview() -> void:
	if loaded_image:
		var preview_texture = ImageTexture.create_from_image(loaded_image)
		image_preview.texture = preview_texture
		# 设置图片自适应屏幕并居中
		image_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # 按纹理大小显示
		image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # 保持宽高比并居中
		
		# 计算合适的缩放比例，确保图片在屏幕内
		var screen_size = get_viewport().get_visible_rect().size
		var image_size = preview_texture.get_size()
		
		# 计算缩放比例，确保图片不超过屏幕的80%
		var scale_x = (screen_size.x * 0.8) / image_size.x
		var scale_y = (screen_size.y * 0.8) / image_size.y
		var min_scale = min(scale_x, scale_y)
		
		image_preview.scale = Vector2(0.8, 0.8)
		image_preview.visible = true
		
		# 等待5秒
		await get_tree().create_timer(5.0).timeout
		
		# 隐藏预览图片
		image_preview.visible = false
		print("图片预览结束，开始切割拼图")
	

func _generate_test_image():
	print("生成测试图片")
	loaded_image = Image.create(512, 512, false, Image.FORMAT_RGB8)
	loaded_image.fill(Color(0.2, 0.3, 0.4, 1.0))
	for x in range(512):
		loaded_image.set_pixel(x, x, Color.WHITE)
		loaded_image.set_pixel(x, 511 - x, Color.WHITE)
		if x < 10 or x > 502:
			for y in range(512):
				loaded_image.set_pixel(x, y, Color.WHITE)
				loaded_image.set_pixel(y, x, Color.WHITE)
	_generate_pieces()

func _generate_pieces():
	print("=== 开始生成碎片 ===")
	
	var img_width = loaded_image.get_width()
	var img_height = loaded_image.get_height()
	
	# 将图片放大3倍后再切割
	var scale_factor = 3
	loaded_image.resize(img_width * scale_factor, img_height * scale_factor, Image.INTERPOLATE_LANCZOS)
	img_width = loaded_image.get_width()
	img_height = loaded_image.get_height()
	print("图片已放大3倍: ", img_width / scale_factor, "x", img_height / scale_factor, " -> ", img_width, "x", img_height)
	
	var cols = int(grid_size.x)
	var rows = int(grid_size.y)
	
	# 获取屏幕尺寸
	var screen_size = get_viewport().get_visible_rect().size
	
	# 目标拼图区域大小
	var target_puzzle_width = 800.0
	var target_puzzle_height = 600.0
	
	var grid_aspect = cols / float(rows)
	var max_width = screen_size.x - 100
	var max_height = screen_size.y - 150
	
	var puzzle_width: float
	var puzzle_height: float
	
	if grid_aspect > max_width / max_height:
		puzzle_width = min(target_puzzle_width, max_width)
		puzzle_height = puzzle_width / grid_aspect
	else:
		puzzle_height = min(target_puzzle_height, max_height)
		puzzle_width = puzzle_height * grid_aspect
	
	var gap = 8.0
	var piece_w = (puzzle_width - gap * (cols - 1)) / cols
	var piece_h = (puzzle_height - gap * (rows - 1)) / rows
	var min_piece_size = 40.0
	piece_w = max(piece_w, min_piece_size)
	piece_h = max(piece_h, min_piece_size)
	
	var original_piece_w = piece_w * 2
	var original_piece_h = piece_h * 2
	
	var actual_puzzle_width = piece_w * cols + gap * (cols - 1)
	var actual_puzzle_height = piece_h * rows + gap * (rows - 1)
	var start_x = (screen_size.x - actual_puzzle_width) / 2
	var start_y = (screen_size.y - actual_puzzle_height) / 2
	
	print("碎片尺寸: ", piece_w, "x", piece_h)
	
	# 清空旧数据
	pieces.clear()
	pieces_dict.clear()
	
	for child in puzzle_container.get_children():
		child.queue_free()
	
	# 收集所有目标点位（弹开范围扩大2倍）
	var scatter_range = 2.0  # 弹开范围倍数
	var target_positions = []
	for row in range(rows):
		for col in range(cols):
			# 计算基于屏幕中心的目标位置，范围扩大2倍
			var center_x = screen_size.x / 2
			var center_y = screen_size.y / 2
			var offset_x = (col - cols / 2.0) * (piece_w + gap) * scatter_range
			var offset_y = (row - rows / 2.0) * (piece_h + gap) * scatter_range
			var pos_x = center_x + offset_x - piece_w / 2
			var pos_y = center_y + offset_y - piece_h / 2
			target_positions.append(Vector2(pos_x, pos_y))
	
	# 创建所有碎片
	var piece_grid = []  # 二维数组存储碎片引用
	
	for row in range(rows):
		piece_grid.append([])
		for col in range(cols):
			# 切割图片
			var src_x = col * (img_width / float(cols))
			var src_y = row * (img_height / float(rows))
			var src_w = img_width / float(cols)
			var src_h = img_height / float(rows)
			var src_rect = Rect2(src_x, src_y, src_w, src_h)
			
			var piece_image = loaded_image.get_region(src_rect)
			var piece_texture = ImageTexture.create_from_image(piece_image)
			
			var piece = piece_scene.instantiate()
			
			# 设置碎片大小
			piece.custom_minimum_size = Vector2(original_piece_w, original_piece_h)
			piece.size = Vector2(original_piece_w, original_piece_h)
			piece.set_piece_texture(piece_texture)
			piece.set_grid_info(col, row, cols, rows)
			# 传递GameScene引用给碎片
			piece.set_game_scene(self)
			
			puzzle_container.add_child(piece)
			piece_grid[row].append(piece)
			pieces.append(piece)
			pieces_dict[Vector2(col, row)] = piece
	
	# 建立相邻关系（用于吸附系统）
	for row in range(rows):
		for col in range(cols):
			var piece = piece_grid[row][col]
			
			# 设置相邻碎片
			if col > 0:  # 左侧碎片
				piece.set_adjacent("left", piece_grid[row][col - 1])
			if col < cols - 1:  # 右侧碎片
				piece.set_adjacent("right", piece_grid[row][col + 1])
			if row > 0:  # 上方碎片
				piece.set_adjacent("top", piece_grid[row - 1][col])
			if row < rows - 1:  # 下方碎片
				piece.set_adjacent("bottom", piece_grid[row + 1][col])
	
	# 随机分配目标位置（用于动画）
	var shuffled_positions = target_positions.duplicate()
	shuffled_positions.shuffle()
	
	for piece in pieces:
		var target_pos = shuffled_positions.pop_back()
		piece.target_position = target_pos
		piece.target_position_original = target_pos  # 保存原始目标位置
	
	print("=== 生成了 ", pieces.size(), " 个拼图碎片 ===")
	
	if pieces.size() == 0:
		return
	
	await get_tree().process_frame
	_play_scatter_animation()

func _play_scatter_animation():
	print("=== 开始散开动画 ===")
	
	if pieces.is_empty():
		return
	
	var screen_center = get_viewport().get_visible_rect().size / 2
	
	for piece in pieces:
		piece.global_position = screen_center
		piece.visible = true
	
	await get_tree().process_frame
	
	for piece in pieces:
		var target = piece.target_position
		var tween = create_tween()
		tween.tween_property(piece, "global_position", target, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# 动画结束后连接碎片吸附信号
		tween.finished.connect(_on_animation_finished.bind(piece), CONNECT_ONE_SHOT)

# 动画完成后的处理
func _on_animation_finished(piece):
	# 监听碎片的吸附组完成信号
	if piece.attached_group:
		# 先断开之前的连接避免重复
		if piece.attached_group.group_completed.is_connected(_on_group_completed):
			piece.attached_group.group_completed.disconnect(_on_group_completed)
		piece.attached_group.group_completed.connect(_on_group_completed)
		# 如果碎片已经在组中，检查是否完成
		_check_complete_by_groups()

# 通过组系统检查拼图完成
func _check_complete_by_groups():
	# 防止重复触发
	if is_game_over or _victory_triggered:
		return
	
	if pieces.is_empty():
		return
	
	print("[检查拼图完成] 碎片总数: ", pieces.size())
	
	# 检查1：如果最大的组包含所有碎片，拼图完成
	var max_group_pieces = 0
	var completed_group = null
	
	for piece in pieces:
		if piece.attached_group and piece.attached_group.pieces.size() > max_group_pieces:
			max_group_pieces = piece.attached_group.pieces.size()
			completed_group = piece.attached_group
	
	# 如果最大的组包含所有碎片，拼图完成
	if max_group_pieces == pieces.size() and completed_group:
		print("=== 所有碎片已吸附完成！碎片数量: ", pieces.size(), " 组内数量: ", max_group_pieces)
		_game_victory()
		return
	
	# 方法2：备选检查 - 如果所有碎片都有 attached_group 且都属于同一个组
	var first_group = null
	var all_in_same_group = true
	for piece in pieces:
		if not piece.attached_group:
			all_in_same_group = false
			break
		if first_group == null:
			first_group = piece.attached_group
		elif piece.attached_group != first_group:
			all_in_same_group = false
			break
	
	if all_in_same_group and first_group and first_group.pieces.size() == pieces.size():
		print("=== 备选检查：所有碎片在同一组中！")
		_game_victory()

func _on_group_completed():
	print("检测到组完成信号")
	_check_complete_by_groups()

# 胜利逻辑
func _game_victory():
	if is_game_over or _victory_triggered:
		return
	
	_victory_triggered = true
	is_game_over = true
	game_timer.stop()
	
	# 播放胜利音效
	if win_audio_player and win_sound:
		win_audio_player.stream = win_sound
		win_audio_player.play()
		# 等待音效播放完再跳转（可选）
		await win_audio_player.finished
	
	print("胜利！拼图完成 - 准备跳转胜利场景")
	_show_victory()

# 显示胜利场景
func _show_victory():
	print("=== 执行跳转到胜利场景 ===")
	# 使用 MicroGameManage 的端游戏功能
	MicroGameManage.end_game(true)
	
# 显示失败场景
func _show_game_over():
	if game_timer:
		game_timer.stop()
	print("=== 执行跳转到失败场景 ===")
	# 使用 MicroGameManage 的端游戏功能
	MicroGameManage.end_game(false)

func _on_back_pressed():
	# 返回按钮已经连接了音效，这里只做场景切换
	get_tree().change_scene_to_file("res://Microgame/Games/Game2PuzzleMap/scenes/ui/StartMenu2.tscn")

# 获取所有碎片（供组系统使用）
func get_all_pieces() -> Array:
	return pieces
