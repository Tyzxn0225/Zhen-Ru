extends Node


var player_name: String = "Player"                # 玩家自定义名字 ( 为空时显示 "Player" )
var coins: int = 100
var campus_points: int = 0                    # 校园活动分

var equipement: Dictionary[String, EquipData] = {
	"helmet" : null,
	"body" : null,
	"legs" : null,
	"weapon" : null,
	"ring" : null,
}

#region ── NPC 遇见次数 (对话多阶段分支用) ────────────────────────────────────
var 陈景明_meet_count:int =0
var 练习的中学生_meet_count:int =0
var 李婶_meet_count:int =0
var 苏婉清_meet_count:int =0
var 测试任务_meet_count:int =0
var 测试任务2_meet_count:int =0

var senior_guide_count: int = 0
#endregion

# ==================== 玩家数据持久化 ====================
# 保存玩家状态
var player_saved_data: Dictionary = {
	"health": 10.0,
	"max_health": 10.0,
	"mana": 10.0,
	"max_mana": 10.0,
	"stamina": 100.0,
	"experience": 0.0,
	"level": 1,
	"position": Vector2.ZERO,
	"direction": ""
}
var return_scene: String = ""
var return_position: Vector2 = Vector2.ZERO

#region ── 待续对话 ( 切场景后返回自动启动对话 ) ──────────────────────────────
var pending_dialogue_resource_path: String = ""    # 待启动的 .dialogue 文件路径
var pending_dialogue_title: String = ""            # 从哪个 title 标签开始 ( 如 "box_return" )
#endregion

var coins_picked_this_session: int = 0

## 玩家是否在室内区域（由 Portal 进出时更新；室内时隐藏小地图）
var player_is_indoor: bool = false


## 增加校园活动分 (供对话脚本 do 调用)
func add_campus_points(amount: int) -> void:
	campus_points += amount
	EventBus.campus_points_changed.emit()


## 减少校园活动分 (供商店购买等调用)
func remove_campus_points(amount: int) -> bool:
	if campus_points < amount:
		return false
	campus_points -= amount
	EventBus.campus_points_changed.emit()
	return true


## 增加金币 (供对话脚本 do 调用)
func add_coins(amount: int) -> void:
	coins += amount
	EventBus.coin_picked.emit()


## 减少金币 (供商店购买等调用)
func remove_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	EventBus.coin_picked.emit()
	return true

var _has_saved_player_data: bool = false

func save_player_data(player: Node) -> void:
	_has_saved_player_data = true
	if "global_position" in player:
		player_saved_data.position = player.global_position
	if player.has_node("HealthComponent") and "current_health" in player.get_node("HealthComponent"):
		player_saved_data.health = player.health_component.current_health
	if "max_health" in player:
		player_saved_data.max_health = player.max_health
	if "curr_mana" in player:
		player_saved_data.mana = player.curr_mana
	if "max_mana" in player:
		player_saved_data.max_mana = player.max_mana
	if player.has_node("StaminaComponent") and "curr_stamina" in player.get_node("StaminaComponent"):
		player_saved_data.stamina = player.stamina_component.curr_stamina
	if "curr_exp" in player:
		player_saved_data.experience = player.curr_exp
	if "curr_level" in player:
		player_saved_data.level = player.curr_level
	if "last_direction" in player:
		player_saved_data.direction = player.last_direction
	return_scene = get_tree().current_scene.scene_file_path

func restore_player_data(player: Node) -> void:
	# 从未存档过 → 保持 setup() 初始化的值 (检查器中设置的各项属性)
	if not _has_saved_player_data:
		return
	# 只有当保存的位置不是原点时才恢复位置（避免覆盖场景设计的初始位置）
	if "global_position" in player and player_saved_data.position != Vector2.ZERO:
		player.global_position = player_saved_data.position
	if player.has_node("HealthComponent") and "current_health" in player.get_node("HealthComponent"):
		player.health_component.current_health = player_saved_data.health
	if "max_health" in player:
		player.max_health = player_saved_data.max_health
	if "curr_mana" in player:
		player.curr_mana = player_saved_data.mana
	if "max_mana" in player:
		player.max_mana = player_saved_data.max_mana
	if player.has_node("StaminaComponent") and "curr_stamina" in player.get_node("StaminaComponent"):
		player.stamina_component.curr_stamina = min(player_saved_data.stamina, player.stamina_component.max_stamina)
	if "curr_exp" in player:
		player.curr_exp = player_saved_data.experience
	if "curr_level" in player:
		player.curr_level = player_saved_data.level
	if "last_direction" in player and not player_saved_data.direction.is_empty():
		player.last_direction = player_saved_data.direction
