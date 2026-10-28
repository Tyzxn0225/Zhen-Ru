extends Node

# 难度设置
const DIFFICULTY_EASY = 0
const DIFFICULTY_NORMAL = 1
const DIFFICULTY_HARD = 2

const TARGETS = [10, 20, 35]  # 简单、普通、困难的目标数

var current_difficulty: int = DIFFICULTY_EASY

func set_difficulty(difficulty: int):
	current_difficulty = difficulty
	print("难度已设置: ", difficulty)

func get_target_score() -> int:
	return TARGETS[current_difficulty]
