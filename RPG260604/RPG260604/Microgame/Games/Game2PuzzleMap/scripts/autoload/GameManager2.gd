extends Node

enum Difficulty { MAP = 0 }

var current_difficulty: int = Difficulty.MAP

func get_grid_size() -> Vector2:
	return Vector2(3, 3)  # map关卡使用3×3切割

func get_time_limit() -> float:
	return -1  # map关卡时长无限制

func set_difficulty(diff: int):
	current_difficulty = Difficulty.MAP
	print("难度已设置为: MAP")

func get_available_images() -> Array:
	const BASE_PATH := "res://Microgame/Games/Game2PuzzleMap/assets/images/map/"
	
	# 硬编码图片列表 —— DirAccess 在导出包中无法访问 res:// 路径
	const FILES := ["map1234.png"]
	
	var images: Array = []
	for file_name in FILES:
		images.append(BASE_PATH + file_name)
	print("在 map 文件夹中找到 ", images.size(), " 张图片")
	return images

func get_current_folder() -> String:
	return "map"
