##
# 游戏管理器 - 负责游戏状态管理和胜利条件检测
##
extends Node2D

# Reset按钮引用
@onready var reset_button: Button = $CanvasLayer/Button
# Player节点引用（延迟获取，避免路径问题）
var player: Node2D

##
# 节点进入场景树时调用
# 注册事件监听器，监听箱子到达目标的事件
##
func _ready() -> void:
	# 连接事件：当箱子到达目标点时，调用 _on_crate_reached_dest
	EventBus.crate_reached_dest.connect(_on_crate_reached_dest)
	# 连接reset按钮的点击事件
	reset_button.pressed.connect(_on_reset_pressed)
	# 延迟初始化，确保TileMap完全加载所有动态创建的节点
	await get_tree().process_frame
	await get_tree().process_frame
	# 记录所有箱子初始位置
	_init_crates_initial_state()
	# 查找并记录玩家初始位置
	player = _find_player()
	if player:
		player.initial_cell_position = player.cell_position

##
# 查找Player节点
# 从Objects TileMapLayer的子节点中查找
##
func _find_player() -> Node2D:
	var objects_layer: Node2D = $Objects
	for child in objects_layer.get_children():
		if child.name == "Player" or (child.has_method("reset_position") and not child.is_in_group("crates")):
			return child
	return null

##
# 记录所有箱子的初始位置和状态
##
func _init_crates_initial_state() -> void:
	for crate: Crate in get_tree().get_nodes_in_group("crates"):
		# 使用 @onready 初始化后的 cell_position（此时应该已正确）
		crate.initial_cell_position = crate.cell_position
		crate.initial_is_reached = crate.is_reached

##
# 箱子到达目标点的事件处理函数
# 检查所有箱子是否都已到达目标点，判断游戏是否胜利
##
func _on_crate_reached_dest():
	# 遍历场景中所有标记为 "crates" 组的箱子
	for crate: Crate in get_tree().get_nodes_in_group("crates"):
		# 如果有任何一个箱子未到达目标点，直接返回（游戏未胜利）
		if not crate.is_reached:
			return

	# 所有箱子都已到达目标点，游戏胜利！
	print("Win!!")
	await Transition.fade_in(0.3)
	GameData.restore_player_data

	LongSceneManager.switch_scene(GameData.return_scene, LongSceneManager.LoadMethod.BOTH_PRELOAD_FIRST, true, "no_transition")
	if get_tree():
		await get_tree().process_frame
	Transition.fade_out(0.3)

##
# Reset按钮点击处理函数
# 让玩家和箱子回归原位
##
func _on_reset_pressed() -> void:
	# 重置所有箱子
	for crate: Crate in get_tree().get_nodes_in_group("crates"):
		crate.reset_position()
	# 重置玩家
	if player:
		player.reset_position()
