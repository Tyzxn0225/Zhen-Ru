##
# 玩家控制脚本 - 继承自 game_object.gd
# 负责处理玩家输入、移动逻辑和推箱子交互
##
extends "res://Microgame/box/game_object.gd"

##
# 每帧更新函数 - 处理玩家输入和移动逻辑
# @param delta: 帧间隔时间（秒）
##
func _process(delta: float) -> void:
	# 如果正在播放移动动画，跳过此次更新（防止移动过程中再次输入）
	if tween and tween.is_running():
		return
	
	# 获取输入方向：将输入映射为方向向量
	# 输入映射：move_left=-x, move_right=+x, move_up=-y, move_down=+y
	var dir := Vector2i(Input.get_vector("move_left", "move_right", "move_up", "move_down").round())
	
	# 如果没有输入（方向向量为零），直接返回
	if dir == Vector2i.ZERO:
		return
	
	# 禁止斜向移动：如果 x 方向有输入，强制 y 方向为 0
	# 这样玩家只能上下左右移动，不能斜着走
	if dir.x != 0:
		dir.y = 0
	
	# 计算目标格子坐标
	var dest := cell_position + dir
	
	# 检测目标位置是否是墙
	if is_wall(dest):
		bump(dest)  # 播放撞墙动画
		return
	
	# 检测目标位置是否有箱子
	var crate := get_crate(dest)
	if crate:
		# 计算箱子被推动后的目标位置
		var crate_dest := dest + dir
		
		# 如果箱子目标位置是墙，或者已经有另一个箱子
		if is_wall(crate_dest) or get_crate(crate_dest):
			bump(dest)  # 播放撞箱子动画（无法推动）
			return
		
		# 推动箱子到目标位置
		crate.move_to(crate_dest)
	
	# 移动玩家到目标位置
	move_to(dest)
