extends Node

# 游戏管理器 - 拼图游戏1
# 负责管理游戏难度、网格大小、时间限制等配置

enum Difficulty { EASY = 0, NORMAL = 1, HARD = 2 }
var current_difficulty: int = Difficulty.EASY

# 难度配置
const DIFFICULTY_SETTINGS = {
	Difficulty.EASY: { "grid": Vector2(3, 3), "time": 120.0, "folder": "picture3x3" },
	Difficulty.NORMAL: { "grid": Vector2(5, 3), "time": 240.0, "folder": "picture3x5" },
	Difficulty.HARD: { "grid": Vector2(6, 4), "time": 300.0, "folder": "picture4x6" }
}

func get_grid_size() -> Vector2:
	return DIFFICULTY_SETTINGS[current_difficulty]["grid"]

func get_time_limit() -> float:
	return DIFFICULTY_SETTINGS[current_difficulty]["time"]

func set_difficulty(diff: int):
	current_difficulty = diff
	print("拼图游戏1 - 难度已设置: ", Difficulty.keys()[current_difficulty])

func get_difficulty() -> int:
	return current_difficulty

func get_available_images() -> Array:
	var folder_name = DIFFICULTY_SETTINGS[current_difficulty]["folder"]
	var base_path = "res://Microgame/Games/Game1PuzzleAll/assets/images/" + folder_name + "/"
	
	# 硬编码图片列表 —— DirAccess 在导出包中无法访问 res:// 路径
	const IMAGES: Dictionary = {
		"picture3x3": ["1 (1).jpg", "1 (2).jpg", "1 (3).jpg", "1 (4).jpg"],
		"picture3x5": ["2 (1).jpg", "2 (2).jpg", "2 (3).jpg", "2 (4).jpg"],
		"picture4x6": ["3 (1).jpg", "3 (2).jpg", "3 (3).jpg", "3 (4).jpg"],
	}
	
	var images: Array = []
	if IMAGES.has(folder_name):
		for file_name in IMAGES[folder_name]:
			images.append(base_path + file_name)
	print("在 ", folder_name, " 中找到 ", images.size(), " 张图片")
	return images

func get_current_folder() -> String:
	return DIFFICULTY_SETTINGS[current_difficulty]["folder"]
