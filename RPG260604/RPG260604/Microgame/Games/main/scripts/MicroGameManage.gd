extends Node2D

# ============== 状态枚举 ==============
enum GameState {
	MENU,        # 主菜单
	LOADING,     # 加载中
	PLAYING,     # 游戏中
	PAUSED,      # 暂停
	WON,         # 胜利
	LOST         # 失败
}

# ============== 游戏类型枚举 ==============
enum GameType {
	PUZZLE_ALL = 0,   # Game1: 拼图大挑战
	PUZZLE_MAP = 1,   # Game2: 地图拼图
	SHOOT = 2         # Game3: 射击游戏
}

# ============== 难度枚举 ==============
enum Difficulty {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
	MAP = 3  # 特殊难度：地图模式
}

# ============== 全局状态 ==============
var current_state: int = GameState.MENU
var current_game: int = GameType.PUZZLE_ALL
var current_difficulty: int = Difficulty.EASY
var current_score: int = 0
var time_elapsed: float = 0.0

# ============== 游戏配置 ==============
var game_configs: Dictionary = {
	0: {  # GameType.PUZZLE_ALL
		"name": "拼图大挑战",
		"main_scene": "res://Microgame/Games/Game1PuzzleAll/scenes/game/GameScene1.tscn",
		"menu_scene": "res://Microgame/Games/Game1PuzzleAll/scenes/ui/StartMenu1.tscn",
		"victory_scene": "res://Microgame/Games/Game1PuzzleAll/scenes/ui/Victory1.tscn",
		"gameover_scene": "res://Microgame/Games/Game1PuzzleAll/scenes/ui/GameOver1.tscn",
		"difficulty_settings": {
			0: { "grid": Vector2(3, 3), "time": 120.0, "folder": "picture3x3" },
			1: { "grid": Vector2(5, 3), "time": 240.0, "folder": "picture3x5" },
			2: { "grid": Vector2(6, 4), "time": 300.0, "folder": "picture4x6" }
		},
		"asset_path": "res://Microgame/Games/Game1PuzzleAll/assets/"
	},
	1: {  # GameType.PUZZLE_MAP
		"name": "地图拼图",
		"main_scene": "res://Microgame/Games/Game2PuzzleMap/scenes/game/GameScene2.tscn",
		"menu_scene": "res://Microgame/Games/Game2PuzzleMap/scenes/ui/StartMenu2.tscn",
		"victory_scene": "res://Microgame/Games/Game2PuzzleMap/scenes/ui/MapGet.tscn",
		"gameover_scene": "res://Microgame/Games/Game1PuzzleAll/scenes/ui/GameOver1.tscn",
		"difficulty_settings": {
			3: { "grid": Vector2(3, 3), "time": -1.0, "folder": "map" }
		},
		"asset_path": "res://Microgame/Games/Game2PuzzleMap/assets/"
	},
	2: {  # GameType.SHOOT
		"name": "射击游戏",
		"main_scene": "res://Microgame/Games/Game3Shoot/scenes/Game.tscn",
		"menu_scene": "res://Microgame/Games/Game3Shoot/scenes/StartMenu3.tscn",
		"difficulty_settings": {
			0: { "target_score": 10, "spawn_rate": 2.0 },
			1: { "target_score": 20, "spawn_rate": 1.5 },
			2: { "target_score": 35, "spawn_rate": 1.0 }
		},
		"asset_path": "res://Microgame/Games/Game3Shoot/assets/"
	}
}

# ============== 信号 ==============
signal state_changed(new_state: int)
signal game_switched(game_type: int)
signal difficulty_changed(difficulty: int)
signal score_updated(score: int)
signal time_updated(time: float)
signal game_won(score: int)
signal game_lost(reason: String)

# ============== 单例模式 ==============
static var instance = null

func _ready():
	if instance == null:
		instance = self
		set_process(true)
	else:
		queue_free()

# ============== 状态转换 ==============
func change_state(new_state: int):
	print("状态转换: ", GameState.keys()[current_state], " → ", GameState.keys()[new_state])
	current_state = new_state
	emit_signal("state_changed", new_state)
	
	# 根据状态执行对应操作
	match new_state:
		GameState.MENU:
			_on_enter_menu()
		GameState.LOADING:
			_on_enter_loading()
		GameState.PLAYING:
			_on_enter_playing()
		GameState.PAUSED:
			_on_enter_paused()
		GameState.WON:
			_on_enter_won()
		GameState.LOST:
			_on_enter_lost()

# ============== 状态进入处理 ==============
func _on_enter_menu():
	current_score = 0
	time_elapsed = 0.0
	print("进入主菜单")

func _on_enter_loading():
	print("加载游戏中...")
	await get_tree().create_timer(0.5).timeout
	_load_game_scene()

func _on_enter_playing():
	print("开始游戏")
	time_elapsed = 0.0

func _on_enter_paused():
	print("游戏暂停")

func _on_enter_won():
	print("游戏胜利！分数: ", current_score)
	emit_signal("game_won", current_score)
	# 自动跳转胜利场景
	await get_tree().create_timer(0.5).timeout
	_load_victory_scene()

func _on_enter_lost():
	print("游戏失败")
	emit_signal("game_lost", "未知原因")
	# 自动跳转失败场景
	await get_tree().create_timer(0.5).timeout
	_load_gameover_scene()

