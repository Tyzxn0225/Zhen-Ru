##
# 箱子类 - 继承自 game_object.gd
# 负责处理箱子的移动和到达目标点的状态管理
##
class_name Crate

extends "res://Microgame/box/game_object.gd"

##
# 是否到达目标点的状态
# 使用属性 setter 实现状态变化时的自动通知
# @value bool: true=已到达目标点, false=未到达
##
var is_reached := false:
	set(v):
		# 如果新值和旧值相同，直接返回（防止重复触发）
		if is_reached == v:
			return
		
		# 更新状态
		is_reached = v
		
		# 根据状态播放不同的动画
		animation_player.play("reached" if is_reached else "default")
		
		# 如果到达目标点，发出事件通知游戏管理器
		if is_reached:
			EventBus.crate_reached_dest.emit()

# 动画播放器引用 - 用于播放到达目标点的动画
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 初始是否到达目标点的状态
var initial_is_reached := false

##
# 重置箱子到初始位置和状态
##
func reset_position() -> void:
	# 调用父类的重置方法
	super.reset_position()
	# 重置到达状态
	is_reached = initial_is_reached
	# 重置动画
	animation_player.play("default" if not initial_is_reached else "reached")

##
# 移动箱子到目标格子
# 重写父类方法，添加到达目标检测
# @param cell: 目标格子坐标
##
func move_to(cell: Vector2i):
	# 调用父类的移动方法执行实际移动
	super.move_to(cell)
	
	# 移动完成后检查是否到达目标点
	is_reached = is_dest(cell)
