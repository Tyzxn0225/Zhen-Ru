##
# 游戏对象基类 - 提供推箱子游戏中所有对象的通用功能
# 包括：平滑移动、碰撞反弹、地图检测等
##
extends Node2D

# Tween 动画控制器 - 用于平滑移动和碰撞效果
var tween: Tween

# 地图层引用 - 通过 get_parent() 获取场景中的 TileMapLayer
@onready var map: TileMapLayer = get_parent()
# 当前格子坐标 - 初始化为当前世界位置对应的格子
@onready var cell_position: Vector2i = map.local_to_map(position)
# 初始格子坐标 - 用于重置游戏
var initial_cell_position: Vector2i

##
# 重置对象到初始位置
# 子类可重写此方法以添加更多重置逻辑
##
func reset_position() -> void:
	# 取消当前动画
	if tween:
		tween.kill()
		tween = null
	# 重置到初始格子位置
	move_to(initial_cell_position)

##
# 平滑移动到目标格子
# @param cell: 目标格子坐标 (Vector2i)
##
func move_to(cell: Vector2i):
	# 更新格子位置记录
	cell_position = cell
	
	# 如果有正在运行的动画，先取消
	if tween:
		tween.kill()
	
	# 创建新的 Tween 动画
	tween = create_tween()
	# 设置缓动模式：EASE_IN_OUT（先慢后快再慢）+ SINE（正弦曲线）
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 在 0.2 秒内将对象位置从当前值插值到目标格子位置
	tween.tween_property(self, "position", map.map_to_local(cell), 0.2)

##
# 碰撞反弹效果 - 当玩家撞到墙或箱子时触发
# @param cell: 碰撞目标的格子坐标
##
func bump(cell: Vector2i):
	# 如果有正在运行的动画，先取消
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 第一步：0.1秒内向碰撞点移动一半距离（模拟碰撞冲击）
	tween.tween_property(self, "position", (map.map_to_local(cell) + position) / 2, 0.1)
	# 第二步：0.1秒内弹回原位置（模拟反弹）
	tween.tween_property(self, "position", position, 0.1)

##
# 判断指定格子是否是墙
# 通过读取 Tile 的自定义数据 "is_wall" 来判断
# @param cell: 要检查的格子坐标
# @return bool: true=是墙, false=不是墙
##
func is_wall(cell: Vector2i) -> bool:
	# 获取格子的 Tile 数据
	var data := map.get_cell_tile_data(cell)
	# 如果格子为空（没有 Tile），返回 false
	if not data:
		return false
	# 返回 Tile 的自定义数据 "is_wall" 的值
	return data.get_custom_data("is_wall")

##
# 判断指定格子是否是目标点（箱子需要推到的位置）
# 通过读取 Tile 的自定义数据 "is_dest" 来判断
# @param cell: 要检查的格子坐标
# @return bool: true=是目标点, false=不是目标点
##
func is_dest(cell: Vector2i) -> bool:
	var data := map.get_cell_tile_data(cell)
	if not data:
		return false
	return data.get_custom_data("is_dest")

##
# 获取指定格子上的箱子
# 通过遍历 "crates" 组中的所有箱子来查找
# @param cell: 要检查的格子坐标
# @return Crate: 找到的箱子对象，如果没有则返回 null
##
func get_crate(cell: Vector2i) -> Crate:
	# 遍历场景中所有标记为 "crates" 组的节点
	for crate: Crate in get_tree().get_nodes_in_group("crates"):
		# 如果箱子的当前位置等于目标格子
		if crate.cell_position == cell:
			return crate
	# 没有找到箱子，返回 null
	return null
		
		
		
		
		
		
		