# ============== 游戏切换 ==============
func switch_game(game_type: int):
	# 直接设置当前游戏（忽略是否已经相同）
	current_game = game_type
	current_score = 0
	time_elapsed = 0.0
	
	# 获取配置
	var config = game_configs.get(game_type)
	if config == null:
		print("错误: 未知游戏类型: ", game_type)
		return
	
	# 设置默认难度
	var default_diff = config["difficulty_settings"].keys()[0]
	current_difficulty = default_diff
	
	emit_signal("game_switched", game_type)
	print("切换到游戏: ", config["name"])
	
	# 先进入菜单状态
	change_state(GameState.MENU)

# ============== 设置难度 ==============
func set_difficulty(difficulty: int):
	var config = game_configs.get(current_game)
	if config == null:
		print("错误: 当前游戏配置不存在")
		return
	
	if difficulty not in config["difficulty_settings"]:
		print("错误: 游戏 ", current_game, " 不支持难度: ", difficulty)
		return
	
	current_difficulty = difficulty
	emit_signal("difficulty_changed", difficulty)
	print("难度已设置为: ", Difficulty.keys()[difficulty])

# ============== 获取当前配置 ==============
func get_current_config() -> Dictionary:
	var config = game_configs.get(current_game)
	if config == null:
		return {}
	return config["difficulty_settings"].get(current_difficulty, {})

func get_grid_size() -> Vector2:
	var config = get_current_config()
	return config.get("grid", Vector2(3, 3))

func get_time_limit() -> float:
	var config = get_current_config()
	return config.get("time", -1.0)

func get_target_score() -> int:
	var config = get_current_config()
	return config.get("target_score", 10)

func get_spawn_rate() -> float:
	var config = get_current_config()
	return config.get("spawn_rate", 2.0)

func get_image_folder() -> String:
	var config = game_configs.get(current_game)
	if config == null:
		return ""
	var diff_config = config["difficulty_settings"].get(current_difficulty, {})
	var folder = diff_config.get("folder", "")
	return config["asset_path"] + "images/" + folder + "/"

# ============== 场景加载 ==============
func _load_game_scene():
	var config = game_configs.get(current_game)
	if config == null:
		print("错误: 当前游戏配置不存在")
		change_state(GameState.MENU)
		return
	
	var scene_path = config["main_scene"]
	var result = get_tree().change_scene_to_file(scene_path)
	
	if result == OK:
		change_state(GameState.PLAYING)
	else:
		print("错误: 场景加载失败: ", scene_path)
		change_state(GameState.MENU)

func _load_victory_scene():
	var config = game_configs.get(current_game)
	if config == null:
		return
	if "victory_scene" in config:
		get_tree().change_scene_to_file(config["victory_scene"])
	change_state(GameState.MENU)

func _load_gameover_scene():
	var config = game_configs.get(current_game)
	if config == null:
		return
	if "gameover_scene" in config:
		get_tree().change_scene_to_file(config["gameover_scene"])
	change_state(GameState.MENU)

func load_menu_scene():
	var config = game_configs.get(current_game)
	if config == null:
		return
	get_tree().change_scene_to_file(config["menu_scene"])
	change_state(GameState.MENU)

# ============== 游戏控制 ==============
func start_game():
	change_state(GameState.LOADING)

func pause_game():
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

func resume_game():
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

func end_game(won: bool, reason: String = ""):
	if won:
		change_state(GameState.WON)
	else:
		change_state(GameState.LOST)
		emit_signal("game_lost", reason)

# ============== 分数管理 ==============
func add_score(points: int):
	current_score += points
	emit_signal("score_updated", current_score)
	
	# 检查射击游戏胜利条件
	if current_game == GameType.SHOOT:
		if current_score >= get_target_score():
			end_game(true)

func reset_score():
	current_score = 0
	emit_signal("score_updated", 0)

# ============== 时间管理 ==============
func _process(delta: float):
	if current_state == GameState.PLAYING:
		time_elapsed += delta
		emit_signal("time_updated", time_elapsed)
		
		# 检查拼图游戏时间限制
		if current_game == GameType.PUZZLE_ALL:
			var time_limit = get_time_limit()
			if time_limit > 0 and time_elapsed >= time_limit:
				end_game(false, "时间到")

# ============== 获取可用图片 ==============
# 硬编码图片列表 —— DirAccess 在导出包中无法访问 res:// 路径
const IMAGE_REGISTRY: Dictionary = {
	"picture3x3": ["1 (1).jpg", "1 (2).jpg", "1 (3).jpg", "1 (4).jpg"],
	"picture3x5": ["2 (1).jpg", "2 (2).jpg", "2 (3).jpg", "2 (4).jpg"],
	"picture4x6": ["3 (1).jpg", "3 (2).jpg", "3 (3).jpg", "3 (4).jpg"],
	"map":        ["map1234.png"],
}

func get_available_images() -> Array:
	var folder_path = get_image_folder()
	var config = game_configs.get(current_game)
	if config == null:
		return []
	var diff_config = config["difficulty_settings"].get(current_difficulty, {})
	var folder = diff_config.get("folder", "")
	
	var images: Array = []
	if IMAGE_REGISTRY.has(folder):
		for file_name in IMAGE_REGISTRY[folder]:
			images.append(folder_path + file_name)
	print("在 ", folder, " 中找到 ", images.size(), " 张图片")
	return images

# ============== 静态访问方法 ==============
static func get_instance():
	return instance

# ============== 辅助方法 ==============
func get_game_name() -> String:
	var config = game_configs.get(current_game)
	if config == null:
		return ""
	return config["name"]

func get_all_games() -> Array:
	var games = []
	for game_type in game_configs:
		games.append({
			"type": game_type,
			"name": game_configs[game_type]["name"]
		})
	return games
