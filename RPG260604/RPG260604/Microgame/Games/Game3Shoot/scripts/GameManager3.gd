extends Node2D

@export var slime_scene: PackedScene
@export var spawn_timer: Timer
@export var score_label: Label

var manager: MicroGameManage = null
var game_ended: bool = false

func _ready():
	manager = MicroGameManage.get_instance()
	
	# 获取难度配置
	var target_score = manager.get_target_score()
	var spawn_rate = manager.get_spawn_rate()
	
	# 根据难度显示对应的CanvasLayer
	_update_difficulty_ui()
	
	# 设置生成速率
	if spawn_timer:
		spawn_timer.wait_time = spawn_rate
		spawn_timer.start()
	
	# 连接返回按钮信号
	var back_button = get_node_or_null("Boundary/UICanvas/BackButton")
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# 监听分数更新
	manager.score_updated.connect(_on_score_updated)
	manager.game_won.connect(_on_game_won)
	manager.game_lost.connect(_on_game_lost)

func _update_difficulty_ui():
	# 获取难度并显示对应的CanvasLayer
	var difficulty = manager.current_difficulty
	print("[DEBUG] _update_difficulty_ui called, difficulty=", difficulty)
	print("[DEBUG] self name=", name, " type=", get_class())
	
	# GameManager就是根节点，Boundary是它的直接子节点
	var canvas1 = get_node("Boundary/CanvasLayer1")
	var canvas2 = get_node("Boundary/CanvasLayer2")
	var canvas3 = get_node("Boundary/CanvasLayer3")
	
	print("[DEBUG] canvas1=", canvas1, " canvas2=", canvas2, " canvas3=", canvas3)
	
	# 先隐藏所有CanvasLayer
	canvas1.visible = (difficulty == MicroGameManage.Difficulty.EASY)
	canvas2.visible = (difficulty == MicroGameManage.Difficulty.NORMAL)
	canvas3.visible = (difficulty == MicroGameManage.Difficulty.HARD)
	
	# 设置score_label为当前难度对应的Label
	match difficulty:
		MicroGameManage.Difficulty.EASY:
			score_label = get_node("Boundary/CanvasLayer1/Label")
		MicroGameManage.Difficulty.NORMAL:
			score_label = get_node("Boundary/CanvasLayer2/Label")
		MicroGameManage.Difficulty.HARD:
			score_label = get_node("Boundary/CanvasLayer3/Label")
	
	print("[DEBUG] Final score_label=", score_label, " text=", score_label.text if score_label else "null")

func _on_game_won(final_score: int):
	game_ended = true
	if spawn_timer:
		spawn_timer.stop()
	# 显示胜利界面
	var end_win = get_node_or_null("Boundary/EndWin")
	if end_win:
		end_win.visible = true
	# 播放玩家胜利动画
	var player_node = get_node_or_null("Player")
	if player_node:
		player_node.on_win()
	print("游戏胜利！最终分数: ", final_score)

func _on_game_lost(reason: String):
	game_ended = true
	if spawn_timer:
		spawn_timer.stop()
	# 显示失败界面
	var end_lose = get_node("Boundary/EndLose")
	if end_lose:
		end_lose.visible = true
	print("游戏失败: ", reason)

func _on_score_updated(score: int):
	# 更新UI显示
	var current_score_label = _get_current_score_label()
	if current_score_label:
		current_score_label.text = "Score: " + str(score) + "/" + str(manager.get_target_score())

func _get_current_score_label() -> Label:
	return score_label

func _spawn_slime():
	var slime_node = slime_scene.instantiate()
	slime_node.position = Vector2(260, randf_range(50, 70))
	add_child(slime_node)

func on_enemy_killed():
	manager.add_score(1)

func show_game_over():
	manager.end_game(false, "被敌人攻击")
	
func _on_back_pressed():
	print("返回按钮点击")
	manager.load_menu_scene()
