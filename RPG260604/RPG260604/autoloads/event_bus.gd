extends Node

signal on_player_created
#创建玩家时使用
signal on_player_health_updated(curr:float,max:float)
signal on_player_mana_updated(curr:float,max:float)
#更新玩家生命法力状态
signal on_player_new_level(curr:float,new_level:float)

signal on_player_stats_updated
signal on_inventory_used_item(item:ItemData)

signal on_player_stamina_updated(curr: float, max: float)

signal on_dialogue_started(data:DialogueData)
signal on_dialogue_finished
signal on_dialogue_input_blocked(is_blocked:bool)
#当对话框状态改变时发射，用于控制玩家输入拦截

signal coin_picked
#金币被拾取时发射

signal campus_points_changed
#校园活动分变化时发射

signal game_paused
#游戏暂停时发射

signal game_resumed
#游戏恢复时发射

signal on_main_buttons_inventory_opened
#MainButtons 背包打开时发射

signal map_travel_requested(world_position: Vector2)
# 大地图点击世界坐标，供后续传送 / POI 跳转接入


#region 剧情移动事件 (事件驱动方案 — 支持多NPC、玩家在对话/剧情中移动)
signal npc_story_move_request(npc_name: String, waypoints: Array, speed: float)
signal player_story_move_request(waypoints: Array, speed: float)

## 请求指定名称的 NPC 执行剧情多点移动 (供 dialogue do 调用)
func request_npc_story_move(npc_name: String, waypoints: Array, speed: float) -> void:
	npc_story_move_request.emit(npc_name, waypoints, speed)

## 请求玩家执行剧情多点移动 (供 dialogue do 调用)
func request_player_story_move(waypoints: Array, speed: float) -> void:
	player_story_move_request.emit(waypoints, speed)
#endregion

#region 场景动画事件 (供 dialogue do 调用, 由当前场景脚本响应)
signal scene_anim_play(node_name: String, anim: String)

## 请求在当前场景中播放指定节点的 AnimatedSprite2D 动画
func request_anim(node_name: String, anim: String) -> void:
	scene_anim_play.emit(node_name, anim)
#endregion

#region 任务系统信号
signal 任务已接取(任务ID: String)
signal 任务阶段变化(任务ID: String, 阶段索引: int)
signal 任务已完成(任务ID: String)
signal 任务关注变化(任务ID: String)
#endregion

signal player_indoor_state_changed(is_indoor: bool)

#region 小游戏信号
signal crate_reached_dest
