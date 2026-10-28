extends Control

# 游戏场景容器 - 所有游戏场景都在此根节点下居中显示
var current_scene_instance: Node = null

func _ready():
	# 设置根节点填满整个窗口
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 默认显示主菜单
	load_game_menu()

func load_game_menu():
	# 可以在这里加载默认的菜单场景
	# 或者显示一个游戏选择界面
	print("Main: 准备就绪，等待游戏加载")

func load_scene(scene_path: String):
	# 移除当前场景
	if current_scene_instance:
		current_scene_instance.queue_free()
		await get_tree().process_frame
	
	# 加载新场景
	var new_scene = load(scene_path)
	if new_scene:
		current_scene_instance = new_scene.instantiate()
		add_child(current_scene_instance)
		
		# 如果是 Control 类型，设置居中
		if current_scene_instance is Control:
			current_scene_instance.set_anchors_preset(Control.PRESET_CENTER)
		# 如果是 Node2D 类型，设置位置到窗口中心
		elif current_scene_instance is Node2D:
			var screen_size = get_viewport_rect().size
			current_scene_instance.position = screen_size / 2
		
		print("Main: 已加载场景 - ", scene_path)
	else:
		print("Main: 加载场景失败 - ", scene_path)

func _input(event: InputEvent):
	# 按 ESC 键可以返回主菜单（可选功能）
	if event.is_action_pressed("ui_cancel"):
		load_game_menu()
